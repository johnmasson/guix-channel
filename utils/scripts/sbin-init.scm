#! /bin/guile
!#
(let ((system (canonicalize-path "/var/guix/profiles/system")))
  ;;; required to activate the correct system generation in boot script
  (setenv "GUIX_NEW_SYSTEM" system)
  (primitive-load (string-append system "/boot")))
