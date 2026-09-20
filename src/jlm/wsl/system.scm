(define-module (jlm wsl system)
  #:use-module (gnu)
  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (gnu system images wsl2)
  #:use-module (gnu system file-systems)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages bash)
  #:use-module (guix modules)
  #:use-module (guix build syscalls)
  #:use-module (guix gexp)
  #:use-module (ice-9 match))

(define set-mount-may-fail
  (record-modifier (@@ (gnu system file-systems) <file-system>)
		   'mount-may-fail?))

(define set-mount
  (record-modifier (@@ (gnu system file-systems) <file-system>)
		   'mount?))

(define (relevant-module? name)
  (match name
    (('guix _ ...) #t)
    (('gnu _ ...) #t)
    (('shepherd _ ...) #t)
    (('jlm _ ...) #t)
    (_ #f)))

(define (read-all-forms port)
  (let loop ((forms '()))
    (let ((form (read port)))
      (if (eof-object? form)
          (reverse forms)
          (loop (cons form forms))))))

(define %fake-systemctl-src
  (call-with-input-file
      (string-append (dirname current-filename) "../../../scripts/fake-systemctl.scm")
    read-all-forms))

;; must call this in reconfigure script
;; there has to be a better way to handle this
(define-public (fix-control-groups-fs)
  (set-mount-may-fail (car %control-groups) #t))

;; startup guix system from WSL boot command
(define (wsl-system-boot-cmd)
  (let* ((system-generation (readlink "/var/guix/profiles/system"))
	 (system (readlink (string-append
			    (if (absolute-file-name? system-generation)
				""
				"/var/guix/profiles/")
			    system-generation))))
    (setenv "GUIX_NEW_SYSTEM" system)
    (mount #f "/run" #f MS_REMOUNT #:update-mtab? #f)
    (execl "/var/guix/profiles/system/profile/bin/guile" "guile" "--no-auto-compile"
	   (string-append system "/boot"))))

(define-public wsl-operating-system
  (operating-system
   (inherit wsl-os)

   ;; set these in the actual os definition
   ;; (host-name "guix")
   ;; (keyboard-layout (keyboard-layout "us" "altgr-intl"))
   ;; (timezone "Europe/London")

   ;(packages (cons wsl-utils %base-packages))
   
   (essential-services
    (modify-services
     (operating-system-default-essential-services this-operating-system)
     ;; cleanup-service-type deletes everything in /run, breaking WSL interop
     ;; should replace this with something more targeted
     (delete cleanup-service-type)

     ;; also delete these on general principles since we don't have any hardware
     (delete firmware-service-type)
     (delete (service-kind %linux-bare-metal-service))))
   
   (users %base-user-accounts) ; do nor override root shell

   ;; this is not the root file system, but guix system reconfigure does
   ;; not work unless this is defined. Ideally this shouldn't be needed
   (file-systems
    (list (file-system
           (device "/dev/sdb")
           (mount-point "/")
           (type "ext4")
           (mount? #t)
	   (mount-may-fail? #t))))

   (services
    (list
     (service guix-service-type)
     (service syslog-service-type)
     ;; elogind and login are required for user shepherd
     ;; instances to run properly
     (service elogind-service-type)
     (service login-service-type)
     
     (service
      special-files-service-type
      `(;("/bin/sh" ,(file-append bash "/bin/bash"))
        ("/bin/mount" ,(file-append util-linux "/bin/mount"))
        ("/usr/bin/env" ,(file-append coreutils "/bin/env"))
	("/sbin/ldconfig" ,(file-append glibc "/sbin/ldconfig"))
	("/bin/login" ,(file-append shadow "/bin/login"))
	("/usr/bin/systemctl"
	 ,(program-file
	   "fake-systemctl"
	   (with-extensions
	    (list shepherd)
	    #~(#$@%fake-systemctl-src))))))))))
	  
