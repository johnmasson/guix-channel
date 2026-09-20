(define-module (wsl conf)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:export (wsl-conf
	    wsl-conf-fields
	    wsl-boot
	    wsl-boot-fields
	    wsl-user
	    wsl-user-fields
	    wsl-automount
	    wsl-automount-fields))

(define (section-serializer section-fields)
  (lambda (name values)
    #~(string-append #$(format #f "[~a]\n" name)
		     #$(serialize-configuration values section-fields))))
  
(define (serialize-quoted-string name value)
  #~(format #f "~a=~s\n" #$(format #f "~a" name) #$value))

(define (serialize-unquoted-string name value)
  #~(format #f "~a=~a\n" #$(format #f "~a" name) #$value))

(define (serialize-boolean name value)
  (format #f "~a=~a\n" name (if value "true" "false")))

(define (string-or-gexp? value)
  (or (string? value) (gexp? value)))

;; Define some of /etc/wsl.conf
(define-configuration wsl-boot
  (command string-or-gexp "Command to run on starting up the distro"
	   (serializer serialize-quoted-string))
  (systemd (boolean #f) "Whether to boot into systemd"
	   (serializer serialize-boolean)))

(define-configuration wsl-user
  (default string "Username of default user"
    (serializer serialize-unquoted-string)))

(define-configuration wsl-automount
  (mountFsTab (boolean #f) "Mount filesystems from /etc/fstab"
	      (serializer serialize-boolean)))

(define-configuration wsl-conf
  (boot wsl-boot "Boot settings"
	(serializer (section-serializer wsl-boot-fields)))
  (user wsl-user "User settings"
	(serializer (section-serializer wsl-user-fields)))
  (automount (wsl-automount (wsl-automount)) "Automount settings"
	     (serializer (section-serializer wsl-automount-fields))))
  
