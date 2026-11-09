;;; my-org-notes.el --- life.org, writing/, and small org helpers -*- lexical-binding: t; -*-

;;; Commentary:

;; ~/org holds notes, not tasks (tasks are in ~/org/todo.txt):
;;
;;   life.org          one-liners under Sparks / TIL / Places / Queue
;;   writing/YYYY.org  one dated entry a day, prose, as long as you like
;;   projects/         reference notes per project
;;
;; Neither is in `org-agenda-files', so nothing in them can nag you.
;; writing/ is split per year because it's the only one of these that grows.

;;; Code:

(defun my/org-life-file ()
  "Path to the one-liner file: sparks, things learned, places, queue."
  (expand-file-name "life.org" org-directory))

(defun my/org-open-life ()
  "Open the life file."
  (interactive)
  (find-file (my/org-life-file)))

(defun my/org-writing-file ()
  "Path to this year's writing file, creating the directory if needed."
  (make-directory (expand-file-name "writing" org-directory) t)
  (expand-file-name (format-time-string "writing/%Y.org") org-directory))

(defun my/org-write-today ()
  "Open this year's writing file at today's entry, creating it at the top.
Point lands after whatever is already written there, so a second sitting on the
same day continues the same entry instead of starting a new one."
  (interactive)
  (find-file (my/org-writing-file))
  (let ((today (format-time-string "* [%Y-%m-%d %a]")))
    (goto-char (point-min))
    (unless (search-forward today nil t)
      ;; newest first, but below any #+keyword lines at the top
      (goto-char (point-min))
      (while (looking-at "^[#\n]") (forward-line 1))
      (insert today "\n\n"))
    (org-back-to-heading t)
    (org-end-of-subtree t t)
    (skip-chars-backward " \t\n")
    (insert "\n"))
  (recenter))

(defun my/org-auto-frontmatter ()
  "Insert org frontmatter when a new org file is created.
The title comes from the file name, the date is today."
  (when (and (eq major-mode 'org-mode)
             (= (buffer-size) 0))
    (let* ((filename (file-name-sans-extension
                      (file-name-nondirectory (buffer-file-name))))
           (title (replace-regexp-in-string "[_-]" " " filename))
           (title (capitalize title))
           (date (format-time-string "[%Y-%m-%d %a]")))
      (insert (format "#+title: %s\n#+date: %s\n#+author: %s\n#+description: \n#+filetags: \n\n"
                      title date user-login-name))
      (search-backward "#+description: ")
      (end-of-line))))

(defun my/org-return-follow-link ()
  "Follow link at point if on a link, otherwise do nothing in normal mode."
  (interactive)
  (when (org-in-regexp org-link-any-re)
    (org-open-at-point)))

(defun my/org-no-angle-pairs ()
  "Stop `electric-pair-mode' from closing < in this buffer.
Otherwise typing <s inserts <s> and org-tempo's <s TAB can't expand."
  (let ((inhibit electric-pair-inhibit-predicate))
    (setq-local electric-pair-inhibit-predicate
                (lambda (c) (or (eq c ?<) (funcall inhibit c))))))

(provide 'my-org-notes)
;;; my-org-notes.el ends here
