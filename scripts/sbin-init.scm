(let* ((system-generation (readlink "/var/guix/profiles/system"))
       (system (readlink (string-append
			  (if (absolute-file-name? system-generation)
			      ""
			      "/var/guix/profiles/")
			  system-generation))))
  (setenv "GUIX_NEW_SYSTEM" system)
  (execl "/var/guix/profiles/system/profile/bin/guile" "guile" "--no-auto-compile"
	 (string-append system "/boot")))
