;;; wiki-pack.el ---                                 -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Antoine R. Dumont

;; Author: Antoine R. Dumont <tony@corellia>
;; Keywords: convenience, setup, mediawiki

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(use-package mediawiki)
(use-package ox-mediawiki)

(defcustom wiki-pack-credentials-file "~/.authinfo.gpg"
  "Default configuration file.")

(defun wiki-pack-log (&rest args)
  "Log ARGS with specific pack prefix."
  (apply #'message (format "Wiki Pack - %s" (car args)) (cdr args)))

(defun wiki-pack-setup-possible-p (creds-file)
  "Check if CREDS-FILE exists and contain at least one account.
If all is ok, return the creds-file's content, nil otherwise."
  (when (file-exists-p creds-file)
    (let* ((creds-file-content (creds/read-lines creds-file))
           (wiki-entry (creds/get creds-file-content "wiki"))
           (sitename   (creds/get-entry wiki-entry "sitename"))
           (url        (creds/get-entry wiki-entry "url"))
           (username   (creds/get-entry wiki-entry "login"))
           (password   (creds/get-entry wiki-entry "password"))
           (main-page  (creds/get-entry wiki-entry "main-page")))
      `(:sitename ,sitename
                  :url ,url
                  :username ,username
                  :password ,password
                  :main-page ,main-page))))

(defun wiki-pack-setup (wiki-data)
  "Wiki pack setup with the WIKI-DATA output from `wiki-pack-setup-possible-p'."
  (add-to-list 'mediawiki-site-alist `(,(plist-get wiki-data :sitename)
                                       ,(plist-get wiki-data :url)
                                       ,(plist-get wiki-data :username)
                                       ,(plist-get wiki-data :password)
                                       ,(plist-get wiki-data :main-page))))

(defun wiki-pack-load-pack ()
  "Mail pack loading routine.
This will check if the pre-requisite are met.
If ok, then checks if an account file exists the minimum required (1 account).
If ok then do the actual loading.
Otherwise, will log an error message with what's wrong to help the user fix it."
  (interactive)
  ;; at last the checks and load pack routine
  (-if-let (wiki-data (wiki-pack-setup-possible-p wiki-pack-credentials-file))
      (progn
        (wiki-pack-log "%s found! Running Setup..." wiki-pack-credentials-file)
        (wiki-pack-setup wiki-data)
        (wiki-pack-log "Setup done!"))
    (wiki-pack-log
     "You need to setup your credentials file %s for this to work. (The credentials file can be secured with gpg or not).
A wiki configuration file would look like:
machine wiki sitename <wiki-name> url <url> login <login> password <password> main-page <main-page>

Optional: Then `M-x encrypt-epa-file` to generate the required ~/.authinfo.gpg and remove ~/.authinfo.
Whatever you choose, reference the file you use in your emacs configuration:
(custom-set-variables '(wiki-pack-credentials-file (expand-file-name \"~/.authinfo\")))"
     wiki-pack-credentials-file)))

;; debug purposes
;; (setq mediawiki-site-alist '(("Wikipedia" "http://en.wikipedia.org/w/" "username" "password" "Main Page")))

(defvar wiki-pack-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c w l") 'wiki-pack-load-pack)
    (define-key map (kbd "C-c w s") 'mediawiki-site)
    map)
  "Keymap for wiki-pack mode.")

(define-minor-mode wiki-pack-mode
  "Minor mode to consolidate wiki-pack extensions.

\\{wiki-pack-mode-map}"
  :lighter " ς"
  :keymap wiki-pack-mode-map)

(define-globalized-minor-mode global-wiki-pack-mode wiki-pack-mode wiki-pack-on)

(defun wiki-pack-on ()
  "Turn on `wiki-pack-mode'."
  (wiki-pack-mode +1))

(global-wiki-pack-mode)

(provide 'wiki-pack)
;;; wiki-pack.el ends here
