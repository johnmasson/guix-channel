(use-modules
 (shepherd comm)
 (jlm wsl services)
 (ice-9 match))

(define (try-open-connection)
  (catch 'system-error
    open-connection
    (lambda (key . args)
      (format (current-error-port)
	      "failed to open shepherd connection ~a : ~a\n"
	      key args)
      #f)))

(define (query-services)
  (let ((con (try-open-connection))
	(cmd (shepherd-command 'status 'root)))
    (and con
	 (begin
	   (write-command cmd con)
	   (match (read con)
	     (('reply ('version 0 _ ...)
		      ('result result)
		      ('error #f)
		      ('messages messages))
	      (car result)))))))

(define (power-off)
  (let ((con (open-connection))
	(cmd (shepherd-command 'power-off 'root)))
    (if con
	(write-command cmd con))))

(define (system-status)
  (if (not (file-exists? "/var/run/shepherd/socket"))
      'wait
      (let ((services (query-services)))
	(if services
	    (begin
	      (format (current-error-port) "~a\n" (get-services-status services))
	      (services-status services))
	    'wait))))


(define (systemctl-main args)
  ;;  (pretty-print args)
  (if (null? (cdr args))
      (begin
	(format #t "missing subcommand\n")
	(exit #f))
      
      (match (cadr args)
	("is-system-running"
	 (let ((status-string 
		(match (system-status)
		  ('wait "starting")
		  ('good
		   "running")
		  ('bad
		   "degraded"))))
	   (sleep 1)
	   (format #t "~a\n" status-string)
	   (exit #t)))
	
	("is-active"
	 (let* ((user-service-name (caddr args))
		(user-service-match
		 (string-match "user@([0-9]+).service" user-service-name))
		(user-id (match:substring user-service-match 1))
		(user-runtime-path (format #f "/run/user/~a" user-id)))
	   (format (current-error-port) "Checking for ~a\n" user-runtime-path)
	   (if (file-exists? user-runtime-path)
	       (exit #t)
	       (exit #f))))

	("poweroff"
	 (power-off)
	 (exit #t))
	
	(_
	 (format #t "command not supported\n")
	 (exit #f)))))

(systemctl-main (command-line))
