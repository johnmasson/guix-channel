(define-module (jlm packages)
  #:use-module (guix)
  #:use-module (guix git-download)
  #:use-module (guix build-system guile)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages package-management))

(define vcs-file?
  (or (git-predicate (dirname (dirname (current-source-directory))))
      (const #t)))

(define-public wsl
  (package
   (name "wsl")
   (version "0.0.1")
   (synopsis "Support functions for WSL installs")
   (description "Support functions for WSL installs")
   (home-page #f)
   (license license:lgpl3+)

   (source (local-file "../" "wsl-src"
		       #:select? vcs-file?
		       #:recursive? #t))

    (native-search-paths
     (list (search-path-specification
            (variable "GUILE_LOAD_PATH")
            (files '("share/guile/site/3.0")))
	   (search-path-specification
            (variable "GUILE_LOAD_COMPILED_PATH")
            (files '("lib/guile/3.0/site-ccache")))))
    
   (build-system guile-build-system)
   (native-inputs (list guile-3.0-latest))
   (inputs (list guix))))

	   
