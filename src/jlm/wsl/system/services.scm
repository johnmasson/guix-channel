(define-module (jlm wsl system services)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu home services)
  #:use-module (guix build syscalls)
  #:use-module (guix gexp))

;;; Note about SIGCHLD
;;;
;;; The /sbin/init process that boots the system, and the /bin/login
;;; process that creates a user session and runs the on-first-login
;;; script, which in turn starts the user's shepherd instance, are
;;; both created from WSL in such a way that SIGCHLD is set to
;;; SIG_IGN. This breaks shepherd, since it can no longer wait for its
;;; child processes to exit. Sometimes this shows up as services
;;; failing to fully start (e.g. udev), sometimes as services getting
;;; stuck in stopping / restarting states.
;;;
;;; The below services bundle the fix for this with other environment
;;; fixes / setup, but istm that shepherd should ensure its signal
;;; handers are sane in its own startup

(define (wsl-boot-service _)
  (with-imported-modules
   '((guix build syscalls))
   #~(begin
       (use-modules (guix build syscalls))
       ;; WSL calls /sbin/init with this set to SIG_IGN, which breaks shepherd, so reset it
       (sigaction SIGCHLD SIG_DFL)
       ;; WSL mounts /run with nosuid set, which breaks /run/privileged
       (mount #f "/run" #f MS_REMOUNT #:update-mtab? #f))))

(define-public wsl-boot-service-type
  (service-type
   (name 'wsl-boot-service-type)
   (extensions
    (list (service-extension boot-service-type wsl-boot-service)))
   (default-value '())
   (description "Adds boot-time setup code needed to adapt Guix to the WSL environment or vice-versa")))

(define (wsl-user-session-service _)
  #~(begin
      ;; same as above, this process is created by WSL with SIGCHLD ignored
      (sigaction SIGCHLD SIG_DFL)
      ;; link the wayland socket into the user's runtime dir -
      ;; required for wayland apps to work properly
      (let ((xdg-runtime-dir
	     (or (getenv "XDG_RUNTIME_DIR")
		 (format #f "/run/user/~a" (getuid)))))
	(symlink "/mnt/wslg/runtime-dir/wayland-0"
		 (string-append xdg-runtime-dir "/wayland-0")))))

(define-public wsl-user-session-service-type
  (service-type
   (name 'wsl-user-session-service)
   (extensions
    (list (service-extension home-run-on-first-login-service-type wsl-user-session-service)))
   (default-value '())
   (description "Adds per-user setup code for WSL sessions")))
	 
