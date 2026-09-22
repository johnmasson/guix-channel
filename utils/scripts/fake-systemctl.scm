#! /bin/guile \
-L /var/guix/profiles/system/profile/share/guile/site/3.0 -s
!#
(use-modules
 (jlm wsl services))

(systemctl-main (command-line))
