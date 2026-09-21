(let ((system (canonicalize-path "/var/guix/profiles/system")))
  (setenv "GUIX_NEW_SYSTEM" system)
  (sigaction SIGCHLD SIG_DFL)
  (execl
   "/var/guix/profiles/system/profile/bin/guile"
   "guile"
   "--no-auto-compile"
   (string-append system "/boot")))
