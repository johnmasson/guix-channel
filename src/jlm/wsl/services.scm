(define-module (jlm wsl services)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 regex)
  #:export (services-status get-services-status))

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

(define (get-services-status services)
  (map (lambda (svc)
	 (list (service-prop 'provides svc)
	       (service-prop 'status svc)
	       (service-prop 'one-shot? svc)
	       (service-status svc)))
       services))

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

