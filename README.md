
# Table of Contents

-   [Getting started](#org36cb03a)
    -   [New Changes](#org3681dc9)
-   [Pretty](#org80b775d)
    -   [Fonts](#org86f430b)
    -   [Bullets and more](#org442f5ed)
-   [Environment](#orgaff8689)
    -   [User Information](#org3e21e99)
    -   [Default folder(s) and file(s)](#orgac5a228)
    -   [Misc Settings](#org314e561)
    -   [Key Bindings](#org4eb6b4f)
    -   [Terminal Mode](#orgd0c19a2)
-   [Behavior](#org4aef802)
    -   [Popup Rules](#org4e1bee9)
    -   [Buffer Settings](#org59267f6)
    -   [Misc Settings](#org0b22868)
-   [Module Settings](#orgb1463c6)
    -   [Misc Modules [Bookmarks, PDF Tools]](#org8db1b21)
    -   [Graphs and Chart Modules](#orge86d7cb)
    -   [Elfeed](#org86201d7)
    -   [DEFT](#orged734a9)
    -   [Org-Rifle](#orge2eb1fa)
    -   [ROAM](#orgcda57f7)
    -   [ROAM Export Backlinks + Content](#org43599ae)
    -   [Reveal [HTML Presentations]](#orgb3ca7c6)
    -   [Super Agenda Settings](#org906ee72)
-   [Load Extras](#orgcd9f17a)
    -   [Theme Settings](#org792db13)



<a id="org36cb03a"></a>

# Getting started


<a id="org3681dc9"></a>

## New Changes

1.  <span class="timestamp-wrapper"><span class="timestamp">[2020-06-21 Sun]</span></span>
    1.  metrics-tracker + capture-template for habit tracker (see ~/.doom.d/templates/habitstracker.org)
    2.  new templates for captures, breakfix, meeting-notes, diary and more&#x2026; (check the ~/.doom.d/templates/.. directory)
    3.  added org-roam-server
2.  <span class="timestamp-wrapper"><span class="timestamp">[2020-06-02 Tue]</span></span>
    1.  Added `org-roam`
    2.  Added agenda schdules faces (thanks to )
    3.  Search and narrow&#x2026; Bound to `SPC ^`, this provides a function to pick a headline from the current buffer and narrow to it.
    4.  Agenda-Hook to narrow on current subtree
    5.  Deft mode with custom title maker (thanks to [jingsi&rsquo;s space](https://jingsi.space/post/2017/04/05/organizing-a-complex-directory-for-emacs-org-mode-and-deft/))
    6.  GTD Inbox Processing &#x2026; Credit to Jethro for his function. Function is bound to `jethro/org-inbox-process`
    7.  [Org-Web-Tools](https://github.com/alphapapa/org-web-tools), thanks Alphapapa for the awesome package.


<a id="org80b775d"></a>

# Pretty


<a id="org86f430b"></a>

## Fonts

For fonts please download [Input](https://input.fontbureau.com/download/) and [DejaVu](http://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-ttf-2.37.tar.bz2)

    (defun zyro/adjust-font-on-display ()
      "Adjust font size to display"
      (if (equal (display-pixel-width) 5120)
          (setq doom-font (font-spec :family "Input Mono" :size 18)
                doom-big-font (font-spec :family "Input Mono" :size 24))
        (setq doom-font (font-spec :family "Input Mono" :size 16)
              doom-big-font (font-spec :family "Input Mono" :size 22))))
    (zyro/adjust-font-on-display)


<a id="org442f5ed"></a>

## Bullets and more

    (setq org-tags-column 0)
    (setq org-superstar-headline-bullets-list '("●" "○"))
    (setq org-ellipsis "▼")


<a id="orgaff8689"></a>

# Environment


<a id="org3e21e99"></a>

## User Information

Load ORG Files
Environment settings, which are specific to the user and system. First up are user settings.

    (setq user-full-name "Nicholas Martin"
          user-mail-address "nmartin84@gmail.com")


<a id="orgac5a228"></a>

## Default folder(s) and file(s)

Then we will define some default files. I&rsquo;m probably going to use default task files for inbox/someday/todo at some point so expect this to change. Also note, all customer functions will start with a `+` to distinguish from major symbols.

    (setq diary-file "~/.org/diary.org")
    (defvar +org-gtd-project-folder "~/.org/gtd/")
    (defvar +org-gtd-tasks-file (concat +org-gtd-project-folder '"next.org"))
    (defvar +org-gtd-inbox-file (concat +org-gtd-project-folder '"inbox.org"))
    (defvar +org-gtd-someday-file (concat +org-gtd-project-folder '"someday.org"))
    (defvar +org-gtd-references-file (concat +org-gtd-project-folder '"references.org"))
    (defvar +org-gtd-notes-file (concat +org-gtd-project-folder '"notes.org"))
    (defvar +org-gtd-refs-project '"~/.org/refs/")


<a id="org314e561"></a>

## Misc Settings

Now we load some default settings for EMACS.

    (display-time-mode 1)
    (setq display-time-day-and-date t)
    (add-to-list 'default-frame-alist '(fullscreen . maximized))


<a id="org4eb6b4f"></a>

## Key Bindings

From here we load some extra key bindings that I use often

    (bind-key "<f5>" #'org-cycle-hide-all-drawers)
    (bind-key "C-M-<up>" #'evil-window-up)
    (bind-key "C-M-<down>" #'evil-window-down)
    (bind-key "C-M-<left>" #'evil-window-left)
    (bind-key "C-M-<right>" #'evil-window-right)
    (map! :after org
          :map org-mode-map
          :leader
          :desc "Move up window" "<up>" #'evil-window-up
          :desc "Move down window" "<down>" #'evil-window-down
          :desc "Move left window" "<left>" #'evil-window-left
          :desc "Move right window" "<right>" #'evil-window-right
          :desc "Toggle Narrowing" "!" #'org-toggle-narrow-to-subtree
          :desc "Find and Narrow" "^" #'+org-find-headline-narrow
          :desc "Rifle Project Files" "P" #'helm-org-rifle-project-files
          :prefix ("s" . "+search")
          :desc "Counsel Narrow" "n" #'counsel-narrow
          :desc "Rifle Buffer" "b" #'helm-org-rifle-current-buffer
          :desc "Rifle Agenda Files" "a" #'helm-org-rifle-agenda-files
          :desc "Deadgrep" "d" #'deadgrep
          :desc "Rifle Project Files" "#" #'helm-org-rifle-project-files
          :desc "Rifle Other Project(s)" "$" #'helm-org-rifle-other-files
          :prefix ("l" . "+links")
          "o" #'org-open-at-point
          "g" #'eos/org-add-ids-to-headlines-in-file
          :prefix ("G" . "gtd")
           :desc "Next" "n" #'+org-gtd-next-tasks
           :desc "Inbox" "i" #'+org-gtd-inbox
           :desc "Someday" "s" #'+org-gtd-someday
           :desc "References" "r" #'+org-gtd-references)
    
    (map! :leader
          :desc "Set Bookmark" "`" #'my/goto-bookmark-location
          :prefix ("s" . "search")
          :desc "Deadgrep Directory" "d" #'deadgrep
          :desc "Swiper All" "@" #'swiper-all
          :prefix ("o" . "open")
          :desc "Elfeed" "e" #'elfeed
          :desc "Deft" "w" #'deft)


<a id="orgd0c19a2"></a>

## Terminal Mode

Set a few settings if we detect terminal mode

    (when (equal (window-system) nil)
      (and
       (bind-key "C-<down>" #'+org/insert-item-below)
       (setq doom-font (font-spec :family "Input Mono" :size 20))
       (setq doom-theme 'doom-dracula)))


<a id="org4aef802"></a>

# Behavior


<a id="org4e1bee9"></a>

## Popup Rules

    (after! org (set-popup-rule! "CAPTURE*" :side 'bottom :size .40 :select t :vslot 2 :ttl 3))
    (after! org (set-popup-rule! "*Deft*" :side 'right :size .50 :select t :vslot 2 :ttl 3))
    ;(after! org (set-popup-rule! "*Select Link*" :side 'bottom :size .40 :select t :vslot 3 :ttl 3))
    ;(after! org (set-popup-rule! "*helm*" :side 'bottom :size .50 :select t :vslot 5 :ttl 3))
    ;(after! org (set-popup-rule! "*deadgrep" :side 'bottom :height .40 :select t :vslot 4 :ttl 3))
    ;(after! org (set-popup-rule! "\\Swiper" :side 'bottom :size .30 :select t :vslot 4 :ttl 3))
    ;(after! org (set-popup-rule! "*Org Agenda*" :side 'right :size .40 :select t :vslot 2 :ttl 3))


<a id="org59267f6"></a>

## Buffer Settings

    (global-auto-revert-mode 1)
    (setq undo-limit 80000000
          evil-want-fine-undo t
          auto-save-default t
          inhibit-compacting-font-caches t)
    (whitespace-mode -1)
    (setq initial-buffer-choice "~/.org/gtd/next.org")


<a id="org0b22868"></a>

## Misc Settings

    (setq display-line-numbers-type t)
    (setq-default
     delete-by-moving-to-trash t
     tab-width 4
     uniquify-buffer-name-style 'forward
     window-combination-resize t
     x-stretch-cursor t)


<a id="orgb1463c6"></a>

# Module Settings


<a id="org8db1b21"></a>

## Misc Modules [Bookmarks, PDF Tools]

    (require 'bookmark+)

Configuring PDF support and ORG-NOTER for note taking

    (use-package org-pdftools
      :hook (org-load . org-pdftools-setup-link))


<a id="orge86d7cb"></a>

## Graphs and Chart Modules

Eventually I would like to have org-mind-map generating charts like Sacha&rsquo;s [evil-plans](https://pages.sachachua.com/evil-plans/).

    (after! org (setq org-ditaa-jar-path "~/.emacs.d/.local/straight/repos/org-mode/contrib/scripts/ditaa.jar"))
    
    ; GNUPLOT
    (use-package gnuplot
      :config
      (setq gnuplot-program "gnuplot"))
    
    ; MERMAID
    (setq mermaid-mmdc-location "~/node_modules/.bin/mmdc"
          ob-mermaid-cli-path "~/node_modules/.bin/mmdc")
    
    ; ORG-MIND-MAP
    (use-package org-mind-map
      :init
      (require 'ox-org)
      ;; Uncomment the below if 'ensure-system-packages` is installed
      ;;:ensure-system-package (gvgen . graphviz)
      :config
      ;;(setq org-mind-map-engine "dot")       ; Default. Directed Graph
       (setq org-mind-map-engine "neato")  ; Undirected Spring Graph
      ;; (setq org-mind-map-engine "twopi")  ; Radial Layout
      ;; (setq org-mind-map-engine "fdp")    ; Undirected Spring Force-Directed
      ;; (setq org-mind-map-engine "sfdp")   ; Multiscale version of fdp for the layout of large graphs
      ;; (setq org-mind-map-engine "twopi")  ; Radial layouts
      ;; (setq org-mind-map-engine "circo")  ; Circular Layout
      )
    
    ; PLANTUML
    (use-package ob-plantuml
      :ensure nil
      :commands
      (org-babel-execute:plantuml)
      :config
      (setq plantuml-jar-path (expand-file-name "~/.doom.d/plantuml.jar")))


<a id="org86201d7"></a>

## Elfeed

    (require 'elfeed-org)
    (elfeed-org)
    (setq rmh-elfeed-org-files (list "~/.elfeed/elfeed.org"))


<a id="orged734a9"></a>

## DEFT

    (load! "my-deft-title.el")
    (use-package deft
      :bind (("<f8>" . deft))
      :commands (deft deft-open-file deft-new-file-named)
      :config
      (setq deft-directory "~/.org/notes/"
            deft-auto-save-interval 0
            deft-recursive t
            deft-current-sort-method 'title
            deft-extensions '("md" "txt" "org")
            deft-use-filter-string-for-filename t
            deft-use-filename-as-title nil
            deft-markdown-mode-title-level 1
            deft-file-naming-rules '((nospace . "-"))))
    (require 'my-deft-title)
    (advice-add 'deft-parse-title :around #'my-deft/parse-title-with-directory-prepended)


<a id="orge2eb1fa"></a>

## Org-Rifle

    (use-package helm-org-rifle
      :after (helm org)
      :preface
      (autoload 'helm-org-rifle-wiki "helm-org-rifle")
      :config
    ;  (add-to-list 'helm-org-rifle-actions '("Super Link" . sl-insert-link-rifle-action) t)
      (add-to-list 'helm-org-rifle-actions '("Insert link" . helm-org-rifle--insert-link) t)
    ;  (add-to-list 'helm-org-rifle-actions '("Insert link with custom ID" . helm-org-rifle--insert-link-with-custom-id) t)
      (add-to-list 'helm-org-rifle-actions '("Store link" . helm-org-rifle--store-link) t)
    ;  (add-to-list 'helm-org-rifle-actions '("Store link with custom ID" . helm-org-rifle--store-link-with-custom-id) t)
    ;  (add-to-list 'helm-org-rifle-actions '("Add org-edna dependency on this entry (with ID)" . akirak/helm-org-rifle-add-edna-blocker-with-id) t)
      (add-to-list 'helm-org-rifle-actions '("Go-to Entry and Narrow" . helm-org-rifle--narrow))
      (defun helm-org-rifle--store-link (candidate &optional use-custom-id)
        "Store a link to CANDIDATE."
        (-let (((buffer . pos) candidate))
          (with-current-buffer buffer
            (org-with-wide-buffer
             (goto-char pos)
             (when (and use-custom-id
                        (not (org-entry-get nil "CUSTOM_ID")))
               (org-set-property "CUSTOM_ID"
                                 (read-string (format "Set CUSTOM_ID for %s: "
                                                      (substring-no-properties
                                                       (org-format-outline-path
                                                        (org-get-outline-path t nil))))
                                              (helm-org-rifle--make-default-custom-id
                                               (nth 4 (org-heading-components))))))
             (call-interactively 'org-store-link)))))
    
      (defun helm-org-rifle--narrow (candidate)
        "Go-to and then Narrow Selection"
        (helm-org-rifle-show-entry candidate)
        (org-narrow-to-subtree))
    
      (defun helm-org-rifle--store-link-with-custom-id (candidate)
        "Store a link to CANDIDATE with a custom ID.."
        (helm-org-rifle--store-link candidate 'use-custom-id))
    
      (defun helm-org-rifle--insert-link (candidate &optional use-custom-id)
        "Insert a link to CANDIDATE."
        (unless (derived-mode-p 'org-mode)
          (user-error "Cannot insert a link into a non-org-mode"))
        (let ((orig-marker (point-marker)))
          (helm-org-rifle--store-link candidate use-custom-id)
          (-let (((dest label) (pop org-stored-links)))
            (org-goto-marker-or-bmk orig-marker)
            (org-insert-link nil dest label)
            (message "Inserted a link to %s" dest))))
    
      (defun helm-org-rifle--make-default-custom-id (title)
        (downcase (replace-regexp-in-string "[[:space:]]" "-" title)))
    
      (defun helm-org-rifle--insert-link-with-custom-id (candidate)
        "Insert a link to CANDIDATE with a custom ID."
        (helm-org-rifle--insert-link candidate t))
    
      (helm-org-rifle-define-command
       "wiki" ()
       "Search in \"~/lib/notes/writing\" and `plain-org-wiki-directory' or create a new wiki entry"
       :sources `(,(helm-build-sync-source "Exact wiki entry"
                     :candidates (plain-org-wiki-files)
                     :action #'plain-org-wiki-find-file)
                  ,@(--map (helm-org-rifle-get-source-for-file it) files)
                  ,(helm-build-dummy-source "Wiki entry"
                     :action #'plain-org-wiki-find-file))
       :let ((files (let ((directories (list "~/lib/notes/writing"
                                             plain-org-wiki-directory
                                             "~/lib/notes")))
                      (-flatten (--map (f-files it
                                                (lambda (file)
                                                  (s-matches? helm-org-rifle-directories-filename-regexp
                                                              (f-filename file))))
                                       directories))))
             (helm-candidate-separator " ")
             (helm-cleanup-hook (lambda ()
                                  ;; Close new buffers if enabled
                                  (when helm-org-rifle-close-unopened-file-buffers
                                    (if (= 0 helm-exit-status)
                                        ;; Candidate selected; close other new buffers
                                        (let ((candidate-source (helm-attr 'name (helm-get-current-source))))
                                          (dolist (source helm-sources)
                                            (unless (or (equal (helm-attr 'name source)
                                                               candidate-source)
                                                        (not (helm-attr 'new-buffer source)))
                                              (kill-buffer (helm-attr 'buffer source)))))
                                      ;; No candidates; close all new buffers
                                      (dolist (source helm-sources)
                                        (when (helm-attr 'new-buffer source)
                                          (kill-buffer (helm-attr 'buffer source))))))))))
      :general
      (:keymaps 'org-mode-map
       "M-s r" #'helm-org-rifle-current-buffer)
      :custom
      (helm-org-rifle-directories-recursive t)
      (helm-org-rifle-show-path t)
      (helm-org-rifle-test-against-path t))
    
    (provide 'setup-helm-org-rifle)


<a id="orgcda57f7"></a>

## ROAM

    (setq org-roam-directory "~/.org/")


<a id="org43599ae"></a>

## ROAM Export Backlinks + Content

    (defun my/org-roam--backlinks-list-with-content (file)
      (with-temp-buffer
        (if-let* ((backlinks (org-roam--get-backlinks file))
                  (grouped-backlinks (--group-by (nth 0 it) backlinks)))
            (progn
              (insert (format "\n\n* %d Backlinks\n"
                              (length backlinks)))
              (dolist (group grouped-backlinks)
                (let ((file-from (car group))
                      (bls (cdr group)))
                  (insert (format "** [[file:%s][%s]]\n"
                                  file-from
                                  (org-roam--get-title-or-slug file-from)))
                  (dolist (backlink bls)
                    (pcase-let ((`(,file-from _ ,props) backlink))
                      (insert (s-trim (s-replace "\n" " " (plist-get props :content))))
                      (insert "\n\n")))))))
        (buffer-string)))
    
      (defun my/org-export-preprocessor (backend)
        (let ((links (my/org-roam--backlinks-list-with-content (buffer-file-name))))
          (unless (string= links "")
            (save-excursion
              (goto-char (point-max))
              (insert (concat "\n* Backlinks\n") links)))))
    
      (add-hook 'org-export-before-processing-hook 'my/org-export-preprocessor)


<a id="orgb3ca7c6"></a>

## Reveal [HTML Presentations]

    (require 'ox-reveal)
    (setq org-reveal-root "https://cdn.jsdelivr.net/npm/reveal.js")
    (setq org-reveal-title-slide nil)


<a id="org906ee72"></a>

## Super Agenda Settings

    (org-super-agenda-mode t)
    (setq org-agenda-custom-commands
          '(("k" "Next Tasks"
              ((agenda ""
                    ((org-agenda-overriding-header "Agenda")
                     (org-agenda-files (list (concat (doom-project-root) "gtd/")))
                     (org-agenda-time-grid nil)
                     (org-agenda-include-diary nil)
                     (org-agenda-start-day (org-today))
                     (org-agenda-span '1)))
               (todo ""
                     ((org-agenda-overriding-header "Not Scheduled")
                      (org-agenda-files (list (concat (doom-project-root) "gtd/next.org")))
                      (org-agenda-skip-function
                       '(or
                         (org-agenda-skip-if 'nil '(scheduled deadline))))))
               (todo ""
                     ((org-agenda-overriding-header "References")
                      (org-agenda-files (list (concat (doom-project-root) "gtd/refs.org")))))
               (todo ""
                     ((org-agenda-overriding-header "Follow-ups")
                      (org-agenda-files (list (concat (doom-project-root) "diary.org")))
                      (org-super-agenda-groups
                       '((:auto-parent t)))))))
            ("i" "Inbox"
             ((todo ""
                    ((org-agenda-overriding-header "")
                     (org-agenda-files (list (concat (doom-project-root) "gtd/inbox.org")))
                     (org-agenda-prefix-format " %(my-agenda-prefix) ")
                     (org-super-agenda-groups
                      '((:auto-ts t)))))))
            ("x" "Someday"
             ((todo ""
                    ((org-agenda-overriding-header "Someday")
                     (org-agenda-files (list (concat (doom-project-root) "gtd/someday.org")))
                     (org-agenda-prefix-format " %(my-agenda-prefix) ")
                     (org-super-agenda-groups
                      '((:auto-parent t)))))))))


<a id="orgcd9f17a"></a>

# Load Extras

    ;(load! "superlinks.el")
    (load! "orgmode.el")
    (load! "customs.el")


<a id="org792db13"></a>

## Theme Settings

    (toggle-frame-maximized)
    (after! org (if (y-or-n-p "Load different theme? ")
                    (call-interactively 'counsel-load-theme)))

