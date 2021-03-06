(defvar cabbage-plone-buildout--instance-argument-history nil)
(defvar cabbage-plone-buildout--run-persp-prefix "*fg*")
(defvar cabbage-plone-buildout--tests-persp-prefix "*tests*")
(defvar cabbage-plone-buildout--default-compilation-fun 'pdb)
(defcustom cabbage-plone-buildout--use-local-pep8 nil
  "Use pep8 executable from buildout when there is one."
  :type 'boolean
  :group 'cabbage)


(defun cabbage-plone-run (&optional known-names persp-prefix arguments first-match)
  "Searches for a known instance in the current buildout at starts it in pdb mode."
  (interactive)

  (catch 'exit
    (let ((cmd (cabbage-plone-buildout--get-command known-names first-match))
          (persp-prefix (or persp-prefix cabbage-plone-buildout--run-persp-prefix)))
      (when (not cmd)
        (message "Could not find any buildout instance.")
        (throw 'exit nil))

      (let* ((script (car (split-string cmd)))
             (args (mapconcat 'identity (cdr (split-string cmd " ")) " ")))

        (if arguments
            (setq args arguments)
          (setq args (read-string
                      (concat script " ") args
                      'cabbage-plone-buildout--instance-argument-history)))

        (setq cmd (concat script " " args))

        (if (not cabbage-plone-run-in-perspective)
            (funcall cabbage-plone-buildout--default-compilation-fun cmd)
          (let ((script-name (car (last (split-string script "/")))))
            (cabbage-plone--run-pdb-in-persp cmd
                                           script-name persp-prefix)))))))

(defun cabbage-plone-tests (&optional arguments first-match)
  "Run tests in current buildout."
  (interactive)

  (cabbage-plone-run cabbage-plone-known-buildout-test-scripts
                   cabbage-plone-buildout--tests-persp-prefix
                   arguments
                   first-match))


(defun cabbage-plone--run-pdb-in-persp (cmd script-name persp-prefix)
  (let ((target-persp-name nil)
        (current-persp-name (persp-name persp-curr)))

    (if (eq (string-match persp-prefix current-persp-name) 0)
        (setq target-persp-name current-persp-name)

      (setq target-persp-name (concat persp-prefix current-persp-name "/" script-name))
      (cabbage-persp target-persp-name))

    (let ((new-buffer-name (concat target-persp-name "*gud*")))
      (set-buffer (buffer-name (funcall cabbage-plone-buildout--default-compilation-fun cmd)))
      (ignore-errors (kill-buffer new-buffer-name))
      (rename-buffer new-buffer-name))))


(defun cabbage-plone-buildout--get-command (&optional known-names first-match)
  "Returns the command (absolute path and arguments) of the first found instance
script in this buildout"

  (let ((instances (or known-names cabbage-plone-known-buildout-instances))
        (inst nil)
        (path nil)
        (buildout-root (cabbage-plone--find-buildout-root default-directory first-match)))
    (if buildout-root

        (catch 'loop
          (while instances
            (setq inst (car instances))
            (setq instances (cdr instances))
            (setq path (concat buildout-root (car inst)))

            (if (file-exists-p path)
                (if (car (cdr inst))
                    (throw 'loop (concat path " " (car (cdr inst))))
                  (throw 'loop path))))))))


(defun cabbage-plone--pdb-hook ()
  (compilation-shell-minor-mode t)
  (gud-def gud-break  "break %d%f:%l"  "\C-b" "Set breakpoint at current line.")
  (gud-def gud-remove "clear %d%f:%l"  "\C-d" "Remove breakpoint at current line"))

(add-hook 'pdb-mode-hook 'cabbage-plone--pdb-hook)


(defun cabbage-plone--run-single-file-tests (filename)
  (let ((cabbage-plone-run-in-perspective nil)
        (cabbage-plone-buildout--default-compilation-fun 'compile)
        (testname (file-name-sans-extension
                   (car (last (split-string filename "/"))))))
    (cabbage-plone-tests (concat "-t " testname) t)))

(defun cabbage-plone--python-setup-testing ()
  (when (and buffer-file-name (string-match "/tests" buffer-file-name))
    (setq cabbage-testing-execute-function
          'cabbage-plone--run-single-file-tests)))
(add-hook 'python-mode-hook 'cabbage-plone--python-setup-testing)


(defun cabbage-plone--load-local-configuration ()
  (when cabbage-plone-buildout--use-local-pep8

    (defadvice python-pep8 (around python-pep8-around)
      (let* ((ori-command python-pep8-command)
             (python-pep8-command
              (or
               (cabbage-plone-buildout--get-command '(("bin/pep8" "")) t)
               ori-command)))

        ad-do-it))

    (defun cabbage-plone--pep8-package ()
      (interactive)
      (when buffer-file-name (save-buffer))
      (cabbage-vendor 'python-pep8)
      (require 'tramp)

      (let* ((command (cabbage-plone-buildout--get-command '(("bin/pep8" "--absolute")) t)))
        (when command
          (add-to-list 'compilation-finish-functions 'cabbage-python-pep8-finished)
          (compilation-start command 'python-pep8-mode))

        (message "No bin/pep8 found.")))

    (cabbage-global-set-key (kbd "C-c f p") 'cabbage-plone--pep8-package)))


(add-hook 'cabbage-initialized-hook 'cabbage-plone--load-local-configuration)
