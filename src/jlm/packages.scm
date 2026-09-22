(define-module (jlm packages)
  #:use-module (guix)
  #:use-module (guix utils)
  #:use-module (guix git-download)
  #:use-module (guix build gnu-build-system)
  #:use-module (guix build-system guile)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages package-management))

(define (get-project-root)
  (let ((current-dir (or (current-source-directory) (dirname (current-filename)))))
    (dirname (dirname current-dir))))

(define vcs-file?
  (or (git-predicate (get-project-root))
      (const #t)))

(define-public wsl-utils
  (package
   (name "wsl-utils")
   (version "0.0.1")
   (synopsis "Supporting utilities for WSL installs")
   (description "Supporting utilitise for WSL installs")

   (home-page "https://github.com/johnmasson/guix-channel")
   (license license:lgpl3+)
   
   (source (local-file "../../utils" "wsl-utils-src"
		       #:select? vcs-file?
		       #:recursive? #t))

   (build-system guile-build-system)
   (arguments
    (list
     #:source-directory "modules"
     #:phases #~(modify-phases %standard-phases
     (add-before 'build 'install-scripts
		 (lambda _
		   (let ((bin (string-append #$output "/share/wsl-utils/scripts")))
		     (for-each
		      (lambda (script) (install-file script bin))
		      (find-files "scripts"))))))
     ))
   (native-inputs (list guile-3.0-latest))
   (inputs (list guix shepherd guile-readline))))

(define-public wsl
  (package
   (name "wsl")
   (version "0.0.1")
   (synopsis "Support functions for WSL installs")
   (description "Support functions for WSL installs")
   (home-page "https://github.com/johnmasson/guix-channel")
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
   (inputs (list guix wsl-utils))))

