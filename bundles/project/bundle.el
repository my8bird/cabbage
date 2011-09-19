(defcustom e-max-project-location
  (expand-file-name "~/Projects/")
  "the location, where your development projects are stored locally"
  :type 'string
  :group 'e-max)

(defun e-max-project-ido-find-project ()
  (interactive)
  (let ((project-name (ido-completing-read "Project: "
                                           (directory-files e-max-project-location nil "^[^.]"))))
    (e-max-persp project-name)
    (find-file (e-max-ido-open-find-directory-files
                (concat e-max-project-location project-name)))))


(global-set-key (kbd "C-x p") 'e-max-project-ido-find-project)


(e-max-vendor 'textmate)
(global-set-key (kbd "M-t") 'textmate-goto-file)
(global-set-key (kbd "M-w") 'textmate-goto-symbol)
