#! /run/current-system/bin/guile \
-L /run/current-system/share/guile/site/3.0 -s
!#
(use-modules (jlm wsl setup))

(define (output-port args)
  (if (null? (cdr args))
      (current-output-port)
      (open-file (cadr args) "w")))

(interactive-generate-system (output-port (command-line)))
