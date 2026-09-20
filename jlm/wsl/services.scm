(define-module (wsl services)
  #:use-module (shepherd comm)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 regex)
  #:export (systemctl-main))

(define (service-prop name svc)
  (cadr (assoc name (cdr svc))))

(define (service-status svc)
  (cond
   ((or (and (service-prop 'one-shot? svc)
	     (eq? 'stopped (service-prop 'status svc)))
	(eq? 'running (service-prop 'status svc)))
    'good)
   ((and (not (service-prop 'one-shot? svc))
	 (eq? 'stopped (service-prop 'status svc)))
    'bad)
   ((eq? 'starting (service-prop 'status svc))
    'wait)
   (#t 'unknown)))

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


(define (get-services-status services)
  (map (lambda (svc)
	 (list (service-prop 'provides svc)
	       (service-prop 'status svc)
	       (service-prop 'one-shot? svc)
	       (service-status svc)))
       services))

(define (system-status)
  (define (services-status services)
    (if (null? services)
	'good
	(match (service-status (car services))
	  ('good (services-status (cdr services)))
	  ('wait 'wait)
	  ((or 'bad 'unknown)
	   (let ((rest-status (services-status (cdr services))))
	     (if (eq? 'wait rest-status)
		 'wait
		 'bad))))))

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
