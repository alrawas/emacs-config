;;; my-todotxt.el --- Helpers for todotxt.el -*- lexical-binding: t; -*-

;;; Commentary:

;; Open tasks live in ~/org/todo.txt in todo.txt format: one self-contained
;; line each, carrying its own +project, @context and due: date.  todotxt.el
;; edits it in Emacs (SPC a), tuxedo edits the same file in the terminal, and
;; neither owns it.  `A' archives completed lines to the sibling done.txt,
;; which is the same file tuxedo archives to.
;;
;; Inside: a add, e edit, c toggle complete, r priority, d due date, t tag,
;; / filter for, \ filter out, l clear filters, i hide done, A archive,
;; R reload, u undo, q bury, ? the full list.  SPC stays the leader.
;;
;; Filters are invisible by default -- hidden lines just aren't there, with
;; nothing saying why.  `my/todotxt-header' names what is being filtered out
;; and how many lines that costs you, so `l' never has to be a guess.
;;
;; todotxt.el's own `todotxt-archive' is broken: it appends each line to
;; done.txt without a trailing newline, so the next one lands on the same
;; line, and its loop body returns t unconditionally, so if a delete ever
;; fails to advance point it appends the same line forever.  That hangs
;; Emacs and corrupts done.txt.  `my/todotxt-archive' replaces it.

;;; Code:

(defun my/todotxt-filter-label (f)
  "Readable name for one predicate in `todotxt-active-filters'.
The keyword filters are lambdas built at runtime, so the word has to be read
back out of the lambda's own source."
  (if (eq f 'todotxt-complete-p)
      "done hidden"
    (let* ((flat (format "%S" f))
           (word (and (string-match "line-match \"\\([^\"]+\\)\"" flat)
                      (match-string 1 flat))))
      (cond ((null word) "a filter")
            ((string-match-p "(not " flat) (concat "only " word))
            (t (concat "without " word))))))

(defun my/todotxt-header ()
  "Header line for todo.txt: what is filtered, and what it is hiding."
  (let* ((hidden (length (seq-filter
                          (lambda (o) (eq (overlay-get o 'invisible) t))
                          (overlays-in (point-min) (point-max)))))
         (total (save-excursion
                  (save-match-data
                    (how-many "^[^[:space:]]" (point-min) (point-max)))))
         (labels (delete-dups (mapcar #'my/todotxt-filter-label
                                      todotxt-active-filters))))
    (if (null labels)
        (propertize (format " %d task%s" total (if (= total 1) "" "s"))
                    'face 'shadow)
      (concat
       (propertize " FILTERED " 'face '(:inherit warning :weight bold))
       (propertize (mapconcat #'identity labels " \u00b7 ") 'face 'warning)
       (propertize (format "  %d of %d shown, press l to clear"
                           (- total hidden) total)
                   'face 'shadow)))))

(defun my/todotxt-archive ()
  "Move every completed line out of todo.txt and onto the end of done.txt.
Collects the lines first and writes them in one go, each newline-terminated, so
a missing final newline cannot concatenate records. The loop always advances."
  (interactive)
  (todotxt-remove-overlays)
  (let ((done '())
        (target (expand-file-name "done.txt" (file-name-directory todotxt-file))))
    (save-excursion
      (goto-char (point-min))
      (let ((inhibit-read-only t))
        (while (not (eobp))
          (if (and (not (todotxt-line-empty-p)) (todotxt-complete-p))
              (progn
                (push (buffer-substring-no-properties
                       (line-beginning-position) (line-end-position))
                      done)
                ;; deleting leaves point at the start of the next line already
                (delete-region (line-beginning-position)
                               (min (point-max) (1+ (line-end-position)))))
            (forward-line 1)))))
    (if (null done)
        (message "Nothing completed to archive")
      (setq done (nreverse done))
      (with-temp-buffer
        (insert (mapconcat #'identity done "\n") "\n")
        (write-region (point-min) (point-max) target t 'silent))
      (when todotxt-save-after-change (save-buffer))
      (todotxt-apply-active-filters)
      (message "Archived %d line%s to done.txt"
               (length done) (if (= (length done) 1) "" "s")))))

(provide 'my-todotxt)
;;; my-todotxt.el ends here
