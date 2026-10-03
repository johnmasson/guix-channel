(define-module (jlm wsl system)
  #:use-module (gnu)
  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (gnu system images wsl2)
  #:use-module (gnu system file-systems)
  #:use-module (gnu packages base)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages bash)
  #:use-module (guix modules)
  #:use-module (guix build syscalls)
  #:use-module (jlm packages)
  #:use-module (jlm wsl system services)
  #:use-module (guix gexp))

(define-public wsl-operating-system
  (operating-system
   ;; inherit the definition from (gnu system images wsl2) to get a
   ;; dummy kernel, bootloader etc.
   (inherit wsl-os)

   ;; packages required for special-files below
   (packages (cons* tzdata wsl-utils %base-packages))
   
   (essential-services
    (modify-services
     (operating-system-default-essential-services this-operating-system)
     ;; cleanup-service-type deletes everything in /run, breaking WSL interop
     ;; should replace this with something more targeted
     (delete cleanup-service-type)

     ;; also delete these on general principles since we don't have
     ;; any hardware to configure
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
     (service wsl-elogind-service-type)
     (service login-service-type)

     ;; qv
     (service wsl-boot-service-type)
      
     (service
      special-files-service-type
      ;; we would like to set /bin/sh to the system bash, but doing so
      ;; causes shells run directly by WSL (e.g. to monitor for
      ;; 'systemd' startup and user sessions) to fail due to not
      ;; having paths set correctly. See scripts/bin-sh.scm
      `(;("/bin/sh" ,(file-append bash "/bin/bash"))
	;; for portable shell scripts
	("/usr/bin/env" ,(file-append coreutils "/bin/env"))
	;; all these are called by WSL either by hardcoded path or via
	;; 'sh -c' in an empty environment
        ("/bin/mount" ,(file-append util-linux "/bin/mount"))
	("/sbin/ldconfig" ,(file-append glibc "/sbin/ldconfig"))
	("/bin/login" ,(file-append shadow "/bin/login"))
	("/bin/grep" ,(file-append grep "/bin/grep"))
	;; WSL attempts to set the timezone from windows' timezone, needs this data
	("/usr/share/zoneinfo" ,(file-append tzdata "/share/zoneinfo"))
	;; these are shims that support booting or calling into guix from WSL
	("/usr/bin/systemctl"
	 ,(file-append wsl-utils "/share/wsl-utils/scripts/fake-systemctl.scm"))
	("/sbin/init"
	 ,(file-append wsl-utils "/share/wsl-utils/scripts/sbin-init.scm"))
	("/bin/sh"
	 ,(file-append wsl-utils "/share/wsl-utils/scripts/bin-sh.scm"))))))))
	  
