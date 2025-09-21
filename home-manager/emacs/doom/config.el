;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Xandor Schiefer"
      user-mail-address "me@xandor.co.za")

(setq doom-font (font-spec :family "Iosevka Nerd Font" :size 12 :weight 'light)
      doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 12 :weight 'light)
      doom-big-font (font-spec :family "Iosevka Nerd Font" :size 18 :weight 'light)
      doom-symbol-font (font-spec :family "Symbols Nerd Font" :size 12)
      doom-emoji-font (font-spec :family "Twitter Color Emoji" :size 12)
      doom-serif-font (font-spec :family "Iosevka Nerd Font" :size 12 :weight 'light)
      nerd-icons-font-family "Iosevka NF Light")

(setq doom-theme 'doom-nord)

;; Tabs > spaces
(setq-default indent-tabs-mode t)

(setq-default display-line-numbers-type 'relative
	      display-line-numbers-widen t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "@XDG_DOCUMENTS_DIR@/notes/"
      org-roam-directory org-directory
      org-roam-dailies-directory "journal/")

;; Fish shell compat
(setq shell-file-name (executable-find "bash"))
(setq-default vterm-shell (executable-find "fish"))
(setq-default explicit-shell-file-name (executable-find "fish"))

(setq Man-notify-method 'pushy)

(setq fancy-splash-image "@doom-png@")
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)
(add-to-list 'default-frame-alist '(alpha-background . 95))

(setq projectile-project-search-path '(("~/Code/" . 2)))

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

(map! :leader
      :desc "Increase font size"
      "+" #'text-scale-adjust)
(map! :leader
      :desc "Decrease font size"
      "-" #'text-scale-adjust)
(map! :leader
      :desc "Reset font size"
      "0" #'text-scale-adjust)

;;
;; evil-mode
;;

(defun me/relative-line-numbers ()
  "Show relative line numbers."
  (unless (equal display-line-numbers nil)
    (setq-local display-line-numbers 'relative)))

(defun me/absolute-line-numbers ()
  "Show absolute line numbers."
  (unless (equal display-line-numbers nil)
    (setq-local display-line-numbers t)))

(after! evil
  (setq evil-esc-delay 0)
  (add-hook! 'evil-insert-state-entry-hook #'me/absolute-line-numbers)
  (add-hook! 'evil-insert-state-exit-hook #'me/relative-line-numbers))

;;
;; org-mode
;;

;; Boris Buliga - Task management with org-roam Vol. 5: Dynamic and fast agenda
;; https://d12frosted.io/posts/2021-01-16-task-management-with-roam-vol5.html
(use-package! vulpea
  :demand t
  :hook ((org-roam-db-autosync-mode . vulpea-db-autosync-enable)))

(defun me/vulpea-project-p ()
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

(defun me/vulpea-buffer-p ()
  "Return non-nil if the currently visited buffer is a note."
  (and buffer-file-name
       (string-prefix-p
	(expand-file-name (file-name-as-directory org-roam-directory))
	(file-name-directory buffer-file-name))))

(defun me/vulpea-project-update-tag ()
  "Update PROJECT tag in the current buffer."
  (when (and (not (active-minibuffer-window))
	     (me/vulpea-buffer-p))
    (save-excursion
      (goto-char (point-min))
      (let* ((tags (vulpea-buffer-tags-get))
	     (original-tags tags))
	(if (me/vulpea-project-p)
	    (setq tags (cons "project" tags))
	  (setq tags (remove "project" tags)))

	;; cleanup duplicates
	(setq tags (seq-uniq tags))

	;; update tags if changed
	(when (or (seq-difference tags original-tags)
		  (seq-difference original-tags tags))
	  (apply #'vulpea-buffer-tags-set tags))))))

(defun me/vulpea-project-files ()
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

(defun me/vulpea-agenda-files-update (&rest _)
  "Update the value of `org-agenda-files'."
  (setq org-agenda-files (me/vulpea-project-files)))

(add-hook! 'find-file-hook #'me/vulpea-project-update-tag)
(add-hook! 'before-save-hook #'me/vulpea-project-update-tag)

(after! org-agenda
  (advice-add 'org-agenda :before #'me/vulpea-agenda-files-update))

(after! org
  (advice-add 'org-todo-list :before #'me/vulpea-agenda-files-update)
  ;; Don't auto-resolve clocks, because all our org-roam files are also
  ;; agenda files, auto-resolution takes forever as org has to open each
  ;; of them.
  (setq org-clock-auto-clock-resolution nil)
  (setq org-return-follows-link t)
  (setq org-todo-keywords '((sequence
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
		             "NO(n)")))

  (setq org-todo-keyword-faces
        '(("NEXT" . +org-todo-next)
          ("[?]"  . +org-todo-wait)
          ("WAIT" . +org-todo-wait)
          ("HOLD" . +org-todo-hold)
          ("IDEA" . +org-todo-hold)
          ("NO"   . +org-todo-kill)
          ("KILL" . +org-todo-kill)))

  (setq org-auto-align-tags nil)
  (setq org-tags-column 0)
  (setq org-fold-catch-invisible-edits 'show-and-error)
  (setq org-special-ctrl-a/e t)
  (setq org-insert-heading-respect-content t)

  (setq org-hide-emphasis-markers t)
  (setq org-pretty-entities t)
  (setq org-ellipsis "…"))

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

;; An evil mode indicator is redundant with cursor shape
(after! doom-modeline
  (advice-add #'doom-modeline-segment--modals :override #'ignore))

(use-package! with-editor
  :demand t
  :hook ((shell-mode . with-editor-export-editor)
	 (eshell-mode . with-editor-export-editor)
	 (term-exec . with-editor-export-editor)
	 (vterm-mode . with-editor-export-editor))
  :config (shell-command-with-editor-mode))

(use-package! all-the-icons-nerd-fonts
  :after all-the-icons
  :config
  (all-the-icons-nerd-fonts-prefer))

;; Invalidate Projectile cache when using Magit to check out different commits
;; https://emacs.stackexchange.com/a/26272
(defun me/run-projectile-invalidate-cache (&rest _args)
  ;; We ignore the args to `magit-checkout'.
  (projectile-invalidate-cache nil))

(after! magit
  (advice-add 'magit-checkout
              :after #'me/run-projectile-invalidate-cache)
  (advice-add 'magit-branch-and-checkout ; This is `b c'.
              :after #'me/run-projectile-invalidate-cache))


(after! spell-fu
  (setq ispell-dictionary "en_GB")
  (setq ispell-personal-dictionary "@DOOMLOCALDIR@/etc/spell-fu/.pws")
  ;; https://github.com/doomemacs/doomemacs/issues/4483#issuecomment-910698739
  (ispell-check-version))

;;
;; lsp-mode
;;

(defun me/lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
	 (funcall bytecode))))
   (apply old-fn args)))

(defun me/lsp-booster--advice-final-command (old-fn cmd &optional test?)
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

(defun me/lsp--gitignore-to-regexp (fn workspace-root)
  (let* ((ignored-things (funcall fn workspace-root))
	 (ignored-files-regex-list (car ignored-things))
	 (ignored-directories-regex-list (cadr ignored-things))
	 (cmd (format "cd '%s'; git clean --dry-run -Xd | cut -d' ' -f3" workspace-root))
	 (gitignored-things (split-string (shell-command-to-string cmd) "\n" t))
	 (gitignored-files (seq-remove (lambda (line) (string-match-p "[/\\\\]\\'" line)) gitignored-things))
	 (gitignored-directories (seq-filter (lambda (line) (string-match-p "[/\\\\]\\'" line)) gitignored-things))
	 (gitignored-files-regex-list
	  (mapcar (lambda (file) (concat "[/\\\\]" (regexp-quote file) "\\'"))
		  gitignored-files))
	 (gitignored-directories-regex-list
	  (mapcar (lambda (directory)
		    (concat "[/\\\\]"
			    (regexp-quote (replace-regexp-in-string "[/\\\\]\\'" "" directory))
			    "\\'"))
		  gitignored-directories)))
    (list
     (append ignored-files-regex-list gitignored-files-regex-list)
     (append ignored-directories-regex-list gitignored-directories-regex-list))))

(after! lsp-mode
  ;; LSP perf tweaks
  ;; https://emacs-lsp.github.io/lsp-mode/page/performance/
  (setq read-process-output-max (* 1024 1024 3)) ;; 3mb
  (setq lsp-idle-delay 0.500)
  (setq gc-cons-threshold 100000000) ;; 100mb

  (setq lsp-eslint-server-command '("@nodejs@/bin/node"
                                    "@vscode-eslint@/share/vscode/extensions/dbaeumer.vscode-eslint/server/out/eslintServer.js"
                                    "--stdio"))
  (setq lsp-enable-suggest-server-download nil
	lsp-clients-typescript-prefer-use-project-ts-server t
	+format-with-lsp nil)

  (advice-add (if (progn (require 'json)
			 (fboundp 'json-parse-buffer))
		  'json-parse-buffer
		'json-read)
	      :around
	      #'me/lsp-booster--advice-json-parse)

  (advice-add 'lsp-resolve-final-command :around #'me/lsp-booster--advice-final-command)

  ;; https://github.com/emacs-lsp/lsp-mode/issues/713#issuecomment-985653873
  (advice-add 'lsp--get-ignored-regexes-for-workspace-root :around #'me/lsp--gitignore-to-regexp)

  ;; https://emacs-lsp.github.io/lsp-mode/page/faq/#how-do-i-force-lsp-mode-to-forget-the-workspace-folders-for-multi-root-servers-so-the-workspace-folders-are-added-on-demand
  (advice-add 'lsp :before (lambda (&rest _args) (eval '(setf (lsp-session-server-id->folders (lsp-session)) (ht))))))

;; Debug Adapter Protocol
(after! dap-mode
  (setq
   ;; dap-auto-configure-features '(sessions locals breakpoints expressions tooltip)
   dap-firefox-debug-path "@vscode-firefox-debug@/share/vscode/extensions/firefox-devtools.vscode-firefox-debug"
   dap-firefox-debug-program `("@nodejs@/bin/node" ,(concat dap-firefox-debug-path "/dist/adapter.bundle.js"))
   dap-js-path "@vscode-js-debug@/bin"
   dap-js-debug-program (list (concat dap-js-path "/js-debug"))))

;; Use Tree Sitter wherever we can
(setq +tree-sitter-hl-enabled-modes t)

(after! company
  (setq company-minimum-prefix-length 2)
  (setq company-idle-delay
        (lambda () (if (company-in-string-or-comment) nil 0.3)))
  (setq company-selection-wrap-around t))

(after! dash-docs
  (setq dash-docs-docsets-path "@XDG_DATA_HOME@/docsets"))

(set-docsets! js2-mode "JavaScript" "NodeJS")
(set-docsets! rjsx-mode "JavaScript" "React")
(set-docsets! typescript-mode "JavaScript" "NodeJS")
(set-docsets! typescript-tsx-mode "JavaScript" "React")

(use-package! langtool
  :config
  (setq langtool-java-user-arguments '("-Dfile.encoding=UTF-8")
	langtool-http-server-host "localhost"
	langtool-http-server-port 8081
	langtool-mother-tongue "en"
	langtool-default-language "en-GB"))

(use-package! langtool-popup
  :after langtool)

(use-package! envrc
  :config
  (setq envrc-show-summary-in-minibuffer nil))

(after! ledger-mode
  (add-to-list 'auto-mode-alist '("\\.\\(h?ledger\\|journal\\|j\\)$" . ledger-mode))
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
  (add-hook! ledger-mode-hook auto-revert-tail-mode)
  (add-hook! ledger-mode-hook orgstruct-mode))

(use-package! flycheck-hledger
  :after (flycheck ledger-mode)
  :config
  (setq flycheck-hledger-strict t))

(defun me/vterm-toggle-scroll (&rest _)
  (when (eq major-mode 'vterm-mode)
    (if (> (window-end) (buffer-size))
        (when vterm-copy-mode (vterm-copy-mode-done nil))
      (vterm-copy-mode 1))))

;; Prevent auto scrolling
;; https://github.com/akermu/emacs-libvterm/issues/397
(after! vterm
  (advice-add 'set-window-vscroll :after #'me/vterm-toggle-scroll))

(after! latex
  (setq +latex-viewers '(zathura)))
