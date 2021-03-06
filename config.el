(defun nm/return-entry-property-names ()
  "Returns a list of property names excluding the DEFAULT org-mode property names."
  (let ((my-list (org-entry-properties))
        (temp-list nil)
        (discard-list '("ITEM" "PRIORITY" "FILE" "BLOCKED")))
    (dolist (i my-list) (push (car i) temp-list))
    (dolist (i discard-list) (setq temp-list (remove i temp-list)))
    temp-list))
(nm/return-entry-property-names)

(defun nm/return-entry-property-value-kill-ring ()
  "Returns a list of properties for the current headline and inserts the contents to the kill ring."
  (interactive)
  (let* ((choice (ivy-completing-read "entry: " (nm/return-entry-property-names)))
        (results (org-entry-get nil choice)))
    (kill-new results)
    (message (format "'%s' was copied to kill-ring" results))))

(map! :after org
      :map org-mode-map
      :leader
      :prefix ("z" . "nicks functions")
      :desc "Copy property value to kill-ring" "x" #'nm/return-entry-property-value-kill-ring)

(defun nm/return-entry-property-names ()
  "Returns a list of property names excluding the DEFAULT org-mode property names."
  (let ((my-list (org-entry-properties))
        (temp-list nil)
        (discard-list '("ITEM" "PRIORITY" "FILE" "BLOCKED")))
    (dolist (i my-list) (push (car i) temp-list))
    (dolist (i discard-list) (setq temp-list (remove i temp-list)))
    temp-list))
(nm/return-entry-property-names)

(defun nm/return-entry-property-value-kill-ring ()
  "Returns a list of properties for the current headline and inserts the contents to the kill ring."
  (interactive)
  (let ((choice (ivy-completing-read "entry: " (nm/return-entry-property-names))))
    (kill-new (org-entry-get nil choice))))

(defun nm/org-clarify-properties ()
  "Clarify properties for task."
  (interactive)
  (let ((my-list nm/org-clarify-templates)
        (my-temp nil))
    (dolist (i my-list) (push (car i) my-temp))
    (dolist (i (cdr (assoc (ivy-completing-read "template: " my-temp) nm/org-clarify-templates))) (org-entry-put nil i (ivy-completing-read (format "%s: " i) (delete-dups (org-map-entries (org-entry-get nil i nil) nil 'file)))))))

(setq nm/org-clarify-templates '(("book" "AUTHOR" "YEAR" "SOURCE")
                                 ("online" "SOURCE" "SITE" "AUTHOR")
                                 ("purchase" "WHY" "FUNCTION")
                                 ("task" "AREA")
                                 ("project" "GOAL" "DUE")
                                 ("article" "SOURCE" "SITE" "SUBJECT")))

(map! :after org
      :map org-mode-map
      :leader
      :prefix ("z" . "nicks functions")
      :desc "Clarify Properties" "c" #'nm/org-clarify-properties)

(unless (ivy-completing-read "select: " '("Something"))
  (error "no output"))

(defun nm/capture-bullet-journal ()
  "Finds bullet journal headline to nest capture headline under."
  (let* ((date (format-time-string "%Y-%m-%d %a")))
    (goto-char (point-min))
    (unless (re-search-forward (format "^*+\s%s" date) nil t)
      (goto-char (point-max))
      (insert (format "* %s %s" date "[/]")))))

(defun nm/skip-non-stuck-projects ()
  "Skip trees that are not stuck projects."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (outline-next-heading))))
      (if (bh/is-project-p)
          (let* ((subtree-end (org-end-of-subtree t))
                 (has-next))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next) (< (point) subtree-end) (and (not (bh/is-project-p)) (nm/has-next-condition)))
                (unless (member (or "WAITING" "SOMEDAY") (org-get-tags-at))
                  (setq has-next t))))
            (if has-next
                next-headline
              nil))
        next-headline))))

(defun nm/project-tasks-ready ()
  "Skip trees that are not projects"
      (let ((next-headline (save-excursion (outline-next-heading)))
            (subtree-end (org-end-of-subtree t)))
        (if (nm/skip-non-stuck-projects)
            (cond
             ((and (bh/is-project-subtree-p) (nm/has-next-condition)) nil)
             (t subtree-end))
          subtree-end)))

(defun nm/has-next-condition ()
  "Returns t if headline has next condition state"
  (save-excursion
    (cond
     ((nm/is-scheduled-p) t)
     ((nm/exist-context-tag-p) t)
     ((nm/checkbox-active-exist-p) t))))

(defun nm/standard-tasks-ready ()
  "Show non-project tasks. Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
           (next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((bh/is-project-p) next-headline)
       ((bh/is-project-subtree-p) next-headline)
       ((and (bh/is-task-p) (not (nm/has-next-condition))) subtree-end)
       (t nil)))))

(defun nm/stuck-projects ()
  "Returns t when a project has no defined next actions for any of its subtasks."
  (let ((next-headline (save-excursion (outline-next-heading)))
        (subtree-end (org-end-of-subtree t)))
    (if (or (bh/is-project-p) (bh/is-project-subtree-p))
        (cond
         ((and (bh/is-project-subtree-p) (not (nm/has-next-condition))) nil))
      subtree-end)))

(defun nm/tasks-refile ()
  "Returns t if the task is not part of a project and has no next state conditions."
  (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
         (next-heading (save-excursion (outline-next-heading))))
    (cond
     ((nm/has-next-condition) next-heading)
     ((bh/is-project-p) subtree-end))))

(defun nm/capture-project-timeframes ()
  "Captures under the given projects timeframe headline."
  (let ((p-name (ivy-completing-read "Select file: " (find-lisp-find-files "~/projects/orgmode/gtd/" "\.org$")))
        (h-name "* Timeframe")
        (c-name (read-string "Entry name: ")))
    (goto-char (point-min))
    (find-file p-name)
    (unless (re-search-forward h-name nil t)
      (progn (goto-char (point-max)) (newline) (insert "* Timeframe")))
    (org-end-of-subtree t)
    (newline 2)
    (insert (format "** %s %s" (format-time-string "[%Y-%m-%d %a %H:%M]") c-name))
    (newline)))

(setq doom-dark-themes '("doom-one" "doom-solarized-dark" "doom-palenight" "doom-rouge" "doom-spacegrey" "doom-dracula" "doom-vibrant" "doom-city-lights" "doom-moonlight" "doom-horizon" "doom-old-hope" "doom-oceanic-next" "doom-monokai-pro" "doom-material" "doom-henna" "doom-gruvbox" "doom-ephemeral" "chocolate"))

(setq doom-light-themes '("doom-one-light" "doom-gruvbox-light" "doom-solarized-light" "doom-flatwhite"))

(defun nm/load-dark-theme ()
  (interactive)
  (let* ((themes doom-dark-themes)
         (first (car doom-dark-themes)))
    (counsel-load-theme-action (car themes))
    (setq doom-theme (car themes))
    (pop doom-dark-themes)
    (add-to-list 'doom-dark-themes first t)))

(defun nm/load-light-theme ()
  (interactive)
  (let* ((themes doom-light-themes)
         (first (car doom-light-themes)))
    (counsel-load-theme-action (car themes))
    (setq doom-theme (car themes))
    (pop doom-light-themes)
    (add-to-list 'doom-light-themes first t)))

;; This function was found on a stackoverflow post -> https://stackoverflow.com/questions/6681407/org-mode-capture-with-sexp
 (defun get-page-title (url)
  "Get title of web page, whose url can be found in the current line"
  ;; Get title of web page, with the help of functions in url.el
  (with-current-buffer (url-retrieve-synchronously url)
    ;; find title by grep the html code
    (goto-char 0)
    (re-search-forward "<title>\\([^<]*\\)</title>" nil t 1)
    (setq web_title_str (match-string 1))
    ;; find charset by grep the html code
    (goto-char 0)

    ;; find the charset, assume utf-8 otherwise
    (if (re-search-forward "charset=\\([-0-9a-zA-Z]*\\)" nil t 1)
        (setq coding_charset (downcase (match-string 1)))
      (setq coding_charset "utf-8")
    ;; decode the string of title.
    (setq web_title_str (decode-coding-string web_title_str (intern
                                                             coding_charset))))
  (concat "[[" url "][" web_title_str "]]")))

(require 'find-lisp)
(defun nm/org-id-prompt-id ()
  "Prompt for the id during completion of id: link."
  (let* ((org-agenda-files (find-lisp-find-files org-directory "\.org$"))
         (dest (org-refile-get-location))
         (name nil)
         (id nil))
    (if (equal (last dest) '(nil))
        (error "File contains no headlines")
      (save-excursion
        (find-file (cadr dest))
        (goto-char (nth 3 dest))
        (setq id (org-id-get (point) t)
              name (org-get-heading t t t t)))
      (org-insert-link nil (concat "id:" id) name))))

(after! org (org-link-set-parameters "id" :complete #'nm/org-id-prompt-id))

(defun nm/org-end-of-headline()
  "Move to end of current headline"
  (interactive)
  (outline-next-heading)
  (forward-char -1))

(defun nm/org-capture-to-task-file ()
  "Capture file to your default tasks file, and prompts to select a date where to file the task file to."
  (let* ((child-l nil)
         (parent "Checklists")
         (date (org-read-date))
         (heading (format "Items for")))
    (goto-char (point-min))
    ;;; Locate or Create our parent headline
    (unless (search-forward (format "* %s" parent) nil t)
      (goto-char (point-max))
      (newline)
      (insert (format "* %s" parent))
      (nm/org-end-of-headline))
    (nm/org-end-of-headline)
    ;;; Capture outline level
    (setq child-l (format "%s" (make-string (+ 1 (org-outline-level)) ?*)))
    ;;; Next we locate or create our subheading using the date string passed by the user.
    (let* ((end (save-excursion (org-end-of-subtree t nil))))
      (unless (re-search-forward (format "%s %s %s" child-l heading date) end t)
        (newline 2)
        (insert (format "%s %s %s %s" child-l heading date "[/]"))))))

(defun nm/add-newline-between-headlines ()
  ""
  (when (equal major-mode 'org-mode)
    (unless (org-at-heading-p)
      (org-back-to-heading))
    (nm/org-end-of-headline)
    (if (not (org--line-empty-p 1))
        (newline))))

(defun nm/add-space-end-of-line ()
  "If N-1 at end of heading is #+end_src then insert blank character on last line."
  (interactive)
  (when (equal major-mode 'org-mode)
    (unless (org-at-heading-p)
      (org-back-to-heading))
    (nm/org-end-of-headline)
    (next-line -1)
    (if (org-looking-at-p "^#\\+end_src$")
        (progn (next-line 1) (insert " ")))))

(defun nm/newlines-between-headlines ()
  "Uses the org-map-entries function to scan through a buffer's
   contents and ensure newlines are inserted between headlines"
  (interactive)
  (org-map-entries #'nm/add-newline-between-headlines t 'file))

(add-hook 'org-insert-heading-hook #'nm/newlines-between-headlines)

(defun nm/capture-to-journal ()
  "When org-capture-template is initiated, it creates the respected headline structure."
  (let ((file "~/projects/orgmode/gtd/journal.org")
        (parent nil)
        (child nil))
    (unless (file-exists-p file)
      (with-temp-buffer (write-file file)))
    (find-file file)
    (goto-char (point-min))
    ;; Search for headline, or else create it.
    (unless (re-search-forward "* Journal" nil t)
      (progn (goto-char (point-max)) (newline) (insert "* Journal")))
    (unless (re-search-forward (format "** %s" (format-time-string "%b '%y")) (save-excursion (org-end-of-subtree)) t)
      (progn (org-end-of-subtree t) (newline) (insert (format "** %s" (format-time-string "%b '%y")))))))

(defun nm/setup-productive-windows (arg1 arg2)
  "Delete all other windows, and setup our ORGMODE production window layout."
  (interactive)
  (progn
    (delete-other-windows)
    (progn
      (find-file arg1))
    (progn
      (split-window-right)
      (evil-window-right 1)
      (org-agenda nil "n"))
    (progn
      (split-window)
      (evil-window-down 1)
      (find-file arg2)
      (goto-char 1)
      (re-search-forward (format "*+\s\\w+\sTasks\sfor\s%s" (format-time-string "%Y-%m-%d")))
      (org-tree-to-indirect-buffer))))

(defun nm/productive-window ()
  "Setup"
  (interactive)
  (nm/setup-productive-windows "~/projects/orgmode/gtd/next.org" "~/projects/orgmode/gtd/tasks.org"))

(map! :after org
      :map org-mode-map
      :leader
      :prefix ("TAB" . "workspace")
      :desc "Load ORGMODE Setup" "," #'nm/productive-window)

(defun nm/get-headlines-org-files (arg &optional indirect)
  "Searches org-directory for headline and returns results to indirect buffer
   ARG being a directory to search and optional INDIRECT should return t if you
   want results returned to an indirect buffer."
  (interactive)
  (let* ((org-agenda-files (find-lisp-find-files arg "\.org$"))
         (org-refile-use-outline-path 'file)
         (org-refile-history nil)
         (dest (org-refile-get-location))
         (buffer nil)
         (first (frame-first-window)))
    (save-excursion
      (if (eq first (next-window first))
          (progn (evil-window-vsplit) (evil-window-right 1))
        (other-window 1))
      (find-file (cadr dest))
      (goto-char (nth 3 dest))
      (if indirect
          (org-tree-to-indirect-buffer)
        nil))))

(defun nm/search-headlines-org-directory ()
  "Search the ORG-DIRECTORY, prompting user for headline and returns its results to indirect buffer."
  (interactive)
  (nm/get-headlines-org-files "~/projects/orgmode/"))

(defun nm/search-headlines-org-tasks-directory ()
  "Search the GTD folder, prompting user for headline and returns its results to indirect buffer."
  (interactive)
  (nm/get-headlines-org-files "~/projects/orgmode/gtd/"))

(map! :after org
      :map org-mode-map
      :leader
      :prefix ("s" . "search")
      :desc "Outline Org-Directory" "c" #'nm/search-headlines-org-directory
      :desc "Outline GTD directory" "!" #'nm/search-headlines-org-tasks-directory)

(setq user-full-name "Nick Martin"
      user-mail-address "nmartin84@gmail.com")

(display-time-mode 1)
(setq display-time-day-and-date t)

(global-auto-revert-mode 1)
(setq undo-limit 80000000
      evil-want-fine-undo t
      auto-save-default nil
      inhibit-compacting-font-caches t)
(whitespace-mode -1)

(setq-default
 delete-by-moving-to-trash t
 tab-width 4
 uniquify-buffer-name-style 'forward
 window-combination-resize t
 x-stretch-cursor nil)

(bind-key "<f6>" #'link-hint-copy-link)
(bind-key "<f12>" #'org-cycle-agenda-files)
(bind-key "M-." #'completion-at-point)

(map! :after org
      :map org-mode-map
      :leader
      :prefix ("z" . "nicks functions")
      :desc "completion at point" "c" #'completion-at-point
      :desc "Review Fleeting Notes" "r" #'nm/review-fleeting-notes
      :desc "Find File in ORGMODE" "f" #'nm/find-files-orgmode
      :desc" File project" "p" #'nm/find-projects
      :prefix ("s" . "+search")
      :desc "Occur" "." #'occur
      :desc "Outline" "o" #'counsel-outline
      :desc "Counsel ripgrep" "d" #'counsel-rg
      :desc "Swiper All" "@" #'swiper-all
      :prefix ("l" . "+links")
      "." #'org-next-link
      "," #'org-previous-link
      "o" #'org-open-at-point
      "g" #'eos/org-add-ids-to-headlines-in-file)

(map! :after org-agenda
      :map org-agenda-mode-map
      :localleader
      :desc "Filter" "f" #'org-agenda-filter)

(defun nm/review-fleeting-notes ()
  (interactive)
  (nm/find-file-cleaned-up "~/projects/orgmode/fleeting/"))

(defun nm/find-files-orgmode ()
  (interactive)
  (nm/find-file-cleaned-up org-directory))

(defun nm/find-projects ()
  (interactive)
  (nm/find-file-cleaned-up "~/projects/orgmode/gtd/projects/"))

(when (equal (window-system) nil)
  (and
   (bind-key "C-<down>" #'+org/insert-item-below)
   ;(setq doom-theme nil)
   (setq doom-font (font-spec :family "Roboto Mono" :size 20))))

(setq diary-file "~/projects/orgmode/diary.org")
(setq org-directory "~/projects/orgmode/")
(setq projectile-project-search-path "~/projects/")

(after! org (set-popup-rule! "^\\*lsp-help" :side 'bottom :size .30 :select t)
  (set-popup-rule! "*helm*" :side 'right :size .30 :select t)
  (set-popup-rule! "*Org QL View:*" :side 'right :size .25 :select t)
  (set-popup-rule! "*Org Note*" :side 'bottom :size .35 :select t)
  (set-popup-rule! "*Capture*" :side 'left :size .30 :select t)
  (set-popup-rule! "*Python:ob-ipython-py*" :side 'right :size .25 :select t)
  (set-popup-rule! "*eww*" :side 'right :size .30 :select t)
  (set-popup-rule! "*CAPTURE-*" :side 'left :size .30 :select t))
                                        ;(set-popup-rule! "*Org Agenda*" :side 'right :size .35 :select t))

(setq inhibit-compacting-font-caches t)
(setq doom-font (font-spec :family "IBM Plex Mono" :size 24 :weight 'light)
      doom-big-font (font-spec :family "IBM Plex Mono" :size 26 :weight 'light)
      doom-variable-pitch-font (font-spec :family "IBM Plex Mono" :weight 'regular :size 20)
      doom-serif-font (font-spec :family "IBM Plex Mono" :weight 'light))

(when (equal window-system 'x) (toggle-frame-fullscreen))

(after! org
  (custom-set-faces!
    '(org-level-1 :height 1.15 :inherit outline-1)
    '(org-level-2 :height 1.13 :inherit outline-2)
    '(org-level-3 :height 1.11 :inherit outline-3)
    '(org-level-4 :height 1.09 :inherit outline-4)
    '(org-level-5 :height 1.07 :inherit outline-5)
    '(org-level-6 :height 1.05 :inherit outline-6)
    '(org-level-7 :height 1.03 :inherit outline-7)
    '(org-level-8 :height 1.01 :inherit outline-8)))

(after! org
  (custom-set-faces!
    '(org-document-title :height 1.15)))

;; (when (equal system-type 'gnu/linux)
;;   (setq doom-font (font-spec :family "JetBrains Mono" :size 20 :weight 'normal)
;;         doom-big-font (font-spec :family "JetBrains Mono" :size 22 :weight 'normal)))
;; (when (equal system-type 'windows-nt)
;;   (setq doom-font (font-spec :family "InputMono" :size 18)
;;         doom-big-font (font-spec :family "InputMono" :size 22)))

(require 'org-habit)
(require 'org-id)
(require 'org-checklist)
(after! org (setq org-archive-location "~/projects/orgmode/gtd/archives.org::* %s"
                  ;org-image-actual-width (truncate (* (display-pixel-width) 0.15))
                  org-link-file-path-type 'relative
                  org-log-state-notes-insert-after-drawers t
                  org-catch-invisible-edits 'error
                  org-refile-targets '((nil :maxlevel . 9)
                                       (org-agenda-files :maxlevel . 4))
                  org-refile-use-outline-path 'buffer-name
                  org-refile-use-cache nil
                  org-outline-path-complete-in-steps nil
                  org-refile-allow-creating-parent-nodes 'confirm
                  org-startup-indented 'indent
                  org-insert-heading-respect-content t
                  org-startup-folded 'content
                  org-src-tab-acts-natively t
                  org-list-allow-alphabetical nil))

(add-hook 'org-mode-hook 'auto-fill-mode)
;(add-hook 'org-mode-hook 'hl-todo-mode)
(add-hook 'org-mode-hook (lambda () (display-line-numbers-mode -1)))

(setq org-attach-directory (concat org-directory ".attach/"))

(setq org-agenda-todo-ignore-scheduled nil
      org-agenda-tags-todo-honor-ignore-options t
      org-agenda-fontify-priorities t)

(setq org-agenda-custom-commands nil)

(push '("o" "overview"
        ((agenda ""
                 ((org-agenda-span '1)
                  (org-agenda-overriding-header " Agenda")
                  (org-agenda-files (append (file-expand-wildcards "~/projects/orgmode/gtd/*.org")))
                  (org-agenda-start-day (org-today))))
         (tags-todo "-@delegated-someday/+NEXT"
                    ((org-agenda-overriding-header " Next Tasks")
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)
                     (org-tags-match-list-sublevels 'indented)
                     (org-agenda-sorting-strategy
                      '(category-up))))
         (tags-todo "-@delegated-someday/+DOING"
                    ((org-agenda-overriding-header " Doing")
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)
                     (org-tags-match-list-sublevels 'indented)
                     (org-agenda-sorting-strategy
                      '(category-up))))
         (tags-todo "@errands-someday/!-REFILE-NEXT-DOING"
                    ((org-agenda-overriding-header " Errands")
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)
                     (org-tags-match-list-sublevels 'indented)
                     (org-agenda-sorting-strategy
                      '(category-up))))
         (tags-todo "@home-someday/!-REFILE-NEXT-DOING"
                    ((org-agenda-overriding-header " Home")
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)
                     (org-tags-match-list-sublevels 'indented)
                     (org-agenda-sorting-strategy
                      '(category-up))))
         (tags-todo "@computer-someday/!-REFILE-NEXT-DOING"
                    ((org-agenda-overriding-header " Computer")
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)
                     (org-tags-match-list-sublevels 'indented)
                     (org-agenda-sorting-strategy
                      '(category-up))))
         (tags-todo "-{^@\\w+}-someday/-NEXT-REFILE-READ-DOING"
                    ((org-agenda-overriding-header " Other Tasks")
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)
                     (org-tags-match-list-sublevels 'indented)
                     (org-agenda-sorting-strategy
                      '(category-up))))
         (tags-todo "-someday/+REFILE"
                    ((org-agenda-overriding-header " Inbox"))))) org-agenda-custom-commands)

(push '("gh" "@home" tags-todo "@home/-REFILE") org-agenda-custom-commands)
(push '("ge" "@errands" tags-todo "@errands/-REFILE") org-agenda-custom-commands)
(push '("gc" "@computer" tags-todo "@computer/-REFILE") org-agenda-custom-commands)
(push '("gr" "@read" tags-todo "@read/-REFILE") org-agenda-custom-commands)
(push '("gd" "doing" todo "+DOING") org-agenda-custom-commands)
(push '("gn" "next" todo "+NEXT") org-agenda-custom-commands)
(push '("go" "other tasks" tags-todo "-{^@\\w+}-goals/-NEXT-REFILE-DOING" ((org-agenda-todo-ignore-with-date t))) org-agenda-custom-commands)
(push '("gg" "goals" tags-todo "goals/" ((org-agenda-todo-ignore-with-date t))) org-agenda-custom-commands)
(push '("gi" " inbox" todo "REFILE") org-agenda-custom-commands)

(push '("l" "literature"
        ((tags-todo "/!"
         ((org-agenda-todo-ignore-scheduled t)
          (org-agenda-todo-ignore-with-date t)
          (org-agenda-todo-ignore-deadlines t)
          (org-agenda-todo-ignore-with-date t)
          (org-agenda-files (append (find-lisp-find-files "~/projects/orgmode/literature/" "\.org$")))
          (org-tags-match-list-sublevels 'indented))))) org-agenda-custom-commands)

(push '("r" "review"
        ((tags-todo "-{^@\\w+}/-REFILE"
         ((org-agenda-todo-ignore-scheduled t)
          (org-agenda-todo-ignore-with-date t)
          (org-agenda-todo-ignore-deadlines t)
          (org-agenda-todo-ignore-with-date t))))) org-agenda-custom-commands)

(push '("b" "bullet"
        ((agenda ""
                 ((org-agenda-span '2)
                  (org-agenda-files (append (file-expand-wildcards "~/projects/orgmode/bullet/*.org")))
                  (org-agenda-start-day (org-today))))
         (tags-todo "-someday/"
                    ((org-agenda-overriding-header "Task Items")
                     (org-agenda-files (append (file-expand-wildcards "~/projects/orgmode/bullet/*.org")))
                     (org-agenda-todo-ignore-scheduled t)
                     (org-agenda-todo-ignore-deadlines t)
                     (org-agenda-todo-ignore-with-date t)))
         (tags "note"
               ((org-agenda-overriding-header "Notes")
                (org-agenda-files (append (file-expand-wildcards "~/projects/orgmode/bullet/*.org"))))))) org-agenda-custom-commands)

(setq org-capture-templates '(("g" " gtd")
                              ("gp" " projects")
                              ("b" " bullet journal")
                              ("l" " local project")
                              ("n" " notes")
                              ("r" " resources")))

(push '("gpt" " task" entry (function nm/find-project-task) "* REFILE %^{task}\n%?" :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)
(push '("gpr" " define requirements" item (function nm/find-project-requirement) "" :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)
(push '("gpn" " note" entry (function nm/find-project-note) "* " :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)
(push '("gpf" " timeframe" entry (function nm/find-project-timeframe) "* %^{timeframe entry} [%<%Y-%m-%d %a %H:%M>]\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?" :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)

;; TODO: Cleanup the template names to be more clear and easier to recognize.
(push '("ga" " append to headline" plain (function nm/org-capture-log) " *Note added:* [%<%Y-%m-%d %a %H:%M>]\n%?" :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)
(push '("gc" " capture" entry (file+olp "~/projects/orgmode/gtd/tasks.org" "Inbox") "* REFILE %^{task}\n:PROPERTIES:\n:CREATED: %U\n:END:\n:METADATA:\n- SOURCE:\n- AUTHOR:\n:END:\n%?") org-capture-templates)
(push '("gk" " capture [kill-ring]" entry (file+olp "~/projects/orgmode/gtd/tasks.org" "Inbox") "* REFILE %^{task}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%c") org-capture-templates)
(push '("gx" " capture [current pos]" entry (file+olp "~/projects/orgmode/gtd/tasks.org" "Inbox") "* REFILE %^{task}\n:PROPERTIES:\n:CREATED: %U\n:END:\nLocation at time of capture: %a") org-capture-templates)

(defun nm/prompt-during-capture ()
  "Prompt and ask for metadata properties during capture."
  (interactive)
  (when (y-or-n-p "add schedule? ")
    (insert (format "SCHEDULED: <%s>"(org-read-date)))))

;; TODO: I need to finish implementing the bullet-journal.
(push '("bt" " bullet task" entry (file+function "~/projects/orgmode/gtd/bullet.org" nm/capture-bullet-journal) "* REFILE %^{task} %^g\n:PROPERTIES:\n:CREATED: %U\n:END:\n" :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)

(push '("nj" " journal" entry (function nm/capture-to-journal) "* %^{entry}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?") org-capture-templates)
(push '("nn" " new reference [excluded from org-roam]" plain (function nm/create-notes-file) "%?" :unnarrowed t :empty-lines-before 1 :empty-lines-after 1) org-capture-templates)
(push '("nr" " roam article" plain (function nm/create-roam-file)"%?" :unnarrowed t) org-capture-templates)

;; TODO: Configure more resource capture templates.
(push '("rr" " research literature" entry (file+function "~/projects/orgmode/gtd/websources.org" nm/enter-headline-websources) "* READ %(get-page-title (current-kill 0))") org-capture-templates)
(push '("rf" " rss feed" entry (file+function "~/projects/orgmode/elfeed.org" nm/return-headline-in-file) "* %^{link}") org-capture-templates)

;; This function is used in conjuction with the capture template "new note" which will find or generate a note based off the folder and filename.
(defun nm/create-notes-file ()
  "Function for creating a notes file under org-capture-templates."
  (nm/find-file-or-create t "~/projects/orgmode/references/" "note"))

(defun nm/create-roam-file ()
  "Function to create a new roam notes file, while prompting for folder location."
  (nm/find-file-or-create t org-directory "note"))

(defun nm/find-project-task ()
  "Function for creating a project file under org-capture-templates."
  (nm/find-file-or-create t "~/projects/orgmode/gtd/projects" "project" "Tasks")
  (setq org-agenda-files (append (file-expand-wildcards "~/projects/orgmode/gtd/*.org") (file-expand-wildcards "~/projects/orgmode/gtd/*/*.org"))))

(defun nm/find-project-timeframe ()
  "Function for creating a project file under org-capture-templates."
  (nm/find-file-or-create t "~/projects/orgmode/gtd/projects" "project" "Timeframe"))

(defun nm/find-project-requirement ()
  "Function for creating a project file under org-capture-templates."
  (nm/find-file-or-create t "~/projects/orgmode/gtd/projects" "project" "Requirements"))

(defun nm/find-project-note ()
  "Function for creating a project file under org-capture-templates."
  (nm/find-file-or-create t "~/projects/orgmode/gtd/projects" "project" "Notes"))

(defun nm/return-headline-in-file ()
  "Returns the headline position."
  (let* ((org-agenda-files "~/projects/orgmode/elfeed.org")
         (location (nth 3 (org-refile-get-location nil nil 'confirm))))
    (goto-char location)
    (org-end-of-line)))

(defun nm/find-project-todo ()
  "When in projectile path, finds root todo.org file"
  (let ((path (doom-project-root))
        (file "todo.org"))
    (find-file (format "%s%s" path file))))

(defun nm/enter-headline-websources ()
  "This is a simple function for the purposes when using org-capture to add my entries to a custom Headline, and if URL is not in clipboard it'll return an error and cancel the capture process."
  (let* ((file "~/projects/orgmode/gtd/websources.org")
         (headline (read-string "Headline? ")))
    (progn
      (nm/check-headline-exist file headline)
      (goto-char (point-min))
      (re-search-forward (format "^\*+\s%s" (upcase headline))))))

(defun nm/check-headline-exist (file-arg headline-arg)
  "This function will check if HEADLINE-ARG exists in FILE-ARG, and if not it creates the headline."
  (save-excursion (find-file file-arg) (goto-char (point-min))
                  (unless (re-search-forward (format "* %s" (upcase headline-arg)) nil t)
                    (goto-char (point-max)) (insert (format "* %s" (upcase headline-arg))) (org-set-property "CATEGORY" (downcase headline-arg)))) t)

(defun nm/org-capture-log ()
  "Initiate the capture system and find headline to capture under."
  (let* ((org-agenda-files (find-lisp-find-files "~/projects/orgmode/gtd/" "\.org$"))
         (dest (org-refile-get-location))
         (file (cadr dest))
         (pos (nth 3 dest))
         (title (nth 2 dest)))
    (find-file file)
    (goto-char pos)
    (nm/org-end-of-headline)))

(after! org (setq org-clock-continuously t)) ; Will fill in gaps between the last and current clocked-in task.

(setq org-tags-column 0)

(setq org-tag-alist '(("@home" . ?h)
                      ("@computer" . ?c)
                      ("@errands")
                      ("@read")
                      ("@delegated")
                      ("someday")))

(after! org (setq org-html-head-include-scripts t
                  org-export-with-toc t
                  org-export-with-author t
                  org-export-headline-levels 4
                  org-export-with-drawers nil
                  org-export-with-email t
                  org-export-with-footnotes t
                  org-export-with-sub-superscripts nil
                  org-export-with-latex t
                  org-export-with-section-numbers nil
                  org-export-with-properties nil
                  org-export-with-smart-quotes t
                  org-export-backends '(pdf ascii html latex odt md pandoc)))

(defun replace-in-string (what with in)
  (replace-regexp-in-string (regexp-quote what) with in nil 'literal))

(defun org-html--format-image (source attributes info)
  (progn
    (setq source (replace-in-string "%20" " " source))
    (format "<img src=\"data:image/%s;base64,%s\"%s />"
            (or (file-name-extension source) "")
            (base64-encode-string
             (with-temp-buffer
               (insert-file-contents-literally source)
              (buffer-string)))
            (file-name-nondirectory source))))

(custom-declare-face '+org-todo-next '((t (:inherit (bold font-lock-constant-face org-todo)))) "")
(custom-declare-face '+org-todo-project '((t (:inherit (bold font-lock-doc-face org-todo)))) "")
(custom-declare-face '+org-todo-onhold  '((t (:inherit (bold warning org-todo)))) "")
(custom-declare-face '+org-todo-next '((t (:inherit (bold font-lock-keyword-face org-todo)))) "")
(custom-declare-face 'org-checkbox-statistics-todo '((t (:inherit (bold font-lock-constant-face org-todo)))) "")

  (setq org-todo-keywords
        '((sequence
           "REFILE(r)" "TODO(t)" "NEXT(n)" "DOING(o)" "WAIT(w)" "|" "DONE(d)" "KILL(k)")
          (sequence
           "PROJ(p)" "|" "COMPLETE" "CANCELED"))
        org-todo-keyword-faces
        '(("WAIT" . +org-todo-onhold)
          ("DOING" . +org-todo-active)
          ("NEXT" . +org-todo-next)
          ("REFILE" . +org-todo-onhold)
          ("PROJ" . +org-todo-next)
          ("TODO" . +org-todo-active)))

(after! org (setq org-agenda-diary-file "~/projects/orgmode/diary.org"
                  org-agenda-dim-blocked-tasks nil ; This has funny behavior, similar to checkbox dependencies.
                  org-agenda-use-time-grid nil
                  org-agenda-tags-column 0
                  org-agenda-hide-tags-regexp "^w+" ; Hides tags in agenda-view
                  org-agenda-compact-blocks nil
                  org-agenda-block-separator " "
                  org-agenda-skip-scheduled-if-done t
                  org-agenda-skip-deadline-if-done t
                  org-agenda-window-setup 'current-window
                  org-enforce-todo-checkbox-dependencies nil ; This has funny behavior, when t and you try changing a value on the parent task, it can lead to Emacs freezing up. TODO See if we can fix the freezing behavior when making changes in org-agenda-mode.
                  org-enforce-todo-dependencies t
                  org-habit-show-habits t))

(after! org (setq org-agenda-files (append (file-expand-wildcards "~/projects/orgmode/gtd/*.org") (file-expand-wildcards "~/projects/orgmode/gtd/*/*.org"))))

(after! org (setq org-log-into-drawer t
                  org-log-done 'time
                  org-log-repeat 'time
                  org-log-redeadline 'note
                  org-log-reschedule 'note))

(after! org (setq org-hide-emphasis-markers t
                  org-hide-leading-stars t
                  org-list-demote-modify-bullet '(("+" . "-") ("1." . "a.") ("-" . "+"))))

(when (require 'org-superstar nil 'noerror)
  (setq org-superstar-headline-bullets-list '("◉")
        org-superstar-item-bullet-alist nil))

(when (require 'org-fancy-priorities nil 'noerror)
  (setq org-fancy-priorities-list '("⚑" "❗" "⬆")))

(after! org (setq org-use-property-inheritance t))

(after! org (setq org-publish-project-alist
                  '(("attachments"
                     :base-directory "~/projects/orgmode/"
                     :recursive t
                     :base-extension "jpg\\|jpeg\\|png\\|pdf\\|css\\|svg"
                     :publishing-directory "~/projects/nmartin84.github.io"
                     :publishing-function org-publish-attachment)
                    ("notes"
                     :base-directory "~/projects/orgmode/"
                     :base-extension "org"
                     :publishing-directory "~/projects/nmartin84.github.io"
                     :section-numbers nil
                     :with-properties nil
                     :with-drawers nil
                     :with-timestamps active
                     :with-creator t
                     :with-email t
                     :with-toc t
                     :recursive t
                     :exclude "gtd/secrets.org|gtd/journal.org"
                     :headline-levels 8
                     :auto-sitemap t
                     :sitemap-filename "index.html"
                     :publishing-function org-html-publish-to-html
                     :html-head "<link rel=\"stylesheet\" href=\"https://raw.githack.com/nmartin84/html-style-sheets/master/notes.css\" type=\"text/css\"/>"
                     :html-link-up "../"
                     :html-link-up "../../index.html"
                     :auto-preamble t)
                    ("myprojectweb" :components("attachments" "notes")))))

(add-hook 'org-mode-hook 'org-appear-mode)
(setq org-appear-autolinks nil)

;(setq company-backends '(company-capf))
(set-company-backend! 'org-mode '(company-yasnippet company-capf company-files company-elisp))
(set-company-backend! 'emacs-lisp-mode '(company-yasnippet company-elisp))
(setq company-idle-delay 0.25
      company-minimum-prefix-length 2)
(add-to-list 'company-backends '(company-capf company-files company-yasnippet company-semantic company-bbdb company-cmake company-keywords))

(map! :map deadgrep-mode-map
      "o" #'deadgrep-visit-result-other-window)

(use-package deft
  :bind (("<f8>" . deft))
  :commands (deft deft-open-file deft-new-file-named)
  :config
  (setq deft-directory "~/projects/orgmode/"
        deft-auto-save-interval 0
        deft-recursive t
        deft-current-sort-method 'title
        deft-extensions '("md" "txt" "org")
        deft-use-filter-string-for-filename t
        deft-use-filename-as-title nil
        deft-markdown-mode-title-level 1
        deft-file-naming-rules '((nospace . "-"))))

(defun my-deft/strip-quotes (str)
  (cond ((string-match "\"\\(.+\\)\"" str) (match-string 1 str))
        ((string-match "'\\(.+\\)'" str) (match-string 1 str))
        (t str)))

(defun my-deft/parse-title-from-front-matter-data (str)
  (if (string-match "^title: \\(.+\\)" str)
      (let* ((title-text (my-deft/strip-quotes (match-string 1 str)))
             (is-draft (string-match "^draft: true" str)))
        (concat (if is-draft "[DRAFT] " "") title-text))))

(defun my-deft/deft-file-relative-directory (filename)
  (file-name-directory (file-relative-name filename deft-directory)))

(defun my-deft/title-prefix-from-file-name (filename)
  (let ((reldir (my-deft/deft-file-relative-directory filename)))
    (if reldir
        (concat (directory-file-name reldir) " > "))))

(defun my-deft/parse-title-with-directory-prepended (orig &rest args)
  (let ((str (nth 1 args))
        (filename (car args)))
    (concat
      (my-deft/title-prefix-from-file-name filename)
      (let ((nondir (file-name-nondirectory filename)))
        (if (or (string-prefix-p "README" nondir)
                (string-suffix-p ".txt" filename))
            nondir
          (if (string-prefix-p "---\n" str)
              (my-deft/parse-title-from-front-matter-data
               (car (split-string (substring str 4) "\n---\n")))
            (apply orig args)))))))

(provide 'my-deft-title)

(advice-add 'deft-parse-title :around #'my-deft/parse-title-with-directory-prepended)

(use-package elfeed-org
  :defer
  :config
  (setq rmh-elfeed-org-files (list "~/projects/orgmode/elfeed.org")))
(use-package elfeed
  :defer
  :config
  (setq elfeed-db-directory "~/.elfeed/"))

(require 'elfeed-org)
(elfeed-org)
(setq elfeed-db-directory "~/.elfeed/")
(setq rmh-elfeed-org-files (list "~/.elfeed/elfeed.org"))

(after! org (setq org-ditaa-jar-path "~/.emacs.d/.local/straight/repos/org-mode/contrib/scripts/ditaa.jar"))

(use-package gnuplot
  :defer
  :config
  (setq gnuplot-program "gnuplot"))

; MERMAID
(use-package mermaid-mode
  :defer
  :config
  (setq mermaid-mmdc-location "~/node_modules/.bin/mmdc"
        ob-mermaid-cli-path "~/node_modules/.bin/mmdc"))

; PLANTUML
(use-package ob-plantuml
  :ensure nil
  :commands
  (org-babel-execute:plantuml)
  :defer
  :config
  (setq plantuml-jar-path (expand-file-name "~/.doom.d/plantuml.jar")))

(setq hugo_base_dir "~/projects/braindump/")

(after! org (setq org-journal-dir "~/projects/orgmode/gtd/journal/"
                  org-journal-enable-agenda-integration t
                  org-journal-file-type 'monthly
                  org-journal-carryover-items "TODO=\"TODO\"|TODO=\"NEXT\"|TODO=\"PROJ\"|TODO=\"STRT\"|TODO=\"WAIT\"|TODO=\"HOLD\""))

(add-to-list 'magit-todos-keywords-list "NOTE")

(setq org-noter-notes-search-path (concat org-directory "literature/"))

(setq org-pandoc-options '((standalone . t) (self-contained . t)))

(when (require 'ox-reveal nil 'noerror)
  (setq org-reveal-root "https://cdn.jsdelivr.net/npm/reveal.js")
  (setq org-reveal-title-slide nil))

(when (require 'org-roam nil 'noerror)
  (setq org-roam-tag-sources '(prop all-directories))
  (setq org-roam-db-location "~/projects/orgmode/roam.db")
  (setq org-roam-directory "~/projects/orgmode/")
  (setq org-roam-buffer-position 'right)
  (setq org-roam-link-file-path-type 'relative)
  (setq org-roam-file-exclude-regexp "references/*\\|gtd/*\\|elfeed.org\\|README.org")
  (setq org-roam-completion-everywhere t)
  ;; Configuration of daily templates
  (setq org-roam-dailies-capture-templates
      '(("d" "daily" plain (function org-roam-capture--get-point) ""
         :immediate-finish t
         :file-name "journal/%<%Y-%m-%d-%a>"
         :head "#+TITLE: %<%Y-%m-%d %a>\n#+STARTUP: content\n\n")))
  (setq org-roam-capture-templates
        '(("l" "literature" plain (function org-roam-capture--get-point)
           :file-name "literature/%<%Y%m%d%H%M>-${slug}"
           :head "#+title: ${title}\n#+author: %(concat user-full-name)\n#+email: %(concat user-mail-address)\n#+created: %(format-time-string \"[%Y-%m-%d %H:%M]\")\n#+roam_tags: %^{roam_tags}\n\nsource: \n\n%?"
           :unnarrowed t)
          ("f" "fleeting" plain (function org-roam-capture--get-point)
           :file-name "fleeting/%<%Y%m%d%H%M>-${slug}"
           :head "#+title: ${title}\n#+author: %(concat user-full-name)\n#+email: %(concat user-mail-address)\n#+created: %(format-time-string \"[%Y-%m-%d %H:%M]\")\n#+roam_tags:\n\n%?"
           :unnarrowed t)
          ("p" "Permanent (prompt folder)" plain (function org-roam-capture--get-point)
           :file-name "%(read-directory-name \"directory: \" org-directory)/%<%Y%m%d%H%M>-${slug}"
           :head "#+title: ${title}\n#+author: %(concat user-full-name)\n#+email: %(concat user-mail-address)\n#+created: %(format-time-string \"[%Y-%m-%d %H:%M]\")\n#+roam_tags:\n\n%?"
           :unnarrowed t)))
  (push '("x" "Projects" plain (function org-roam-capture--get-point)
          :file-name "gtd/projects/%<%Y%m%d%H%M>-${slug}"
          :head "#+title: ${title}\n#+roam_tags: %^{tags}\n\n%?"
          :unnarrowed t) org-roam-capture-templates))

(defun nm/org-roam-prompt-tags ()
  "Prompt user and ask if they want to input roam_tags during capture."
  (when (y-or-n-p "Add tags? ")
    (insert (format "%s" "\n#+roam_tags: "))))

(when (require 'org-roam-server nil 'noerror)
  (use-package org-roam-server
    :ensure t
    :config
    (setq org-roam-server-host "192.168.1.249"
          org-roam-server-port 8060
          org-roam-server-export-inline-images t
          org-roam-server-authenticate nil
          org-roam-server-network-poll t
          org-roam-server-network-vis-options "{ \"layout\": { \"randomSeed\": false }, \"physics\": { \"stabilization\": { \"iterations\": 10000, \"fit\": false, \"updateInterval\": 10000 }, \"barnesHut\": { \"gravitationalConstant\": -4000, \"avoidOverlap\": 1, \"springConstant\": 0.02, \"springLength\": 95 } } }"
          org-roam-server-network-arrows nil
          org-roam-server-serve-files t
          org-roam-server-extra-node-options (list (cons 'shape "dot") (cons 'opacity 1))
          org-roam-server-network-label-truncate t
          org-roam-server-network-label-truncate-length 40
          org-roam-server-network-label-wrap-length 20)))

(load! "org-helpers.el")

(defun nm/task-is-active-proj ()
  "Checks if task is a Project with child subtask"
  (and (bh/is-project-p)
       (nm/has-subtask-active-p)))

(defun nm/task-is-stuck-proj ()
  "Checks if task is a Project with child subtask"
  (and (bh/is-project-p)
       (not (nm/has-subtask-active-p))))

(defun nm/has-subtask-active-p ()
  "Returns t for any heading that has subtasks."
  (save-restriction
    (widen)
    (org-back-to-heading t)
    (let ((end (save-excursion (org-end-of-subtree t))))
      (outline-end-of-heading)
      (save-excursion
        (re-search-forward (concat "^\*+ " "\\(NEXT\\|DOING\\)") end t)))))

(defun nm/update-task-conditions ()
  "Update task states depending on their conditions."
  (interactive)
  (org-map-entries (lambda ()
                     (when (nm/task-is-active-proj) (org-todo "ACTIVE"))
                     (when (nm/task-is-stuck-proj) (org-todo "PENDING"))) t))

(add-hook 'before-save-hook #'nm/update-task-conditions)

(defun nm/find-file-cleaned-up (folder)
  "Returns a list of filenames, in a cleaned up format and easy to read. FOLDER will
   be your folder path to search for."
  (interactive)
  (let* ((files (find-lisp-find-files folder ".org$"))
         (files-alist nil)
         (file-names nil))
    (dolist (i files) (push (cons i (capitalize (replace-regexp-in-string "[-_]" " " (replace-regexp-in-string "^[0-9]+-\\|.org$" "" (file-name-nondirectory i))))) files-alist))
    (dolist (i files-alist) (push (cdr i) file-names))
    (let* ((choice (ivy-completing-read "select: " file-names)))
      (if (equal choice "")
          nil
        (find-file (car (rassoc choice files-alist)))))))

(defun nm/convert-filename-format (&optional time-p folder-path)
  "Prompts user for filename and directory, and returns the value in a cleaned up format.
   If TIME-P is t, then includes date+time stamp in filename, FOLDER-PATH is the folder
   location to search for files."
  (let* ((file (replace-in-string " " "-" (downcase (read-file-name "select file: " (if folder-path (concat folder-path) org-directory))))))
    (if (file-exists-p file)
        (concat file)
      (if (s-ends-with? ".org" file)
          (concat (format "%s%s" (file-name-directory file) (if time-p (concat (format-time-string "%Y%m%d%H%M%S-") (file-name-nondirectory (downcase file)))
                                                              (concat (file-name-nondirectory (downcase file))))))
        (concat (format "%s%s.org" (file-name-directory file) (if time-p (concat (format-time-string "%Y%m%d%H%M%S-") (file-name-nondirectory (downcase file)))
                                                                (concat (file-name-nondirectory (downcase file))))))))))

(defun nm/find-file-or-create (time-p folder-path &optional type header)
  "Creates a new file, if TYPE is set to NOTE then also insert file-template."
  (interactive)
  (let* ((file (nm/convert-filename-format time-p folder-path))) ;; TODO: Add condition when filename is passed in as argument to skip this piece.
    (if (file-exists-p file)
        (find-file file)
      (when (equal "note" type) (find-file file)
            (insert (format "%s\n%s\n%s\n\n"
                            (downcase (format "#+title: %s" (replace-in-string "-" " " (replace-regexp-in-string "[0-9]+-" "" (replace-in-string ".org" "" (file-name-nondirectory file))))))
                            (downcase (concat "#+author: " user-full-name))
                            (downcase (concat "#+email: " user-mail-address)))))
      (when (equal "project" type) (find-file file)
            (insert (format "%s\n%s\n%s\n\n* Requirements\n\n* Timeframe\n\n* Notes\n\n* Tasks\n"
                            (downcase (format "#+title: %s" (replace-in-string "-" " " (replace-regexp-in-string "[0-9]+-" "" (replace-in-string ".org" "" (file-name-nondirectory file))))))
                            (downcase (concat "#+author: " user-full-name ))
                            (downcase (concat "#+email: " user-mail-address)))))
      (when (equal nil type) (find-file)))
    ;; If user passes in header argument, search for it and if the search fails to find the header, create it.
    (if header (unless (progn (goto-char (point-min)) (re-search-forward (format "^*+ %s" header)))
                 (goto-char (point-max))
                 (newline)
                 (insert (format "* %s" header))
                 (newline)))))

(defadvice org-archive-subtree (around fix-hierarchy activate)
  (let* ((fix-archive-p (and (not current-prefix-arg)
                             (not (use-region-p))))
         (location (org-archive--compute-location org-archive-location))
         (afile (car location))
         (offset (if (= 0 (length (cdr location)))
                     1
                   (1+ (string-match "[^*]" (cdr location)))))
         (buffer (or (find-buffer-visiting afile) (find-file-noselect afile))))
    ad-do-it
    (when fix-archive-p
      (with-current-buffer buffer
        (goto-char (point-max))
        (while (> (org-current-level) offset) (org-up-heading-safe))
        (let* ((olpath (org-entry-get (point) "ARCHIVE_OLPATH"))
               (path (and olpath (split-string olpath "/")))
               (level offset)
               tree-text)
          (when olpath
            (org-mark-subtree)
            (setq tree-text (buffer-substring (region-beginning) (region-end)))
            (let (this-command) (org-cut-subtree))
            (goto-char (point-min))
            (save-restriction
              (widen)
              (-each path
                (lambda (heading)
                  (if (re-search-forward
                       (rx-to-string
                        `(: bol (repeat ,level "*") (1+ " ") ,heading)) nil t)
                      (org-narrow-to-subtree)
                    (goto-char (point-max))
                    (unless (looking-at "^")
                      (insert "\n"))
                    (insert (make-string level ?*)
                            " "
                            heading
                            "\n"))
                  (cl-incf level)))
              (widen)
              (org-end-of-subtree t t)
              (org-paste-subtree level tree-text))))))))

;; (defface org-logbook-note
;;   '((t (:foreground "LightSkyBlue")))
;;   "Face for printr function")
;; (custom-set-faces!
;;   '(org-roam-block-link :weight "bold"))

;; (font-lock-add-keywords 'org-mode '(("\\[\\[\\[\\[.+\\]\\[.+\\]\\]\\]\\]" . 'org-roam-block-link)))

(defun nm/org-get-headline-property (arg)
  "Extract property from headline and return results."
  (interactive)
  (org-entry-get nil arg t))

(defun nm/org-get-headline-properties ()
  "Get headline properties for ARG."
  (org-back-to-heading)
  (org-element-at-point))

(defun nm/org-get-headline-title ()
  "Get headline title from current headline."
  (interactive)
  (org-element-property :title (nm/org-get-headline-properties)))

;;;;;;;;;;;;--------[ Clarify Task Properties ]----------;;;;;;;;;;;;;

(defun nm/org-clarify-metadata ()
  "Runs the clarify-task-metadata function with ARG being a list of property values." ; TODO work on this function and add some meaning to it.
  (interactive)
  (nm/org-clarify-task-properties org-tasks-properties-metadata))

(map! :after org
      :map org-mode-map
      :localleader
      :prefix ("j" . "nicks functions")
      :desc "Clarify properties" "c" #'nm/org-clarify-metadata)

(defun nm/emacs-change-font ()
  "Change font based on available font list."
  (interactive)
  (let ((font (ivy-completing-read "font: " nm/font-family-list))
        (size (ivy-completing-read "size: " '("16" "18" "20" "22" "24" "26" "28" "30")))
        (weight (ivy-completing-read "weight: " '(normal light bold extra-light ultra-light semi-light extra-bold ultra-bold)))
        (width (ivy-completing-read "width: " '(normal condensed expanded ultra-condensed extra-condensed semi-condensed semi-expanded extra-expanded ultra-expanded))))
    (setq doom-font (font-spec :family font :size (string-to-number size) :weight (intern weight) :width (intern width))
          doom-big-font (font-spec :family font :size (+ 2 (string-to-number size)) :weight (intern weight) :width (intern width))))
  (doom/reload-font))

(defvar nm/font-family-list '("JetBrains Mono" "Roboto Mono" "VictorMono Nerd Font Mono" "Fira Code" "Hack" "Input Mono" "Anonymous Pro" "Cousine" "PT Mono" "DejaVu Sans Mono" "Victor Mono" "Liberation Mono"))

(let ((secrets (expand-file-name "secrets.el" doom-private-dir)))
  (when (file-exists-p secrets)
    (load secrets)))
