;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Xandor Schiefer"
      user-mail-address "me@xandor.co.za")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Iosevka Nerd Font" :size @12px@ :weight 'light)
      doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size @12px@ :weight 'light)
      doom-big-font (font-spec :family "Iosevka Nerd Font" :size @18px@ :weight 'light)
      doom-symbol-font (font-spec :family "Symbols Nerd Font" :size @12px@)
      doom-serif-font (font-spec :family "Iosevka Nerd Font" :size @12px@ :weight 'light)
      nerd-icons-font-family "Iosevka NF Light")
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-nord)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq-default display-line-numbers-type 'relative
	      display-line-numbers-widen t)

(defun me/relative-line-numbers ()
  "Show relative line numbers."
  (unless (equal display-line-numbers nil)
    (setq-local display-line-numbers 'relative)))

(defun me/absolute-line-numbers ()
  "Show absolute line numbers."
  (unless (equal display-line-numbers nil)
    (setq-local display-line-numbers t)))

(add-hook 'evil-insert-state-entry-hook #'me/absolute-line-numbers)
(add-hook 'evil-insert-state-exit-hook #'me/relative-line-numbers)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "@XDG_DOCUMENTS_DIR@/notes/"
      org-roam-directory org-directory
      org-roam-dailies-directory "journal/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Fish shell compat
(setq shell-file-name (executable-find "bash"))
(setq-default vterm-shell (executable-find "fish"))
(setq-default explicit-shell-file-name (executable-find "fish"))

(use-package! with-editor
  :demand t
  :hook ((shell-mode . with-editor-export-editor)
	 (eshell-mode . with-editor-export-editor)
	 (term-exec . with-editor-export-editor)
	 (vterm-mode . with-editor-export-editor))
  :config (shell-command-with-editor-mode))

(use-package! magit-delta
  :hook ((magit-mode . magit-delta-mode))
  :config
  (setq magit-delta-executable "@delta@/bin/delta"
	magit-delta-default-dark-theme "Nord")
  (add-to-list 'magit-delta-delta-args "--features" t)
  (add-to-list 'magit-delta-delta-args "magit-delta" t))

(use-package! org
  :config
  (setq org-return-follows-link t))

(use-package! org-web-tools
  :after org)
(use-package! ox-clip
  :after org)

;; Boris Buliga - Task management with org-roam Vol. 5: Dynamic and fast agenda
;; https://d12frosted.io/posts/2021-01-16-task-management-with-roam-vol5.html
(use-package! vulpea
  :demand t
  :hook ((org-roam-db-autosync-mode . vulpea-db-autosync-enable)))

(defun vulpea-project-p ()
  "Return non-nil if current buffer has any todo entry.

TODO entries marked as done are ignored, meaning the this
function returns nil if current buffer contains only completed
tasks."
  (seq-find                                 ; (3)
   (lambda (type)
     (eq type 'todo))
   (org-element-map                         ; (2)
       (org-element-parse-buffer 'headline) ; (1)
       'headline
     (lambda (h)
       (org-element-property :todo-type h)))))

(defun vulpea-project-update-tag ()
  "Update PROJECT tag in the current buffer."
  (when (and (not (active-minibuffer-window))
	     (vulpea-buffer-p))
    (save-excursion
      (goto-char (point-min))
      (let* ((tags (vulpea-buffer-tags-get))
	     (original-tags tags))
	(if (vulpea-project-p)
	    (setq tags (cons "project" tags))
	  (setq tags (remove "project" tags)))

	;; cleanup duplicates
	(setq tags (seq-uniq tags))

	;; update tags if changed
	(when (or (seq-difference tags original-tags)
		  (seq-difference original-tags tags))
	  (apply #'vulpea-buffer-tags-set tags))))))

(defun vulpea-buffer-p ()
  "Return non-nil if the currently visited buffer is a note."
  (and buffer-file-name
       (string-prefix-p
	(expand-file-name (file-name-as-directory org-roam-directory))
	(file-name-directory buffer-file-name))))

(defun vulpea-project-files ()
  "Return a list of note files containing 'project' tag." ;
  (seq-uniq
   (seq-map
    #'car
    (org-roam-db-query
     [:select [nodes:file]
      :from tags
      :left-join nodes
      :on (= tags:node-id nodes:id)
      :where (like tag (quote "%\"project\"%"))]))))

(defun vulpea-agenda-files-update (&rest _)
  "Update the value of `org-agenda-files'."
  (setq org-agenda-files (vulpea-project-files)))

(add-hook 'find-file-hook #'vulpea-project-update-tag)
(add-hook 'before-save-hook #'vulpea-project-update-tag)

(advice-add 'org-agenda :before #'vulpea-agenda-files-update)
(advice-add 'org-todo-list :before #'vulpea-agenda-files-update)

(after! org (progn
	      (with-no-warnings
		(custom-declare-face '+org-todo-next   '((t (:inherit (bold font-lock-constant-face org-todo)))) "")
		(custom-declare-face '+org-todo-wait '((t (:inherit (bold warning org-todo)))) "")
		(custom-declare-face '+org-todo-hold '((t (:inherit (bold font-lock-doc-face org-todo)))) "")
		(custom-declare-face '+org-todo-kill '((t (:inherit (bold font-lock-comment-face org-todo)))) ""))

	      org-todo-keywords '((sequence
				   "TODO(t!)"  ; A single task (that is not made up of other tasks—which would be a /project/)
				   "NEXT(x!)"  ; A TODO that is the next action item in a project
				   "LOOP(r!)"  ; A recurring task
				   "WAIT(w!)"  ; A task that is current blocked because it is waiting for someone or something external
				   "|"
				   "DONE(d!)"  ; Done
				   "HOLD(h!)"  ; On hold due to me
				   "IDEA(i!)"  ; Someday/maybe
				   "KILL(k!)") ; Cancelled
				  (sequence
				   "[ ](T)"  ; A task that needs doing
				   "|"
				   "[?](W)"  ; Waiting
				   "[X](D)") ; Done
				  (sequence
				   "|"
				   "OKAY(o)"
				   "YES(y)"
				   "NO(n)"))

	      org-todo-keyword-faces
	      '(("NEXT" . +org-todo-next)
		("[?]"  . +org-todo-wait)
		("WAIT" . +org-todo-wait)
		("HOLD" . +org-todo-hold)
		("IDEA" . +org-todo-hold)
		("NO"   . +org-todo-kill)
		("KILL" . +org-todo-kill))

	      org-auto-align-tags nil
	      org-tags-column 0
	      org-catch-invisible-edits 'show-and-error
	      org-special-ctrl-a/e t
	      org-insert-heading-respect-content t

	      org-hide-emphasis-markers t
	      org-pretty-entities t
	      org-ellipsis "…"

	      ;; org-agenda-tags-column 0
	      ;; org-agenda-block-separator ?─
	      ;; org-agenda-time-grid
	      ;; '((daily today require-timed)
	      ;;   (800 1000 1200 1400 1600 1800 2000)
	      ;;   " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
	      ;; org-agenda-current-time-string
	      ;; "◀── now ─────────────────────────────────────────────────"

	      ;; display-line-numbers-mode 0
	      ;; variable-pitch-mode 1
	      ))

(use-package! org-modern
  :hook ((org-mode . org-modern-mode)
	 (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-star '("◉" "○" "✸" "✿" "✤" "✜" "◆" "▶")
	org-modern-table-vertical 1
	org-modern-table-horizontal 0.2
	org-modern-list '((43 . "➤")
			  (45 . "–")
			  (42 . "•"))
	org-modern-todo-faces
	'(("TODO" :inverse-video t :inherit org-todo)
	  ("NEXT" :inverse-video t :inherit +org-todo-next)
	  ("PROJ" :inverse-video t :inherit +org-todo-project)
	  ("STRT" :inverse-video t :inherit +org-todo-active)
	  ("[-]"  :inverse-video t :inherit +org-todo-active)
	  ("HOLD" :inverse-video t :inherit +org-todo-onhold)
	  ("WAIT" :inverse-video t :inherit +org-todo-onhold)
	  ("[?]"  :inverse-video t :inherit +org-todo-onhold)
	  ("KILL" :inverse-video t :inherit +org-todo-cancel)
	  ("NO"   :inverse-video t :inherit +org-todo-cancel))
	org-modern-footnote
	(cons nil (cadr org-script-display))
	org-modern-block-fringe nil
	org-modern-block-name
	'((t . t)
	  ("src" "»" "«")
	  ("example" "»–" "–«")
	  ("quote" "❝" "❞")
	  ("export" "⏩" "⏪"))
	org-modern-progress nil
	org-modern-priority nil
	org-modern-horizontal-rule (make-string 36 ?─)
	org-modern-keyword
	'((t . t)
	  ("title" . "𝙏")
	  ("subtitle" . "𝙩")
	  ("author" . "𝘼")
	  ("email" . #("" 0 1 (display (raise -0.14))))
	  ("date" . "𝘿")
	  ("property" . "☸")
	  ("options" . "⌥")
	  ("startup" . "⏻")
	  ("macro" . "𝓜")
	  ("bind" . #("" 0 1 (display (raise -0.1))))
	  ("bibliography" . "")
	  ("print_bibliography" . #("" 0 1 (display (raise -0.1))))
	  ("cite_export" . "⮭")
	  ("print_glossary" . #("ᴬᶻ" 0 1 (display (raise -0.1))))
	  ("glossary_sources" . #("" 0 1 (display (raise -0.14))))
	  ("include" . "⇤")
	  ("setupfile" . "⇚")
	  ("html_head" . "🅷")
	  ("html" . "🅗")
	  ("latex_class" . "🄻")
	  ("latex_class_options" . #("🄻" 1 2 (display (raise -0.14))))
	  ("latex_header" . "🅻")
	  ("latex_header_extra" . "🅻⁺")
	  ("latex" . "🅛")
	  ("beamer_theme" . "🄱")
	  ("beamer_color_theme" . #("🄱" 1 2 (display (raise -0.12))))
	  ("beamer_font_theme" . "🄱𝐀")
	  ("beamer_header" . "🅱")
	  ("beamer" . "🅑")
	  ("attr_latex" . "🄛")
	  ("attr_html" . "🄗")
	  ("attr_org" . "⒪")
	  ("call" . #("" 0 1 (display (raise -0.15))))
	  ("name" . "⁍")
	  ("header" . "›")
	  ("caption" . "☰")
	  ("results" . "🠶")))
  (custom-set-faces! '(org-modern-statistics :inherit org-checkbox-statistics-todo)))

(after! spell-fu
  (cl-pushnew 'org-modern-tag (alist-get 'org-mode +spell-excluded-faces-alist)))

(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
	org-appear-autosubmarkers t
	org-appear-autolinks nil)
  ;; for proper first-time setup, `org-appear--set-elements'
  ;; needs to be run after other hooks have acted.
  (run-at-time nil nil #'org-appear--set-elements))

(setq projectile-project-search-path '(("~/Code/" . 2)))

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(use-package! all-the-icons-nerd-fonts
  :after all-the-icons
  :config
  (all-the-icons-nerd-fonts-prefer))

(map! :leader
      :desc "Increase font size"
      "+" #'text-scale-adjust)
(map! :leader
      :desc "Decrease font size"
      "-" #'text-scale-adjust)
(map! :leader
      :desc "Reset font size"
      "0" #'text-scale-adjust)

(map! (:map +tree-sitter-outer-text-objects-map
	    "f" (evil-textobj-tree-sitter-get-textobj "call.inner")
	    "F" (evil-textobj-tree-sitter-get-textobj "function.inner"))
      (:map +tree-sitter-inner-text-objects-map
	    "f" (evil-textobj-tree-sitter-get-textobj "call.inner")
	    "F" (evil-textobj-tree-sitter-get-textobj "function.inner")))

;; Tabs > spaces
(setq-default indent-tabs-mode t)

;; An evil mode indicator is redundant with cursor shape
(advice-add #'doom-modeline-segment--modals :override #'ignore)

;; Disable "package-cl is deprecated" warning
;; https://discourse.doomemacs.org/t/warning-at-startup-package-cl-is-deprecated/60/5
(defadvice! fixed-do-after-load-evaluation (abs-file)
  :override #'do-after-load-evaluation
  (dolist (a-l-element after-load-alist)
    (when (and (stringp (car a-l-element))
	       (string-match-p (car a-l-element) abs-file))
      (mapc #'funcall (cdr a-l-element))))
  (run-hook-with-args 'after-load-functions abs-file))

;; Enable some more Evil keybindings for org-mode
(after! evil-org
  (evil-org-set-key-theme '(navigation
			    return
			    insert
			    textobjects
			    additional
			    calendar
			    shift
			    ;; heading
			    todo)))

(use-package! org-super-agenda
  :after org-agenda
  :init
  (require 'evil-org-agenda)
  (setq org-super-agenda-groups '((:name "Today"
				   :time-grid t
				   :scheduled today)
				  (:name "Due today"
				   :deadline today)
				  (:name "Important"
				   :priority "A")
				  (:name "Overdue"
				   :deadline past)
				  (:name "Due soon"
				   :deadline future)))
  :config
  ;; https://github.com/alphapapa/org-super-agenda/issues/50#issuecomment-817432643
  (setq org-super-agenda-header-map evil-org-agenda-mode-map)
  (org-super-agenda-mode))

(add-to-list 'auto-mode-alist '("\\.mermaid\\'" . mermaid-mode))
(setq mermaid-output-format ".svg")

;; Don't auto-resolve clocks, because all our org-roam files are also
;; agenda files, auto-resolution takes forever as org has to open each
;; of them.
(setq org-clock-auto-clock-resolution nil)

;; Invalidate Projectile cache when using Magit to check out different commits
;; https://emacs.stackexchange.com/a/26272
(defun run-projectile-invalidate-cache (&rest _args)
  ;; We ignore the args to `magit-checkout'.
  (projectile-invalidate-cache nil))
(advice-add 'magit-checkout
	    :after #'run-projectile-invalidate-cache)
(advice-add 'magit-branch-and-checkout ; This is `b c'.
	    :after #'run-projectile-invalidate-cache)

(use-package! spell-fu
  :config
  (setq ispell-personal-dictionary "@DOOMLOCALDIR@/etc/spell-fu/.pws")
  ;; https://github.com/doomemacs/doomemacs/issues/4483#issuecomment-910698739
  (ispell-check-version))

;; Don't use language servers to auto-format
(setq +format-with-lsp nil)

;; LSP perf tweaks
;; https://emacs-lsp.github.io/lsp-mode/page/performance/
(setq read-process-output-max (* 1024 1024 3)) ;; 3mb
(setq lsp-idle-delay 0.500)
(setq gc-cons-threshold 100000000) ;; 100mb

(setq lsp-eslint-server-command '("@nodejs@/bin/node"
				  "@vscode-eslint@/share/vscode/extensions/dbaeumer.vscode-eslint/server/out/eslintServer.js"
				  "--stdio"))

(after! lsp-mode
  (setq lsp-enable-suggest-server-download nil
	lsp-clients-typescript-prefer-use-project-ts-server t)
  (defun lsp-booster--advice-json-parse (old-fn &rest args)
    "Try to parse bytecode instead of json."
    (or
     (when (equal (following-char) ?#)
       (let ((bytecode (read (current-buffer))))
	 (when (byte-code-function-p bytecode)
	   (funcall bytecode))))
     (apply old-fn args)))
  (advice-add (if (progn (require 'json)
			 (fboundp 'json-parse-buffer))
		  'json-parse-buffer
		'json-read)
	      :around
	      #'lsp-booster--advice-json-parse)
  (defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
    "Prepend emacs-lsp-booster command to lsp CMD."
    (let ((orig-result (funcall old-fn cmd test?)))
      (if (and (not test?)                             ;; for check lsp-server-present?
	       (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
	       lsp-use-plists
	       (not (functionp 'json-rpc-connection))  ;; native json-rpc
	       (executable-find "emacs-lsp-booster"))
	  (progn
	    (when-let ((command-from-exec-path (executable-find (car orig-result))))  ;; resolve command from exec-path (in case not found in $PATH)
	      (setcar orig-result command-from-exec-path))
	    (message "Using emacs-lsp-booster for %s!" orig-result)
	    (cons "emacs-lsp-booster" orig-result))
	orig-result)))
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command))

(add-hook! 'typescript-tsx-mode-hook
  (setq comment-start "//"
	comment-end ""))

;; Debug Adapter Protocol
(use-package! dap-mode
  :init
  (setq ;; dap-auto-configure-features '(sessions locals breakpoints expressions tooltip)
   dap-firefox-debug-path "@vscode-firefox-debug@/share/vscode/extensions/firefox-devtools.vscode-firefox-debug"
   dap-firefox-debug-program `("@nodejs@/bin/node" ,(concat dap-firefox-debug-path "/dist/adapter.bundle.js"))
   dap-js-path "@vscode-js-debug@/bin"
   dap-js-debug-program (list (concat dap-js-path "/js-debug"))))

(setq fancy-splash-image "@doom-png@")
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)
(add-to-list 'default-frame-alist '(alpha-background . 95))

;; Emacs everywhere
(after! emacs-everywhere
  (setq emacs-everywhere-frame-name-format "emacs-everywhere")

  ;; The modeline is not useful to me in the popup window. It looks much nicer
  ;; to hide it.
  (remove-hook 'emacs-everywhere-init-hooks #'hide-mode-line-mode)

  ;; Semi-center it over the target window, rather than at the cursor position
  ;; (which could be anywhere).
  (defadvice! center-emacs-everywhere-in-origin-window (frame window-info)
    :override #'emacs-everywhere-set-frame-position
    (cl-destructuring-bind (x y width height)
	(emacs-everywhere-window-geometry window-info)
      (set-frame-position frame
			  (+ x (/ width 2) (- (/ width 2)))
			  (+ y (/ height 2))))))
(atomic-chrome-start-server)

;; Use Tree Sitter wherever we can
(setq +tree-sitter-hl-enabled-modes t)

(setq company-minimum-prefix-length 2)
(setq company-idle-delay
      (lambda () (if (company-in-string-or-comment) nil 0.3)))
(setq company-selection-wrap-around t)

(setq dash-docs-docsets-path "@XDG_DATA_HOME@/docsets")
(set-docsets! 'js2-mode "JavaScript" "NodeJS")
(set-docsets! 'rjsx-mode "JavaScript" "React")
(set-docsets! 'typescript-mode "JavaScript" "NodeJS")
(set-docsets! 'typescript-tsx-mode "JavaScript" "React")

(setq Man-notify-method 'pushy)

(setq ispell-dictionary "en_GB")

(use-package! langtool
  :config
  (setq langtool-java-user-arguments '("-Dfile.encoding=UTF-8")
	langtool-http-server-host "localhost"
	langtool-http-server-port 8081
	langtool-mother-tongue "en"
	langtool-default-language "en-GB"))

(use-package! langtool-popup
  :after langtool)

(use-package! evil-little-word
  :after evil)

(use-package! envrc
  :config
  (setq envrc-show-summary-in-minibuffer nil))

(use-package! ledger-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.\\(h?ledger\\|journal\\|j\\)$" . ledger-mode))
  :config
  (setq ledger-binary-path (executable-find "hledger")
	ledger-mode-should-check-version nil
	ledger-report-links-in-register nil
	ledger-report-auto-width nil
	ledger-report-use-header-line t
	ledger-report-native-highlighting-arguments '("--color=always")
	ledger-report-use-native-highlighting t
	ledger-report-auto-refresh-sticky-cursor t
	ledger-report-use-strict t
	ledger-init-file-name " "
	ledger-post-amount-alignment-column 64
	ledger-reconcile-default-commodity "ZAR"
	ledger-highlight-xact-under-point nil)
  (add-hook 'ledger-mode-hook #'auto-revert-tail-mode)
  (add-hook 'ledger-mode-hook #'orgstruct-mode))

(use-package! flycheck-hledger
  :after (flycheck ledger-mode)
  :demand t
  :config
  (setq flycheck-hledger-strict t))

;; Prevent auto scrolling
;; https://github.com/akermu/emacs-libvterm/issues/397
(advice-add 'set-window-vscroll :after
	    (defun me/vterm-toggle-scroll (&rest _)
	      (when (eq major-mode 'vterm-mode)
		(if (> (window-end) (buffer-size))
		    (when vterm-copy-mode (vterm-copy-mode-done nil))
		  (vterm-copy-mode 1)))))

(use-package! evil
  :config
  (setq evil-esc-delay 0))

(use-package! evil-escape
  :config
  (setq evil-escape-delay 0))
