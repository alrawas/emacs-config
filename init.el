;;; init.el --- Abed's Emacs -*- lexical-binding: t; -*-

;;; Commentary:

;; Read it top to bottom.  Every package gets one `use-package' block
;; holding its settings (:custom), hooks (:hook) and keys (:bind), so each
;; block can be read, moved or deleted on its own.  What gets downloaded is
;; one list, under Packages; everything else ships with Emacs.
;;
;; One config for Emacs 29 and 30, in a window or in a terminal (emacs -nw).
;; Commands I wrote myself live in lisp/, themes in themes/.
;;
;; TAB on a ";;;" line folds that section (zc / zo / zR work too).

;;; Code:

;;; Packages

;; Everything downloaded, in one list -- like a Nix package list.  Startup
;; installs whatever is missing.  To drop a package, delete it here and run
;; M-x package-autoremove.  Anything not listed ships with Emacs.
;;
;; GNU and NonGNU ELPA publish tagged releases; MELPA builds every commit.
;; The priorities make package.el take a release whenever one exists, and
;; MELPA only for what isn't elsewhere (evil-collection, todotxt).
(use-package package
  :custom
  (package-archives '(("gnu"    . "https://elpa.gnu.org/packages/")
                      ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                      ("melpa"  . "https://melpa.org/packages/")))
  (package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1)))
  (package-selected-packages
   '(evil evil-collection                   ; vim keys everywhere
     vertico orderless marginalia consult   ; completion
     company                                ; completion popup in code
     magit                                  ; git
     go-mode                                ; Go (Java's mode is built in)
     hl-todo                                ; highlight TODO and FIXME
     todotxt                                ; todo.txt
     which-key))                            ; built into Emacs 30, downloaded on 29
  :config
  (unless (seq-every-p #'package-installed-p package-selected-packages)
    (package-refresh-contents)
    (package-install-selected-packages 'noconfirm)))

;;; Where things are

;; A GUI Emacs started from the desktop doesn't get your shell's PATH (yours
;; only had /usr/local/bin and /usr/bin), so it couldn't find go, gopls or
;; java.  Add the usual tool folders; ones missing on this machine are skipped.
(dolist (dir '("~/.local/bin" "~/go/bin" "/usr/local/go/bin"
               "~/.sdkman/candidates/java/current/bin"
               "~/.sdkman/candidates/maven/current/bin"
               "~/.sdkman/candidates/gradle/current/bin"))
  (setq dir (expand-file-name dir))
  (when (and (file-directory-p dir) (not (member dir exec-path)))
    (push dir exec-path)
    (setenv "PATH" (concat dir path-separator (getenv "PATH")))))

;; My own code: lisp/*.el
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;;; Emacs itself

(use-package emacs
  :custom
  (inhibit-startup-screen t)            ; start in *scratch*
  (initial-scratch-message "\
;; ARAWAS Emacs.  SPC is the leader; M-SPC in insert state.
;; Leader letters mirror Emacs: SPC h = C-h, SPC p = C-x p, SPC r = C-x r,
;; SPC w = C-w, SPC x = C-x.  Anything you read in the manual works.
;;
;; SPC ,    buffers, recent files, bookmarks  SPC .    find a file
;; SPC SPC  run a command (M-x)               SPC s r  search the project
;; SPC p p  switch project, then f g m e      SPC g g  magit
;; SPC r m  bookmark this spot                SPC r b  jump to a bookmark
;; SPC c a  code actions (also gd, K, C-o)    SPC h k  what does a key do?
;; SPC m c  capture a note                    SPC m w  write today
;; SPC a    todo.txt                          SPC b k  close this buffer
;;
;; Config: SPC f c (zM folds it).  Guide: ~/.config/emacs/docs/index.html

")
  (ring-bell-function #'ignore)         ; no beeping
  (create-lockfiles nil)                ; no .#file symlinks next to your files
  (backup-directory-alist               ; file~ backups go here, not next to the file
   `(("." . ,(expand-file-name "backups/" user-emacs-directory))))
  ;; M-x customize writes here, and it's never loaded: settings live in
  ;; this file and nowhere else.
  (custom-file (expand-file-name "custom.el" user-emacs-directory))
  (native-comp-async-report-warnings-errors 'silent) ; no popups about packages' compile warnings
  (line-spacing 0.12)                   ; a little air between lines (GUI only)
  :hook
  (((prog-mode text-mode conf-mode) . display-line-numbers-mode)
   (text-mode . visual-line-mode))      ; prose wraps at the window edge, code doesn't
  :bind
  (("<escape>" . keyboard-escape-quit)  ; one ESC leaves the minibuffer
   ("C-=" . text-scale-increase)        ; zoom (GUI)
   ("C--" . text-scale-decrease))
  :config
  (electric-pair-mode))                 ; typing ( inserts ()

;;; Evil

;; evil-want-keybinding and evil-want-C-i-jump are in early-init.el: evil
;; must see them before it ever loads.

(use-package evil
  :custom
  (evil-undo-system 'undo-redo)         ; C-r redoes, with Emacs's own undo
  (evil-split-window-below t)           ; :split opens below
  (evil-vsplit-window-right t)          ; :vsplit opens on the right
  :config
  (evil-mode 1))                        ; RET in normal state moves down, as in vim;
                                        ; org binds it to follow links (see Org)

(use-package evil-collection            ; vim keys for dired, magit, help, ...
  :after evil
  :custom
  (evil-collection-key-blacklist '("SPC")) ; SPC stays the leader in every mode
  ;; In shells and REPLs (eshell, ielm) RET runs the command in either
  ;; state, like a terminal; S-RET still inserts a newline.  Out of the
  ;; box, RET in insert state there only adds a line.
  (evil-collection-binding-overrides
   '((repl-submit :state (normal insert))
     (repl-newline :enabled nil)))
  :config
  (evil-collection-init))

;;; Leader key

;; SPC in normal, visual and motion state; M-SPC everywhere else (insert
;; state, the minibuffer).  A letter that matches an Emacs prefix *is* that
;; prefix, so the leader only shortens keys Emacs already has:
;;
;;   SPC h = C-h     help          SPC r = C-x r   bookmarks, registers
;;   SPC p = C-x p   projects      SPC w = C-w     windows (evil)
;;   SPC x = C-x     everything else
;;
;; The strings are the labels which-key shows for each group.

(defun my/find-init-file ()
  "Open this file."
  (interactive)
  (find-file user-init-file))

(defun my/sudo-this-file ()
  "Reopen the current file as root, through TRAMP's /sudo:: method."
  (interactive)
  (find-alternate-file (concat "/sudo::" buffer-file-name)))

(defvar-keymap my/leader-map
  "SPC" #'execute-extended-command
  "."   #'find-file
  ","   #'consult-buffer
  "a"   #'todotxt
  "TAB TAB" #'comment-line
  "h" (cons "help (C-h)"        help-map)
  "p" (cons "project (C-x p)"   project-prefix-map)
  "r" (cons "bookmarks (C-x r)" ctl-x-r-map)
  "w" (cons "windows (C-w)"     evil-window-map)
  "x" (cons "C-x"               ctl-x-map)
  "b" (cons "buffers" (define-keymap
                        "b" #'consult-buffer
                        "i" #'ibuffer
                        "k" #'kill-current-buffer
                        "n" #'next-buffer
                        "p" #'previous-buffer
                        "r" #'revert-buffer
                        "s" #'save-buffer
                        "x" #'scratch-buffer))
  "c" (cons "code" (define-keymap
                     "a" #'eglot-code-actions
                     "d" #'flymake-show-buffer-diagnostics
                     "e" #'eglot
                     "f" #'eglot-format-buffer
                     "r" #'eglot-rename))
  "d" (cons "dired" (define-keymap
                      "d" #'dired
                      "j" #'dired-jump))
  "e" (cons "eval" (define-keymap
                     "b" #'eval-buffer
                     "d" #'eval-defun
                     "e" #'eval-expression
                     "l" #'eval-last-sexp
                     "r" #'eval-region
                     "s" #'eshell))
  "f" (cons "files" (define-keymap
                      "c" #'my/find-init-file
                      "r" #'consult-recent-file
                      "U" #'my/sudo-this-file))
  "g" (cons "git" (define-keymap
                    "g"   #'magit-status
                    "SPC" #'magit-dispatch
                    "f"   #'magit-file-dispatch
                    "b"   #'magit-blame-addition
                    "l"   #'magit-log-current
                    "L"   #'magit-log-buffer-file
                    "d"   #'magit-diff-buffer-file
                    "c"   #'magit-clone
                    "i"   #'magit-init))
  "m" (cons "org" (define-keymap
                    "c"   #'org-capture
                    "e"   #'org-export-dispatch
                    "i"   #'org-toggle-item
                    "t"   #'org-todo
                    "l"   #'my/org-open-life
                    "w"   #'my/org-write-today
                    "b -" #'org-table-insert-hline
                    "d t" #'org-time-stamp))
  "s" (cons "search" (define-keymap
                       "s" #'consult-line
                       "i" #'consult-imenu
                       "r" #'consult-ripgrep
                       "d" #'dictionary-search
                       "m" #'man))
  "t" (cons "toggle" (define-keymap
                       "l" #'display-line-numbers-mode
                       "t" #'visual-line-mode)))

(keymap-set evil-motion-state-map "SPC" my/leader-map)
(keymap-global-set "M-SPC" my/leader-map)

;;; Completion

;; Four small packages that improve Emacs's own completion instead of
;; replacing it, so plain M-x, find-file and C-x b all get them.

(use-package vertico                    ; candidates in a vertical list
  :hook (after-init . vertico-mode))

(use-package orderless                  ; match space-separated words in any order
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides        ; in file names, ~/.c/em finds ~/.config/emacs
   '((file (styles partial-completion)))))

(use-package marginalia                 ; descriptions next to candidates
  :hook (after-init . marginalia-mode))

(use-package consult                    ; search and jump commands with live preview
  :bind
  (([remap switch-to-buffer]         . consult-buffer)         ; C-x b
   ([remap project-switch-to-buffer] . consult-project-buffer) ; SPC p b
   ([remap bookmark-jump]            . consult-bookmark)))     ; SPC r b

(use-package savehist                   ; remember minibuffer history; vertico sorts by it
  :hook (after-init . savehist-mode))

(use-package recentf                    ; remember recently opened files
  :custom (recentf-max-saved-items 200)
  :hook (after-init . recentf-mode))

;;; Help

(use-package which-key                  ; after a prefix like SPC, show what comes next
  :hook (after-init . which-key-mode))

(use-package which-keymap               ; lisp/which-keymap.el, my own
  :bind (:map help-map ("K" . my/which-keymap))) ; SPC h K: every keymap binding a key

;;; Files and projects

;; Every git repo is a project (SPC p = C-x p).  A repo is remembered the
;; first time you use a SPC p command inside it; import a whole folder of
;; them with M-x project-remember-projects-under.
(use-package project
  :bind (:map project-prefix-map ("m" . magit-project-status)) ; SPC p m: magit here
  :config                               ; and `m' in the SPC p p menu
  (add-to-list 'project-switch-commands '(magit-project-status "Magit") t))

(use-package dired
  :defer t
  :custom
  (dired-listing-switches "-alh --group-directories-first") ; readable sizes, folders first
  (dired-kill-when-opening-new-dired-buffer t) ; one dired buffer, not one per folder
  (dired-dwim-target t)                 ; copy/move suggests the other dired window
  :config
  (evil-define-key 'normal dired-mode-map
    "h" #'dired-up-directory
    "l" #'dired-find-file))

(use-package autorevert                 ; reload files changed outside Emacs (tuxedo, git)
  :hook (after-init . global-auto-revert-mode))

(use-package saveplace                  ; reopen files where you left off
  :hook (after-init . save-place-mode))

;;; Git

(use-package magit
  :defer t
  :custom
  (magit-display-buffer-function        ; status opens in the current window
   #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk 'all))        ; highlight changed words, not only lines

;;; Programming

(use-package outline                    ; fold elisp files (like this one) by their headings
  :custom (outline-minor-mode-cycle t)  ; TAB on a ";;;" or "(" line at column 0 folds it
  :hook (emacs-lisp-mode . outline-minor-mode))

(use-package company                    ; completion popup while typing; works in a terminal
  :hook (prog-mode . company-mode)
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2)
  (company-tooltip-align-annotations t))

;; Eglot talks to language servers (gopls, jdtls, ...): completion, go to
;; definition (gd), docs (K), rename and fixes (SPC c), errors in the buffer
;; (via flymake).  The servers are separate programs, installed per machine.
(use-package eglot
  :hook ((go-mode java-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)                ; stop a server when its last file closes
  (read-process-output-max (* 1024 1024))) ; read server replies in bigger chunks

(use-package go-mode                    ; outside tree-sitter, Emacs has no Go mode
  :preface
  (defun my/gofmt-on-save ()
    "Run gofmt on this buffer every time it is saved."
    (add-hook 'before-save-hook #'gofmt-before-save nil t))
  :hook (go-mode . my/gofmt-on-save))

;; Java uses the built-in java-mode, with jdtls through Eglot (above).

(use-package hl-todo                    ; highlight TODO, FIXME, HACK, NOTE in code
  :hook (prog-mode . hl-todo-mode))

;;; Terminal

;; Only `emacs -nw' and `emacsclient -t' use these; window frames ignore them.

(use-package xt-mouse                   ; clicks and scrolling (Shift+drag: terminal's own selection)
  :hook (after-init . xterm-mouse-mode))

;; Copying in a terminal Emacs puts the text on your local clipboard, even
;; over SSH, through the OSC 52 escape code.  Inside tmux, also put
;; `set -g set-clipboard on' in ~/.tmux.conf.
(use-package term/xterm
  :defer t
  :custom
  (xterm-extra-capabilities '(setSelection))
  (xterm-tmux-extra-capabilities '(modifyOtherKeys setSelection)))

;;; Org and notes

;; ~/org is notes only: life.org for one-liners, writing/YYYY.org for prose.
;; Tasks live in todo.txt (below).  My commands are in lisp/my-org-notes.el.
;;
;; A plain setq, not :custom: a :custom value only arrives when its package
;; loads, and life.org, writing/, the diary and todo.txt all need this
;; before org itself has loaded.
(setq org-directory "~/org/")
(require 'my-org-notes)

(use-package org
  :custom
  (org-return-follows-link t)           ; RET on a link opens it
  (org-bookmark-names-plist nil)        ; no automatic "org-capture-last-stored" bookmarks
  (org-edit-src-content-indentation 0)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "PROG(p)" "WAIT(w)" "HOLD(h)"
               "|" "DONE(d)" "DELEGATED(l)" "KILL(k)")))
  (org-log-done 'time)
  (org-refile-use-outline-path 'file)
  (org-outline-path-complete-in-steps nil)
  (org-refile-allow-creating-parent-nodes 'confirm)
  ;; Four one-line templates, all into life.org (file+headline creates the
  ;; heading if it's missing).
  (org-capture-templates
   '(("s" "Spark"   entry (file+headline my/org-life-file "Sparks")
      "* %<[%Y-%m-%d %a]> %?" :prepend t)
     ("i" "Learned" entry (file+headline my/org-life-file "TIL")
      "* %<[%Y-%m-%d %a]> %?" :prepend t)
     ("p" "Place"   entry (file+headline my/org-life-file "Places")
      "* %<[%Y-%m-%d %a]> %? :want:" :prepend t)
     ("q" "Queue"   entry (file+headline my/org-life-file "Queue")
      "* %<[%Y-%m-%d %a]> %? :want:" :prepend t)))
  :hook
  ((org-mode . org-indent-mode)         ; indent text under headings (display only)
   (org-mode . my/org-no-angle-pairs)   ; so <s TAB expands instead of pairing <>
   (find-file . my/org-auto-frontmatter)) ; a new .org file gets a title/date header
  :config
  (require 'org-tempo)                  ; <s TAB -> source block, <q TAB -> quote, ...
  (evil-define-key 'normal org-mode-map (kbd "RET") #'my/org-return-follow-link))

;; Emacs's own diary: plain text, dated, no agenda needed.
(use-package calendar
  :custom
  (diary-file (expand-file-name "diary" org-directory))
  :init
  (add-to-list 'display-buffer-alist     ; calendar opens in a strip at the bottom
               '("\\*Calendar\\*" display-buffer-in-side-window
                 (side . bottom) (window-height . 0.3)))
  :config
  (calendar-set-date-style 'iso)        ; YYYY-MM-DD; also updates diary formats
  ;; Vanilla adds entries under `i', which evil takes for insert; use `gi'.
  (with-eval-after-load 'evil-collection-calendar
    (evil-collection-define-key 'normal 'calendar-mode-map
      "gid" #'diary-insert-entry
      "giw" #'diary-insert-weekly-entry
      "gim" #'diary-insert-monthly-entry
      "giy" #'diary-insert-yearly-entry)))

;;; todo.txt

;; SPC a.  Carried over unchanged; the helpers (filter header line, fixed
;; archive) are in lisp/my-todotxt.el.
(require 'my-todotxt)

(use-package todotxt
  :init
  (setq todotxt-file (expand-file-name "todo.txt" org-directory))
  :config
  ;; The interface is single-letter keys, but putting the buffer in evil's emacs
  ;; state to get them kills SPC as the leader inside it. Stay in normal state
  ;; and bind them there instead: the buffer is read-only, so the evil keys
  ;; being shadowed (i, a, d, t, l) had nothing to do here anyway. j/k/gg/G
  ;; still come from evil.
  (with-eval-after-load 'evil
    (evil-define-key 'normal todotxt-mode-map
      "a" #'todotxt-add-item
      "e" #'todotxt-edit-item
      "c" #'todotxt-complete-toggle
      "r" #'todotxt-add-priority
      "d" #'todotxt-add-due-date
      "t" #'todotxt-tag-item
      "/" #'todotxt-filter-for
      "\\" #'todotxt-filter-out
      "l" #'todotxt-unhide-all
      "i" #'todotxt-show-incomplete
      "A" #'my/todotxt-archive
      "N" #'todotxt-nuke-item
      "R" #'todotxt-revert
      "u" #'todotxt-undo
      "q" #'todotxt-bury
      "?" #'describe-mode))
  ;; :eval re-runs on redisplay, so no hook is needed when a filter changes
  (add-hook 'todotxt-mode-hook
            (lambda ()
              (setq header-line-format '((:eval (my/todotxt-header)))))))

;;; Look

;; themes/ holds single-file themes.  Try others live with M-x consult-theme.
(setq custom-theme-directory (expand-file-name "themes/" user-emacs-directory))
(load-theme 'gruber-darker t)
(set-face-attribute 'font-lock-comment-face nil :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil :slant 'italic)

;;; init.el ends here
