(define-module (jlm wsl setup)
  #:use-module (ice-9 readline)
  #:use-module (ice-9 pretty-print)
  #:use-module (guix gexp))

(define (current-system-template hostname timezone username realname)
  `((define-module (current-system)
      #:use-module (gnu system)
      #:use-module (jlm wsl system)
      #:use-module (jlm wsl conf)
      #:use-module (guix gexp)
      #:use-module (gnu packages bash))

    (fix-control-groups-fs)

    (define-public current-operating-system
      (operating-system
       (inherit wsl-operating-system)

       (host-name ,hostname)
       (timezone ,timezone)

       (users
	(cons
	 (user-account
	  (name ,username)
	  (shell #~(string-append #$bash "/bin/bash"))
	  (comment ,realname)
	  (group "users")
	  (supplementary-groups
	   '("wheel")))
	 (operating-system-users wsl-operating-system)))

       (services
	(cons
	 (service
	  wsl-conf-service-type
	  (wsl-conf
	   (user (wsl-user (default ,username)))))
	 (operating-system-user-services wsl-operating-system)))))
    
    current-operating-system))

(define (read-with-default prompt default)
  (let ((line (readline (string-append prompt " (default " default ") "))))
    (if (and line (not (string-null? line)))
	line
	default)))

(define-public (interactive-generate-system output)
  (format #t "Welcome to Guix. Please complete this short questionnaire:\n")
  (let* ((hostname (readline "What should this instance's hostname be? "))
	 (timezone (readline "What timezone is this instance in? ")))
    (format #t "We will create a non-root user account, which will be the WSL default user\n")
    (let* ((username (readline "What should this user's username be? "))
	   (realname (readline "What should this user's real name be? ")))
      (with-output-to-port output
	(lambda ()
	  (for-each
	   pretty-print
	   (current-system-template hostname timezone username realname)))))))

(define-public (generate-system-file file-name)
  (interactive-generate-system (open-file file-name)))
