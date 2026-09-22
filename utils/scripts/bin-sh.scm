#! /bin/guile
!#
;;; WSL runs certain commands in the linux instance by calling `sh -c`
;;; with a command line. Due to this shell begin run outside of any
;;; other process, non-login and non-interactive, it runs in an empty
;;; environment with no PATH set and does not read any startup files.
;;; In Guix, bash's compiled-in default path is /no-such-path, which
;;; obviously doesn't contain any useful programs. So here we hijack
;;; /bin/sh to set a more useful default path if none exists in the
;;; environment

(define (unset? v)
  (or (not v) (string-null? v)))

(if (unset? (getenv "PATH"))
    (setenv "PATH" "/usr/bin:/bin"))

(apply execl (cons* "/var/guix/profiles/system/profile/bin/bash" "sh" (cdr (command-line))))
    
