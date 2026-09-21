(let ((system (canonicalize-path "/var/guix/profiles/system")))
  (setenv "GUIX_NEW_SYSTEM" system)
  (execl
   "/var/guix/profiles/system/profile/bin/guile"
   "guile"
   "--no-auto-compile"
   (string-append system "/boot")))
