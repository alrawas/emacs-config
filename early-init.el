;;; early-init.el --- Runs before the first frame appears -*- lexical-binding: t; -*-

;;; Code:

;; Collect garbage less often.  At the 800 KB default the old config spent
;; about half its startup time collecting garbage, and language servers
;; allocate a lot too.
(setq gc-cons-threshold (* 64 1024 1024))

;; Evil reads these the moment it loads.  On a fresh machine that happens
;; while packages are still installing (compiling evil-collection loads
;; evil), before init.el reaches its Evil section -- so they live here.
(setq evil-want-keybinding nil          ; evil-collection does other modes' keys
      evil-want-C-i-jump nil)           ; TAB stays TAB; a terminal can't tell TAB from C-i

;; How graphical frames look.  Terminal frames ignore all of this, so the
;; same file works for `emacs -nw' -- and it also reaches frames a daemon
;; opens later, which the old (find-font ...) check at startup missed.
(setq default-frame-alist
      '((menu-bar-lines . 0)
        (tool-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (font . "IosevkaTerm Nerd Font Mono-10")
        (alpha-background . 90)))       ; 90% opaque background, text stays solid

;;; early-init.el ends here
