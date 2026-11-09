;;; which-keymap.el --- Find out which keymap a key came from -*- lexical-binding: t; -*-

;;; Commentary:

;; `C-h k' names the keymap a key resolved in, but only the winning one.  With
;; evil in the picture the interesting question is usually who got *shadowed*:
;; evil's state maps live in `emulation-mode-map-alists', which sits above the
;; major-mode map, and general's leader sits above both in an intercept map.
;;
;; `my/which-keymap' walks `current-active-maps' and reports every active map
;; that binds the key, in the order Emacs consults them.
;;
;; NOTE: this file needs its own lexical-binding cookie.  Under dynamic
;; binding the `dolist' variable becomes a global whose value is the keymap,
;; and `help-fns-find-keymap-name' then finds *it* instead of the real name.

;;; Code:

(require 'help-fns)

(defun my/keymap-label (km)
  "Best available human name for keymap KM."
  (or (help-fns-find-keymap-name km)   ; a global variable holding it
      (keymap-prompt km)               ; evil names its aux maps this way
      "<anonymous>"))

;;;###autoload
(defun my/which-keymap (key)
  "Show every active keymap that binds KEY, in the order Emacs consults them.
The first row is the winner; every row below it is shadowed."
  (interactive "kKey: ")
  (let (hits)
    (dolist (km (current-active-maps t))
      (let ((def (lookup-key km key)))
        (when (and def (not (numberp def)))
          (push (format "%-38s %s"
                        (my/keymap-label km)
                        (if (keymapp def) "<prefix keymap>" def))
                hits))))
    (setq hits (delete-dups (nreverse hits)))
    (if (null hits)
        (message "%s is unbound here" (key-description key))
      (with-output-to-temp-buffer "*which-keymap*"
        (princ (format "%s   state: %s   mode: %s\n\n"
                       (key-description key)
                       (if (boundp 'evil-state) evil-state "n/a")
                       major-mode))
        (princ (format "%-38s %s\n" "KEYMAP" "BINDING"))
        (princ (format "%s %s\n" (make-string 38 ?-) "-------"))
        (princ (mapconcat #'identity hits "\n"))
        (princ "\n\nFirst row wins; rows below are shadowed.\n")))))

(provide 'which-keymap)

;;; which-keymap.el ends here
