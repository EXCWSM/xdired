;;; -*- Mode: Lisp; Package: xdired -*-
;;; This file is not part of xyzzy.
;;; 
;;; pseudo directory editor for xyzzy
;;; written by EXCWSM 2010-2022
;;;
;;; usage:
;;;   (require 'xdired)
;;;   (global-set-key '(#\C-x #\d) 'xdired)

(provide "xdired")

(defpackage "xdired"
  (:use "lisp" "system" "editor")
  (:internal-size 137)
  (:external-size 7))
(use-package "xdired")
(in-package "xdired")

(export '(*xdired-map*
	  *xdired-single-buffer*
	  *xdired-use-recycle-bin*
	  *xdired-send-to-list*
	  *xdired-color-keywords*
	  *xdired-large-file-warning-threshold*
	  *xdired-compress-file-suffixes*
	  *xdired-find-tar-function*
	  *xdired-find-tar-other-window-function*
	  xdired
	  xdired-read-send-to-folder
	  ))

(defvar *xdired-map* nil "Keymap for xdired-mode")
(unless *xdired-map*
  (setf *xdired-map* (make-sparse-keymap))
  (define-key *xdired-map* '(#\ESC #\C-h) 'xdired-unmark-all-files)
  (define-key *xdired-map* #\M-C-h 'xdired-unmark-all-files)
  (define-key *xdired-map* #\C-h 'xdired-unmark-backward)
  (define-key *xdired-map* #\RET 'xdired-find-file)
  (define-key *xdired-map* #\SPC 'next-line)
  (define-key *xdired-map* #\C-a 'xdired-move-to-filename)
  (define-key *xdired-map* #\B 'xdired-byte-compile)
  (define-key *xdired-map* #\c 'xdired-do-compress-to)
  (define-key *xdired-map* #\C 'xdired-do-copy)
  (define-key *xdired-map* #\d 'xdired-flag)
  (define-key *xdired-map* #\D 'xdired-do-delete)
  (define-key *xdired-map* #\e 'xdired-find-file)
  (define-key *xdired-map* #\f 'xdired-find-file)
  (define-key *xdired-map* #\g 'xdired-reload)
  (define-key *xdired-map* #\l 'xdired-reload)
  (define-key *xdired-map* #\m 'xdired-mark)
  (define-key *xdired-map* #\M 'xdired-do-chmod)
  (define-key *xdired-map* #\S 'xdired-do-symlink)
  (define-key *xdired-map* #\n 'next-line)
  (define-key *xdired-map* #\o 'xdired-find-file-other-window)
  (define-key *xdired-map* #\p 'previous-line)
  (define-key *xdired-map* #\q #'(lambda () (interactive) (delete-buffer (selected-buffer))))
  (define-key *xdired-map* #\R 'xdired-do-rename)
  (define-key *xdired-map* #\s 'xdired-sort-next)
  (define-key *xdired-map* #\t 'xdired-toggle-marks)
  (define-key *xdired-map* #\T 'xdired-do-touch)
  (define-key *xdired-map* #\u 'xdired-unmark)
  (define-key *xdired-map* #\U 'xdired-unmark-all-marks)
  (define-key *xdired-map* #\v 'xdired-find-file-read-only)
  (define-key *xdired-map* #\x 'xdired-do-flagged-delete)
  (define-key *xdired-map* #\X 'xdired-shell-command)
  (define-key *xdired-map* #\Z 'xdired-do-compress)
  (define-key *xdired-map* #\! 'xdired-shell-command)
  (define-key *xdired-map* #\^ 'xdired-up-directory)
  (define-key *xdired-map* #\+ 'xdired-create-directory)
  (define-key *xdired-map* #\= 'xdired-diff)
  (define-key *xdired-map* '(#\ESC #\=) 'xdired-count-items)
  (define-key *xdired-map* #\M-= 'xdired-count-items)
  (define-key *xdired-map* #\\ 'xdired-find-root-directory)
  (define-key *xdired-map* #\| 'xdired-shell-command-pipe)
  (define-key *xdired-map* '(#\* #\.) 'xdired-mark-extension)
  (define-key *xdired-map* '(#\* #\/) 'xdired-mark-directories)
  (define-key *xdired-map* '(#\* #\*) 'xdired-mark-executables)
  (define-key *xdired-map* '(#\* #\c) 'xdired-change-marks)
  (define-key *xdired-map* '(#\% #\m) 'xdired-mark-regexp)
  (define-key *xdired-map* '(#\C-c #\Backspace) 'xdired-up-directory)
  (define-key *xdired-map* '(#\C-c #\C-c) 'xdired-do-shell-execute)
  (define-key *xdired-map* '(#\C-c #\C-e) #'(lambda () (interactive) (shell-execute (default-directory))))
  (define-key *xdired-map* '(#\C-c #\C-x) 'xdired-send-to)
  (define-key *xdired-map* '(#\C-c #\z) 'xdired-do-uncompress)
  (define-key *xdired-map* '(#\C-x #\f) 'quit)
  (define-key *xdired-map* '(#\M-g #\g) 'grep-dialog)
  (define-key *xdired-map* '(#\M-g #\M-g) 'grep-dialog)
  (define-key *xdired-map* #\LBtnDown 'xdired-mouse-left-press)
  )

(defvar *xdired-single-buffer* t
  "Specifies whether to kill the previous xdired's buffer.")

(defvar *xdired-use-recycle-bin* ed::*filer-use-recycle-bin*
  "Specifies whether to use the recycle bin.")

(defvar *xdired-guess-shell-alist*
  '(("." "start \"\" \"?\"")
    )
  "Rules for suggested commands.
'( (\"regexp\" \"command\") ... )")

(defvar *xdired-send-to-list*
  '(("notepad" "notepad.exe ?"))
  "#'xdired-send-to references.
'((\"keyword\" \"command-line|directory-path|shortcut-path\") ...)")

(defvar *xdired-compress-file-suffixes*
  '("7z" "arj" "bga" "bz2" "cab" "gca" "gz" "lzh" "rar" "tar" "yz1" "zip")
  "File name suffixes for compressed files. #'xdired-do-compress uses first suffix.")

(defvar *xdired-find-tar-function* nil
  "#'xdired-find-file uses to visit the compressed file.")

(defvar *xdired-find-tar-other-window-function* nil
  "#'xdired-find-file-other-window uses to visit the compressed file.")

(defvar *xdired-color-keywords*
  '(
    ("^  d[\-a]" nil (:keyword 0 :line))
    ("^  [\-d][\-a]s[\-r][\-h]" nil (:color 10 0 :line))
    ;;("^  [\-d][\-a][\-s]r[\-h]" nil (:color 10 0 :line))
    ("^  [\-d][\-a][\-s][\-r]h" nil (:color 10 0 :line))
    ("^\*" nil (:keyword 1 :bold :line))
    ("^D" nil (:color 0 1 :bold :line))
    )
  "Color keywords for xdired-mode")

(defvar *xdired-large-file-warning-threshold* 10000000
  "Maximum file size above which a confirmation is requested.")

(defvar *xdired-sort-functions*
  (list (list "name"
	      #'(lambda (item1 item2)
		  (let ((i1d (logand (nth 1 item1) ed::*file-attribute-directory*))
			(i2d (logand (nth 1 item2) ed::*file-attribute-directory*)))
		    (cond ((or (and (< 0 i1d) (< 0 i2d))
			       (and (= 0 i1d) (= 0 i2d)))
			   (string-lessp (nth 0 item1) (nth 0 item2)))
			  (t (> i1d i2d))))))
	(list "date"
	      #'(lambda (item1 item2)
		  (let ((i1d (logand (nth 1 item1) ed::*file-attribute-directory*))
			(i2d (logand (nth 1 item2) ed::*file-attribute-directory*)))
		    (cond ((or (and (< 0 i1d) (< 0 i2d))
			       (and (= 0 i1d) (= 0 i2d)))
			   (cond ((= (nth 2 item1) (nth 2 item2))
				  (string-lessp (nth 0 item1) (nth 0 item2)))
				 (t
				  (< (nth 2 item1) (nth 2 item2)))))
			  (t (> i1d i2d))))))
	(list "size"
	      #'(lambda (item1 item2)
		  (let ((i1d (logand (nth 1 item1) ed::*file-attribute-directory*))
			(i2d (logand (nth 1 item2) ed::*file-attribute-directory*)))
		    (cond ((or (and (< 0 i1d) (< 0 i2d))
			       (and (= 0 i1d) (= 0 i2d)))
			   (cond ((= (nth 3 item1) (nth 3 item2))
				  (string-lessp (nth 0 item1) (nth 0 item2)))
				 (t
				  (< (nth 3 item1) (nth 3 item2)))))
			  (t (> i1d i2d))))))
	)
  "Sort functions")

;;*****************************************************************************
;;
;; interactive functions
;;
;;*****************************************************************************

(defun xdired (path)
  "xdired"
  (interactive "DxDired: " :default0 (default-directory))
  (let ((*xdired-single-buffer* nil))
    (xdired-find-dir (truename path) nil)))

(defun xdired-find-file (&optional path)
  "Visit the current item."
  (interactive)
  (xdired--find-file (or path (xdired-get-filename)) 'xdired-find-dir *xdired-find-tar-function* 'find-file))

(defun xdired-find-file-read-only (&optional path)
  "Visit the current item, but don't allow changes."
  (interactive)
  (xdired--find-file (or path (xdired-get-filename)) 'xdired-find-dir *xdired-find-tar-function* 'find-file-read-only))

(defun xdired-find-file-other-window (&optional path)
  "Visit the current item, in another window."
  (interactive)
  (xdired--find-file (or path (xdired-get-filename)) 'xdired-find-dir-other-window *xdired-find-tar-other-window-function* 'find-file-other-window))

(defun xdired-up-directory ()
  "Go to parent directory"
  (interactive)
  (let ((parent-path (truename "..")))
    (if (string-not-equal parent-path (default-directory))
	(xdired-find-dir parent-path (pathname-name (default-directory))))))

(defun xdired-find-root-directory ()
  "Go to root directory"
  (interactive)
  (let ((drive-letter (pathname-device (default-directory))))
    (if drive-letter
	(xdired-find-dir (truename (concat drive-letter ":/")) nil))))

(defun xdired-reload ()
  "Reload"
  (interactive)
  (xdired--reload-directory))

(defun xdired-mouse-left-press ()
  "Left button"
  (interactive)
  (let ((fn))
    (if (and (= (mod *last-mouse-click-count* 6) 2) ;; double click
	     (stringp (setq fn (xdired-get-filename))))
	(if (file-directory-p fn)
	    (xdired--find-file fn 'xdired-find-dir *xdired-find-tar-function* 'find-file)
	  (shell-execute (truename fn)))
      (mouse-left-press))))

(defun xdired-move-to-filename ()
  "Move cursor to head of file name."
  (interactive)
  (goto-bol)
  (if (<= 3 (current-line-number))
      (goto-char (+ (point) *xdired-file-name-column*))))

(defun xdired-mark ()
  "Mark"
  (interactive)
  (xdired--mark "*"))

(defun xdired-flag ()
  "Flag"
  (interactive)
  (xdired--mark "D"))

(defun xdired-unmark ()
  "Unmark the current item or all items"
  (interactive)
  (xdired--mark " "))

(defun xdired-unmark-backward ()
  "Unmark the current item and move up cursor"
  (interactive)
  (previous-line)
  (xdired--mark " " 'quit))

(defun xdired-unmark-all-marks ()
  "Remove all marks"
  (interactive)
  (xdired-apply-lines
   (point-min) (point-max)
   nil
   #'(lambda () (xdired-mark-current-line " "))))

(defun xdired-mark-regexp (regexp)
  "Mark all items matching regexp for use in later commands."
  (interactive "sMark files (regexp): ")
  (if (< 0 (length regexp))
      (let ((re (compile-regexp regexp t)))
	(message "~:D matching items marked"
		 (xdired-apply-lines
		  (point-min) (point-max)
		  #'(lambda () (string-match re (xdired-get-filename)))
		  #'xdired-mark-current-line)))))

(defun xdired-mark-extension (ext)
  "Mark all items with a certain extension for use in later commands."
  (interactive "sMark extension: ")
  (if (< 0 (length ext))
      (let ((re-ext (compile-regexp (format nil "\\.~A$" (quote-string ext #\. #\\)) t)))
	(message "~:D matching items marked"
		 (xdired-apply-lines
		  (point-min) (point-max)
		  #'(lambda () (string-match re-ext (xdired-get-filename)))
		  #'xdired-mark-current-line)))))

(defun xdired-mark-directories ()
  "Mark all directories for use in later commands."
  (interactive)
  (message "~:D directory items marked"
	   (xdired-apply-lines
	    (point-min) (point-max)
	    #'(lambda () (char= (char (buffer-substring (progn (goto-bol) (+ 2 (point))) (+ 3 (point))) 0) #\d))
	    #'xdired-mark-current-line)))

(defun xdired-mark-executables ()
  "Mark all executable files for use in later commands."
  (interactive)
  (let ((re (compile-regexp "\\.exe$" t)))
    (message "~:D matching items marked"
	     (xdired-apply-lines
	      (point-min) (point-max)
	      #'(lambda () (string-match re (xdired-get-filename)))
	      #'xdired-mark-current-line))))

(defun xdired-change-marks (&optional old new)
  "Change all #\\old marks to #\\new marks."
  (interactive)
  (unless old (setq old (progn (minibuffer-prompt "Change (old mark)") (read-char *keyboard*))))
  (if (eq old #\C-g) (quit))
  (unless new (setq new (progn (minibuffer-prompt "Change ~C marks to (new mark)" old) (read-char *keyboard*))))
  (if (eq new #\C-g) (quit))
  (if (and (not (eq old new)) (characterp old) (characterp new))
    (progn
      (setq new (string new))
      (xdired-apply-lines
       (point-min) (point-max)
       #'(lambda () (char= (char (buffer-substring (progn (goto-bol) (point)) (1+ (point))) 0) old))
       #'(lambda () (xdired-mark-current-line new))))))

(defun xdired-unmark-all-files (&optional markch)
  "Remove a specific mark from every file."
  (interactive)
  (unless markch (setq markch (progn (minibuffer-prompt "Remove marks (RET means all):") (read-char *keyboard*))))
  (if (or (null markch) (char= markch #\C-g)) (quit))
  (let ((test-func (if (char= markch #\RET)
		       nil
		     #'(lambda () (char= (char (buffer-substring (progn (goto-bol) (point)) (1+ (point))) 0) markch)))))
    (xdired-apply-lines (point-min) (point-max)
			 test-func
			 #'(lambda () (xdired-mark-current-line " ")))))

(defun xdired-toggle-marks (&optional (markch "*"))
  "Toggle marks: marked files become unmarked, vice versa."
  (interactive)
  (xdired-apply-lines
   (point-min) (point-max)
   nil
   #'(lambda () (xdired-mark-current-line markch " "))))

(defun xdired-create-directory (newdir)
  "Create a directory."
  (interactive "FCreate directory: " :default0 (default-directory))
  (if (handler-case
	  (create-directory newdir :if-exists :error)
	(error (c)
	  (message "Can not create direcotry ~A: ~A." newdir (substitute-string (si:*condition-string c) "\r?\n" ""))
	  nil))
      (let ((newpath (merge-pathnames ".." (truename newdir))))
	(xdired-reload-directory newpath (file-namestring newdir))
	(message "New directory \"~A\" created." newpath))))

(defun xdired-do-copy ()
  "Copy all marked files, or copy the current file."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (if items
	(long-operation
	  (xdired-copy items
		       (read-directory-name (concat "Copy "
						    (if (= 1 (length items)) (car items) (format nil "[~D items]" (length items)))
						    " to: ")
					    :default (xdired-get-target-directory)))))))

(defun xdired-do-delete ()
  "Delete the current file."
  (interactive)
  (let ((fn (xdired-get-filename)))
    (if (stringp fn)
	(xdired--delete (list fn) *xdired-use-recycle-bin*))))

(defun xdired-do-flagged-delete ()
  "Delete all flagged files"
  (interactive)
  (long-operation (xdired--delete (xdired-get-marked-files "D") *xdired-use-recycle-bin*)))

(defun xdired-do-rename ()
  "Rename current item or all marked items"
  (interactive)
  (let* ((items (xdired-get-marked-files))
	 (doMove (< 0 (length items))))
    (unless doMove
      (unless (setq items (let ((fn (xdired-get-filename))) (if fn (list fn))))
	(quit)))
    (let ((succeed 0)
	  (rename-src-is-dir (file-directory-p (car items)))
	  (dest (if doMove
		    (read-directory-name (concat "Move "
						 (if (= 1 (length items))
						     (car items)
						   (format nil "[~D items]" (length items)))
						 " to: ")
					 :default (xdired-get-target-directory))
		  (let ((old (remove-trail-slash (car items))))
		    (loop (let ((new (read-string (concat "Rename " old " to: ") :default old)))
			    (if (and (< 0 (length new))
				     (not (file-exist-p new))
				     (not (file-directory-p new)))
				(return new))))))))
      (mapc #'(lambda (item)
		(loop
		  (let ((errmsg))
		    (if (handler-case
			    (rename-file (truename item)
					 (if doMove (merge-pathnames item dest)
					   (merge-pathnames dest (directory-namestring (truename item))))
					 :if-exists :error
					 :if-access-denied :error)
			  (error (c)
			    (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
			    nil))
			(progn
			  (setq succeed (1+ succeed))
			  (return t))
		      (progn
			(message "[~A] Rename: ~A to ~A" (format-date-string "%H:%M:%S") item dest)
			(unless (y-or-n-p "~A Retry ? " (or errmsg "Rename failed."))
			  (return nil)))))
		  (if doMove
		      (do-events))))
	    items)
      (if (< 0 succeed)
	  (progn
	    (xdired--reload-directory (unless doMove dest))
	    (let ((dpath (truename dest)))
	      (if (and doMove
		       (not (path-equal dpath (default-directory))))
		  (xdired-reload-directory dpath (car items))))
	    (message "~D item~A ~A." succeed (if (< 1 succeed) "s" "") (if doMove "moved" "renamed")))
	(message "No rename performed")))))

(defun xdired-do-touch ()
  "Change the timestamp of the makred items."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (if (= 0 (length items)) (quit))
    (let ((succeed 0)
	  (newtime (xdired-datetime-prompt
		    (format nil "Change Timestamp of ~A to: "
			    (if (= 1 (list-length items))
				(car items)
			      (format nil "[~Ditems]" (length items))))
		    (file-write-time (car items))
		    "invalid date time. please re-enter date time.")))
      (mapc #'(lambda (item)
		(loop
		  (let ((errmsg))
		    (if (handler-case
			    (set-file-write-time (truename item) newtime)
			  (error (c)
			    (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
			    nil))
			(progn
			  (setq succeed (1+ succeed))
			  (return t))
		      (progn
			(message "[~A] touch ~A , ~A" (format-date-string "%H:%M:%S") item (format-date-string "%Y-%m-%d %H:%M:%S" newtime))
			(unless (y-or-n-p "~A Retry? " (or errmsg "Rename failed."))
			  (return nil)))))))
	    items)
      (if (< 0 succeed)
	  (progn
	    (xdired--reload-directory)
	    (message "~D item~A touched." succeed (if (< 1 succeed) "s" "")))
	(message "No touch performed")))))

(defun xdired-do-chmod ()
  "Change attribute of the marked items."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (if (= 0 (length items)) (quit))
  (let ((succeed 0)
	(opr (loop (let ((newopr (read-string (concat "Change mode of "
						      (if (= 1 (list-length items))
							  (car items)
							(format nil "~Ditems" (list-length items)))
						      " to: "))))
		     (if (and (< 0 (length newopr))
			      (xdired-chmod-operation newopr 0))
			 (return newopr)
		       (message "invalid change mode operations. please re-enter operations."))))))
    (mapc #'(lambda (item)
	      (let* ((fullpath (truename item))
		     (newattr (xdired-chmod-operation opr (get-file-attributes fullpath))))
		(loop
		  (let ((errmsg))
		    (if (handler-case
			    (modify-file-attributes fullpath newattr (lognot newattr))
			  (error (c)
			    (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
			    nil))
			(progn
			  (setq succeed (1+ succeed))
			  (return t))
		      (progn
			(message "[~A] chmod ~A , ~A" (format-date-string "%H:%M:%S") item opr)
			(unless (y-or-n-p "~A Retry? " (or errmsg "Rename failed."))
			  (return nil))))))))
	  items)
    (if (< 0 succeed)
	(progn
	  (xdired--reload-directory)
	  (message "~D item~A changed." succeed (if (< 1 succeed) "s" "")))
      (message "No chmod performed")))))

(defun xdired-do-symlink ()
  "Create a new short cut (.lnk) file."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (if (= 0 (length items)) (quit)))
  (let ((succeed 0)
	(dest (read-directory-name (concat "New shortcut " (file-namestring (car items)) " to: ")
				   :default (xdired-get-target-directory))))
    (mapc #'(lambda (item)
	      (loop
		(let ((errmsg))
		  (if (handler-case
			  (create-shortcut (truename item) dest)
			(error (c)
			  (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
			  nil))
		      (progn
			(setq succeed (1+ succeed))
			(return t))
		    (progn
		      (message "[~A] create-shortcut ~A to ~A" (format-date-string "%H:%M:%S") item dest)
		      (unless (y-or-n-p "~A Retry? " (or errmsg "create-shortcut failed."))
			(return nil)))))))
	  items)
    (if (< 0 succeed)
	(progn
	  (xdired-reload-directory dest (concat (file-namestring (remove-trail-slash (car item))) ".lnk"))
	  (message "~D item~A linked." succeed (if (< 1 succeed) "s" "")))
      (message "No create-shortcut performed"))))

(defun xdired-do-compress-to ()
  "Compress marked files."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (if (= 0 (length items)) (quit))
    (let ((afile (read-file-name (concat "Compress "
					 (if (= 1 (length items))
					     (car items)
					   (format nil "[~D items]" (length items)))
					 " to: "))))
      (if (long-operation (create-archive afile (mapcar 'truename items) (default-directory)))
	  (xdired--reload-directory (directory-namestring afile))))))

(defun xdired-do-compress ()
  "Compress or uncompress marked files."
  (interactive)
  (let ((items (xdired-get-marked-or-current))
	(succeed 0))
    (if (= 0 (length items)) (quit))
    (if (y-or-n-p (concat "Compress or uncompress " (if (= 1 (length items)) (car items) (format nil "[~D items]" (length items))) ": "))
	(progn
	  (long-operation
	    (mapc #'(lambda (item)
		      (cond ((and (not (file-directory-p item))
				  (member (pathname-type item) *xdired-compress-file-suffixes* :test 'string-equal))
			     (if (extract-archive item (default-directory))
				 (setq succeed (1+ succeed))))
			    (t
			     (if (create-archive (merge-pathnames (concat (file-namestring (remove-trail-slash item)) "." (car *xdired-compress-file-suffixes*)))
						 (list (truename item))
						 (default-directory))
				 (setq succeed (1+ succeed))))
			    ))
		  items))
	  (if (< 0 succeed)
	      (xdired--reload-directory))))))

(defun xdired-do-uncompress ()
  "Uncompress marked files."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (unless items (quit))
    (let ((dest (read-directory-name (concat "Uncompress "
					     (if (= 1 (length items))
						 (car items)
					       (format nil "[~D files]" (length items)))
					     " to: ")
				     :default (default-directory)))
	  (succeed 0))
      (long-operation (mapc #'(lambda (item) (if (extract-archive item dest) (setq succeed (1+ succeed)))) items))
      (if (< 0 succeed)
	  (xdired-reload-directory dest)))))

(defun xdired-do-shell-execute ()
  "ShellExecute()"
  (interactive)
  (mapc #'(lambda (item)
	    (shell-execute (truename item)))
	(xdired-get-marked-or-current)))

(defun xdired-byte-compile (&optional files)
  "Byte compile marked xyzzy lisp files."
  (interactive)
  (if (= 0 (length files)) (setq files (xdired-get-marked-or-current)))
  (if (and (listp files) (< 0 (length files))
	   (y-or-n-p "Byte-compile ~A ?"
		     (cond ((= 1 (length files)) (car files))
			   (t (format nil "[~D files]" (length files))))))
      (mapc 'byte-compile-file files)))

(defun xdired-diff ()
  "diff"
  (interactive)
  (let ((files (remove-if #'null (mapcar #'(lambda (i) (if (file-exist-p i) i)) (xdired-get-marked-or-current)))))
    (diff (read-exist-file-name "diff(new file): "
				:default (or (if files (truename (car files)))
					     (default-directory)))
	  (read-exist-file-name "diff(old file): "
				:default
				(or (if (<= 2 (count-windows))
					(save-window-excursion
					  (let ((orig-win (selected-window)))
					    (other-window 1)
					    (while (not (eq (selected-window) orig-win))
					      (if (eq buffer-mode 'xdired-mode)
						  (let ((fn (car (xdired-get-marked-or-current))))
						    (return (if fn (truename fn)
							      (default-directory)))))
					      (other-window 1)))))
				    (if files
					(truename (cadr files))
				      (default-directory)))))))

(defun xdired-send-to ()
  "Send to ..."
  (interactive)
  (let ((items (xdired-get-marked-or-current)))
    (unless items (quit))
    (if (= 1 (length items))
	(message "~A" (car items))
      (message "~D items" (length items)))
    (let ((cmd (cadr (assoc (completing-read "Send to: " (mapcar 'car *xdired-send-to-list*) :must-match t)
			    *xdired-send-to-list* :test 'string=))))
      (unless (and (stringp cmd) (< 0 (length cmd))) (quit))
      (let ((cmdclass (cond ((string-match "\\.lnk$" cmd)
			     (let ((dest (resolve-shortcut cmd)))
			       (if (file-directory-p dest)
				   (progn (setq cmd dest) 'dir)
				 'lnk)))
			    ((file-directory-p cmd)
			     'dir)
			    (t
			     'cmd))))
	(cond ((eq cmdclass 'dir)
	       (let ((items (xdired-get-marked-or-current)))
		 (if (and (listp items) (< 0 (length items)))
		     (long-operation (xdired-copy items cmd)))))
	      ((eq cmdclass 'lnk)
	       (mapc #'(lambda (item)
			 (shell-execute cmd t (map-slash-to-backslash (truename item))))
		     items))
	      (t
	       (mapc #'(lambda (item)
			 (call-process (substitute-string cmd "\\?" (quote-string (map-slash-to-backslash (truename item)) #\\ #\\)) :wait nil))
		     items)))))))

(defun xdired-shell-command (&optional files)
  "Run a shell command on marked items."
  (interactive)
  (unless files (setq files (xdired-get-marked-or-current)))
  (if (and
       (listp files) (< 0 (length files))
       (setq cmdstr (read-string (concat "! on "
					 (if (= 1 (length files))
					     (car files)
					   (format nil "[~D files]" (length files)))
					 ": ")
				 :default (or (cadr (member-if #'(lambda (cmd) (string-matchp (car cmd) (car files)))
							       *xdired-guess-shell-alist*))
					      "start \"\" \"?\""))))
      (if (< 0 (length cmdstr))
	  (mapc #'(lambda (fn) (pipe-command (substitute-string cmdstr "?" (map-slash-to-backslash (substitute-string fn "/$" "")))))
		files))))

(defun xdired-shell-command-pipe (&optional files)
  "Run a shell command."
  (interactive)
  (unless files (setq files (xdired-get-marked-or-current)))
  (if (and
       (listp files) (< 0 (length files))
       (setq cmdstr (read-string (concat "| on "
					 (if (= 1 (length files)) (car files)
					   (format nil "[~D files] " (length files)))
					 ": "))))
      (if (< 0 (length cmdstr))
	  (with-output-to-temp-buffer ("*Shell Command*")
	    (insert "Command ===> " cmdstr "\n")
	    (let ((proc (make-process cmdstr)))
	      (command-output-mode)
	      (mapc #'(lambda (i)
			(process-send-string proc (concat (map-slash-to-backslash i) "\n")))
		    files)
	      (process-send-string proc (string #\C-z)))))))

(defun xdired-sort-next ()
  "Toggle sort order."
  (interactive)
  (xdired-set-sort-next)
  (xdired-sort)
  (xdired-set-mode-name))

(defun xdired-count-items (&optional (markch "*"))
  "Count the number of items."
  (interactive)
  (let ((point-start) (point-end) (test-funcion)
	(total-files 0) (total-directories 0) (total-bytes 0))
    (cond ((pre-selection-p)
	   (setq point-start (min (selection-mark) (selection-point)))
	   (setq point-end (max (selection-mark) (selection-point)))
	   (setq test-function nil))
	  (t
	   (setq point-start (point-min))
	   (setq point-end (point-max))
	   (setq test-function
		 #'(lambda ()
		     (string= (buffer-substring (progn (goto-bol) (point)) (1+ (point))) markch)))))
    (xdired-apply-lines
     point-start point-end
     test-function
     #'(lambda ()
	 (let ((item (xdired-detail-line-to-values (buffer-substring (progn (goto-bol) (point)) (progn (goto-eol) (point))))))
	   (if (< 0 (logand (nth 1 item) ed::*file-attribute-directory*))
	       (setq total-directories (1+ total-directories))
	     (progn
	       (setq total-files (1+ total-files))
	       (setq total-bytes (+ (nth 3 item) total-bytes)))))))
    (message "~A ~:D items, ~:D directories, ~:D files, ~:D bytes."
	     (if (pre-selection-p)
		 "Selection has"
	       (concat "\"" markch "\""))
	     (+ total-files total-directories) total-directories total-files total-bytes)))

;;*****************************************************************************
;;
;; functions
;;
;;*****************************************************************************

(defun xdired-mode ()
  "xdired mode"
  (kill-all-local-variables)
  (setup-temp-buffer (selected-buffer))
  (setq buffer-mode 'xdired-mode)
  (use-keymap *xdired-map*)
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list (compile-regexp-keyword-list *xdired-color-keywords*))
  (make-local-variable '*xdired-sort-order*)
  (unless *xdired-sort-order*
    (setq *xdired-sort-order* (car *xdired-sort-functions*)))
  (make-local-variable '*xdired-file-name-column*)
  (setq *xdired-file-name-column* (length (xdired-format-detail-line '("" 0 0 0 nil))))
  (make-local-variable 'paragraph-start)
  (setq paragraph-start "^[\\*D] ")
  (xdired-set-mode-name)
  (run-hooks '*xdired-mode-hook*))

(defun xdired-set-mode-name ()
  (setq mode-name (if *xdired-sort-order* (concat "xdired(" (car *xdired-sort-order*) ")")
		    "xdired")))

(defun xdired-load (path &optional marklist)
  "Load directory entries."
  (set-buffer-alternate-file-name path)
  (set-default-directory path)
  (setq buffer-read-only nil)
  (erase-buffer (selected-buffer))
  (insert (xdired-format-header-line path))
  (mapc (if (< 0 (length marklist))
	    #'(lambda (item)
		(insert (xdired-format-detail-line (append item (list (cadr (assoc (car item) marklist :test 'string=))))) "\n"))
	  #'(lambda (item) (insert (xdired-format-detail-line item) "\n")))
	(if *xdired-sort-order*
	    (sort (directory path :show-dots nil :file-info t)
		  (cadr *xdired-sort-order*))
	  (directory path :show-dots nil :file-info t)))
  (set-buffer-modified-p nil)
  (setq buffer-read-only t))

(defun xdired--reload-directory (&optional cur-item)
  "Reload this buffer"
  (unless cur-item
    (unless (setq cur-item (xdired-get-filename))
      (setq cur-item (if (<= (current-line-number) 2) 'top 'botton))))
  (let ((marklist))
    (save-excursion
      (goto-char (point-min))
      (next-line 2)
      (while (not (progn (goto-eol) (eobp)))
	(let ((m (buffer-substring (progn (goto-bol) (point)) (1+ (point)))))
	  (unless (string= m " ")
	    (setq marklist (append marklist (list (list (xdired-get-filename) m))))))
	(next-line)))
    (xdired-load (default-directory) marklist)
    (xdired-goto-filename (or cur-item 1))))

(defun xdired-reload-directory (path &optional cur-item)
  "Reload xdired window"
  (let ((orig-win (selected-window)))
    (loop
      (if (and (eq buffer-mode 'xdired-mode)
	       (path-equal path (default-directory)))
	  (xdired--reload-directory cur-item))
      (other-window 1)
      (if (eq orig-win (selected-window))
	  (return nil)))
    (set-window orig-win)))

(defun xdired-goto-filename (filename)
  "Go to line"
  (cond ((stringp filename)
	 (goto-char
	  (or (save-excursion
		(let ((eol))
		  (setq filename (remove-trail-slash filename))
		  (goto-char (point-min))
		  (while (< (setq eol (progn (goto-eol) (point))) (point-max))
		    (goto-column *xdired-file-name-column*)
		    (if (string-equal filename (remove-trail-slash (buffer-substring (point) eol)))
			(return (point)))
		    (next-line))))
	      (point))))
	((numberp filename)
	 (goto-char (point-min))
	 (if (< 0 filename)
	     (next-line (+ 1 filename))))))

(defun xdired--find-file (path find-dir-function find-tar-function find-file-function)
  "xdired's find-file"
  (cond ((null path)
	 nil)
	((file-directory-p path)
	 (funcall (or find-dir-function 'xdired-find-dir) (truename path)))
	((file-exist-p path)
	 (let ((ext (pathname-type path)))
	   (cond ((string-equal ext "lnk")
		  (let ((dest (handler-case (resolve-shortcut path) (catch (c) nil))))
		    (if (string-not-equal path dest)
			(xdired--find-file dest find-dir-function find-tar-function find-file-function))))
		 ((and find-tar-function
		       (member ext *xdired-compress-file-suffixes* :test 'string-equal))
		  (funcall find-tar-function (truename path)))
		 (t
		  (if (if (numberp *xdired-large-file-warning-threshold*)
			  (let ((filelen (file-length path)))
			    (if (<= *xdired-large-file-warning-threshold* filelen)
				(y-or-n-p (format nil "File ~A is TOO large(~:Dbytes), really open?" (file-namestring path) filelen))
			      t))
			t)
		      (funcall (or find-file-function 'find-file) (truename path)))))))
	(t
	 (message "file not found: ~A" path))))

(defun xdired--find-directory (path)
  "find xdired buffer or create"
  (or (enum-buffers
       #'(lambda (buf)
	   (if (and (path-equal path (default-directory buf))
		    (eq (buffer-local-value buf 'buffer-mode) 'xdired-mode))
	       buf)))
      (save-window-excursion
	(let ((newBuf (create-new-buffer
		       (let ((dirname (pathname-name path)) s0)
			 (if (= 0 (length dirname))
			     (setq dirname "/"))
			 (cond ((setq s0 (pathname-device path))
				(concat s0 ":" dirname))
			       ((setq s0 (pathname-host path))
				(concat s0
					"/"
					(substitute-string path
							   "^//[^/]*/\\([^/]*\\)\.*"
							   "\\1")
					":"
					dirname))
			       )))))
	  (if newBuf
	      (progn
		(set-buffer newBuf)
		(xdired-mode)
		(if (xdired-load path)
		    newBuf
		  (progn
		    (kill-buffer newBuf)
		    nil))))))))

(defun xdired-find-dir (path &optional cur-item)
  "Visit the directory"
  (let ((newBuf (xdired--find-directory path)))
    (if newBuf
	(let ((curBuf (selected-buffer)))
	  (set-buffer newBuf)
	  (xdired-goto-filename (or cur-item 1))
	  (if (and *xdired-single-buffer*
		   (not (eq newBuf curBuf))
		   (eq (buffer-local-value curBuf 'buffer-mode) 'xdired-mode))
	      (kill-buffer curBuf))))))

(defun xdired-find-dir-other-window (path &optional cur-item)
  "Visit the directory, in another window."
  (let ((newBuf (xdired--find-directory path)))
    (if newBuf
	(progn
	  (switch-to-buffer-other-window newBuf)
	  (xdired-goto-filename (or cur-item 1))))))

(defun xdired-get-filename ()
  "Get filename on the current item"
  (if (<= (current-line-number) 2)
      nil
    (save-excursion
      (let ((eol (progn (goto-eol) (point))))
	(if (< eol (point-max))
	    (buffer-substring (progn (goto-column *xdired-file-name-column*) (point)) eol)
	  nil)))))

(defun xdired-get-marked-files (&optional (markch "*"))
  "Get marked items"
  (let ((result))
    (save-excursion
      (goto-char (point-min))
      (next-line 2)
      (while (not (progn (goto-eol) (eobp)))
	(if (string= (buffer-substring (progn (goto-bol) (point)) (1+ (point))) markch)
	    (setq result (append result (list (xdired-get-filename)))))
	(next-line)))
    result))

(defun xdired-get-marked-or-current (&optional (markch "*"))
  "Get marked items or the current item."
  (or (xdired-get-marked-files markch)
      (let ((fn (xdired-get-filename))) (if fn (list fn)))))

(defun xdired-get-marked-files-list ()
  "Get marked items list"
  (let ((result))
    (save-excursion
      (goto-char (point-min))
      (next-line 2)
      (while (not (progn (goto-eol) (eobp)))
	(let ((m (buffer-substring (progn (goto-bol) (point)) (1+ (point)))))
	  (unless (string= m " ")
	    (setq result (append result (list (list (xdired-get-filename) m))))))
	(next-line)))
    result))

(defun xdired-set-sort-next ()
  "Toggle sort order"
  (setq *xdired-sort-order*
	(let ((next (cadr (member-if #'(lambda (item) (eq item *xdired-sort-order*))
				     *xdired-sort-functions*))))
	  (or next
	      (car *xdired-sort-functions*)))))

(defun xdired-sort ()
  "Sort"
  (unless *xdired-sort-order*
    (unless (setq *xdired-sort-order* (car *xdired-sort-functions*))
      (quit)))
  (let ((header) (lines)
	(cur-item (xdired-get-filename)))
    (setq header (buffer-substring (progn (goto-char (point-min)) (point)) (progn (next-line 1) (goto-eol) (point))))
    (next-line)
    (while (not (progn (goto-eol) (eobp)))
      (let ((eol (point)))
	(setq lines (append lines (list (xdired-detail-line-to-values (buffer-substring (progn (goto-bol) (point)) eol))))))
      (next-line))
    (setq lines (sort lines (cadr *xdired-sort-order*)))
    (setq buffer-read-only nil)
    (erase-buffer (selected-buffer))
    (insert header "\n")
    (mapc #'(lambda (line) (insert (xdired-format-detail-line line) "\n")) lines)
    (set-buffer-modified-p nil)
    (setq buffer-read-only t)
    (xdired-goto-filename (or cur-item 1))))

(defun xdired-get-target-directory ()
  "Get the target directory."
  (if (= 1 (count-windows))
      (default-directory)
    (or (save-window-excursion
	  (let ((orig-win (selected-window)))
	    (other-window 1)
	    (while (not (eq (selected-window) orig-win))
	      (if (eql buffer-mode 'xdired-mode)
		  (return (default-directory)))
	      (other-window 1))))
	(default-directory))))

(defun xdired-apply-lines (point-start point-end test-function do-function)
  "Apply functions"
  (let ((result 0))
    (setq buffer-read-only nil)
    (save-excursion
      (goto-char point-start)
      (if (<= (current-line-number) 2)
	  (next-line (- 3 (current-line-number))))
      (while (and (< (progn (goto-bol) (point)) point-end)
		  (not (progn (goto-eol) (eobp))))
	(if (if (functionp test-function) (funcall test-function) t)
	    (if (funcall do-function)
		(setq result (1+ result))))
	(next-line)))
    (setq buffer-read-only t)
    (set-buffer-modified-p nil)
    result))

(defun xdired-mark-current-line (&optional (markch "*") unmarkch)
  "Mark the current line."
  (goto-bol)
  (let ((new (if unmarkch
		 (let ((old (buffer-substring (point) (1+ (point)))))
		   (cond ((string= old markch) unmarkch)
			 ((string= old unmarkch) markch)))
	       markch)))
    (if new (progn (delete-char 1) (insert new)))))

(defun xdired--mark (markch &optional (move-function 'next-line))
  (cond ((pre-selection-p)
	 (xdired-apply-lines
	  (min (selection-mark) (selection-point))
	  (max (selection-mark) (selection-point))
	  nil
	  #'(lambda () (xdired-mark-current-line markch))))
	((= 1 (current-line-number))
	 (xdired-apply-lines
	  (point-min) (point-max)
	  nil
	  #'(lambda () (xdired-mark-current-line markch))))
	((< 2 (current-line-number))
	 (if (save-excursion
	       (if (< (progn (goto-eol) (point)) (point-max))
		   (progn
		     (setq buffer-read-only nil)
		     (xdired-mark-current-line markch)
		     (setq buffer-read-only t)
		     (set-buffer-modified-p nil)
		     t)))
	     (funcall move-function)))))

(defun xdired-format-header-line (path)
  "header line string"
  (let ((diskinfo (multiple-value-list (get-disk-usage path))))
    (format nil "  ~A\n  total used in directory ~:d available ~:d\n"
	    (map-slash-to-backslash path)
	    (nth 4 diskinfo)
	    (nth 2 diskinfo))))

(defun xdired-format-file-attribute (attr)
  "attribute value to string"
  (concat
   (if (< 0 (logand attr ed::*file-attribute-directory*)) "d" "-")
   (if (< 0 (logand attr ed::*file-attribute-archive*)) "a" "-")
   (if (< 0 (logand attr ed::*file-attribute-system*)) "s" "-")
   (if (< 0 (logand attr ed::*file-attribute-readonly*)) "r" "-")
   (if (< 0 (logand attr ed::*file-attribute-hidden*)) "h" "-")
   (if (< 0 (logand attr ed::*file-attribute-compressed*)) "c" "-")))

(defun xdired-attribute-string-to-value (attrstr)
  "attribute string to value"
  (+ (if (string-match "d" attrstr) ed::*file-attribute-directory* 0)
     (if (string-match "a" attrstr) ed::*file-attribute-archive* 0)
     (if (string-match "s" attrstr) ed::*file-attribute-system* 0)
     (if (string-match "r" attrstr) ed::*file-attribute-readonly* 0)
     (if (string-match "h" attrstr) ed::*file-attribute-hidden* 0)
     (if (string-match "c" attrstr) ed::*file-attribute-compressed* 0)))

(defun xdired-format-detail-line (item)
  "(directory)'s values to string"
  (format nil "~1A ~6A ~12A ~19A ~A"
	  (or (nth 5 item) "") ;; mark
	  (xdired-format-file-attribute (nth 1 item)) ;; attribute
	  (let ((size (nth 3 item))) ;; size
	    (cond ((< 0 (logand (nth 1 item) ed::*file-attribute-directory*))
		   "")
		  ((numberp size)
		   (cond ((<= 100000000000 size)
			  (format nil "~:DM" (ceiling size 1000000)))
			 ((<= 100000000 size)
			  (format nil "~:DK" (ceiling size 1000)))
			 (t
			  (format nil "~:D" size))))
		  (t "")))
	  (format-date-string "%Y-%m-%d %H:%M:%S" (nth 2 item)) ;; datetime
	  (nth 0 item) ;; file name
	  ))

(defun xdired-detail-line-to-values (line)
  "Detail line string to (directory)'s values"
  (let ((items (split-string line #\  nil)))
    (if (< 1 (length (nth 0 items)))
	(setq items (append (list "") items)))
    (if (char= (char (nth 1 items) 0) #\d)
	(setq items (append (list (car items) (cadr items) 0)
			    (cddr items))))
    (list (substring line *xdired-file-name-column*) ;; file name
	  (xdired-attribute-string-to-value (nth 1 items)) ;; attribute
	  (let ((da (mapcar 'parse-integer (split-string (nth 3 items) "-")))
		(tm (mapcar 'parse-integer (split-string (nth 4 items) ":"))))
	    (encode-universal-time (nth 2 tm) (nth 1 tm) (nth 0 tm) (nth 2 da) (nth 1 da) (nth 0 da)))
	  (let ((size (nth 2 items)))
	    (cond ((not (stringp size)) 0)
		  ((string-match "[Kk]$" size)
		   (* 1000 (parse-integer (substitute-string size "[,Kk]" ""))))
		  ((string-match "[Mm]$" size)
		   (* 1000000 (parse-integer (substitute-string size "[,Mm]" ""))))
		  (t
		   (parse-integer (substitute-string size "," "")))))
	  nil
	  (nth 0 items) ;; mark
	  )))

(defun xdired-copy (items dest)
  "Copy files"
  (let ((succeed 0) (ovr))
    (mapc #'(lambda (item)
	      (cond ((file-directory-p item)
		     (let ((rc))
		       (multiple-value-setq (rc ovr) (xdired-copy-directory (truename item) (merge-pathnames item dest) ovr))
		       (setq succeed (+ succeed rc))))
		    ((file-exist-p item)
		     (let ((ovr1 ovr))
		       (loop
			 (let ((errmsg))
			   (if (handler-case
				   (copy-file (truename item) (merge-pathnames item dest) :if-exists ovr1 :if-access-denied :error)
				 (error (c)
				   (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
				   nil))
			       (progn
				 (setq succeed (1+ succeed))
				 (return t))
			     (progn
			       (message "[~A] Copy~A ~A" (format-date-string "%H:%M:%S") (if (eql ovr1 :overwrite) "(ovr)" "") item)
			       (case (xdired-y-or-!-or-n-p (concat (or errmsg "Copy failed.") " Retry? "))
				 (:YES (setq ovr1 :overwrite))
				 (:ALL (setq ovr (setq ovr1 :overwrite)))
				 (t (return nil)))))))))))
	  items)
    (if (< 0 succeed)
	(progn
	  (xdired--reload-directory)
	  (if (not (path-equal dest (default-directory)))
	      (xdired-reload-directory dest))
	  (message "~D item~A copied." succeed (if (< 1 succeed) "s" "")))
      (message "No copies performed"))))

(defun xdired-copy-directory (path dest ovr)
  "Copy the directory; *recursive*"
  (let ((succeed 0))
    (if (null ovr) (setq ovr :error))
    (mapc #'(lambda (dir)
	      (if (handler-case
		      (create-directory (merge-pathnames dir dest) :if-exists :skip)
		    (error (c)
		      nil))
		  (let ((rc))
		    (multiple-value-setq (rc ovr) (xdired-copy-directory (merge-pathnames dir path) (merge-pathnames dir dest) ovr))
		    (setq succeed (+ succeed rc)))))
	  (directory path :directory-only t))
    (do-events)
    (mapc #'(lambda (file)
	      (let ((ovr1 ovr))
		(loop
		  (let ((errmsg))
		    (if (handler-case
			    (copy-file (merge-pathnames file path) (merge-pathnames file dest) :if-exists ovr :if-access-denied :error)
			  (error (c)
			    (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
			    nil))
			(progn
			  (setq succeed (1+ succeed))
			  (return t))
		      (progn
			(message "[~A] Copy~A ~A" (format-date-string "%H:%M:%S") (if (eql ovr :overwrite) "(ovr)" "") file)
			(case (xdired-y-or-!-or-n-p (concat (or errmsg "Copy failed.") " Retry? "))
			  (:YES (setq ovr1 :overwrite))
			  (:ALL (setq ovr (setq ovr1 :overwrite)))
			  (t (return nil)))))))))
	  (directory path :file-only t))
    (values succeed ovr)))

(defun xdired--delete (items recycle)
  "Delete all marked files, or the current file."
  (if (< 0 (length items))
      (if (y-or-n-p (concat (if recycle "Recycle " "Delete ")
			    (if (= 1 (length items))
				(car items)
			      (format nil "[~D items]" (length items)))
			    " "))
	  (xdired-delete items recycle))))

(defun xdired-delete (items recycle)
  "Delete itesm."
  (if (= 0 (length items)) (quit))
  (let ((succeed 0) (force :error))
    (mapc #'(lambda (item)
	      (cond ((file-directory-p item)
		     (let ((rc) (rd))
		       (multiple-value-setq (rc rd force) (xdired-delete-directory (truename item) recycle force))
		       (setq succeed (+ succeed rc))))
		    ((file-exist-p item)
		     (let ((force1 force))
		       (loop
			 (let ((errmsg))
			   (if (handler-case
				   (if recycle
				       (delete-file (truename item) :if-does-not-exist :error :if-access-denied force1 :recycle recycle)
				     (delete-file (truename item) :if-does-not-exist :error :if-access-denied force1))
				 (error (c)
				   (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
				   nil))
			       (progn
				 (setq succeed (1+ succeed))
				 (return t))
			     (progn
			       (message "[~A] ~A ~A" (format-date-string "%H:%M:%S") (if recycle "Recycle" "Delete") item)
			       (case (xdired-y-or-!-or-n-p (concat (or errmsg "Deletion failed.") " Retry? "))
				 (:YES (setq force1 :force))
				 (:ALL (setq force (setq force1 :force)))
				 (t (return nil)))))))))))
	  items)
    (if (< 0 succeed)
	(progn
	  (xdired--reload-directory)
	  (message "~D item~A ~A." succeed (if (< 1 succeed) "s" "") (if recycle "recycled" "deleted")))
      (message "No deletions performed"))))

(defun xdired-delete-directory (path recycle force)
  "Delete the directory; *recursive*"
  (let ((succeed 0) (delmyself t))
    (mapc #'(lambda (dir)
	      (let ((rc) (rd))
		(multiple-value-setq (rc rd force) (xdired-delete-directory (merge-pathnames dir path) recycle force))
		(if (null rd) (setq delmyself nil))
		(setq succeed (+ succeed rc))))
	  (directory path :directory-only t))
    (do-events)
    (mapc #'(lambda (file)
	      (let ((filepath (merge-pathnames file path))
		    (force1 force))
		(unless (loop
			  (let ((errmsg))
			    (if (file-exist-p filepath)
				(if (handler-case
					(if recycle
					    (delete-file filepath :if-does-not-exist :error :if-access-denied force1 :recycle recycle)
					  (delete-file filepath :if-does-not-exist :error :if-access-denied force1))
				      (error (c)
					(setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
					nil))
				    (progn
				      (setq succeed (1+ succeed))
				      (return t))
				  (progn
				    (message "[~A] ~A ~A" (format-date-string "%H:%M:%S") (or recycle "Recycle" "Delete") filepath)
				    (case (xdired-y-or-!-or-n-p (concat (or errmsg "Deletion failed.") " Retry? "))
				      (:YES (setq force1 :force))
				      (:ALL (setq force (setq force1 :force)))
				      (t (return nil)))))
			      (return t))))
		  (setq delmyself nil))))
	  (directory path :file-only t))
    (if delmyself
	(let ((force1 force))
	  (if (loop
		(let ((errmsg))
		  (if (file-directory-p path)
		      (if (handler-case
			      (delete-directory path :if-does-not-exist :error :if-access-denied force1)
			    (error (c)
			      (setq errmsg (substitute-string (si:*condition-string c) "^.*\n" ""))
			      nil))
			  (return t)
			(progn
			  (message "[~A] rmdir: ~A" (format-date-string "%H:%M:%S") path)
			  (case (xdired-y-or-!-or-n-p (concat (or errmsg "Deletion failed.") " Retry? "))
			    (:YES (setq force1 :force))
			    (:ALL (setq force (setq force1 :force)))
			    (t (return nil)))))
		    (return t))))
	      (setq succeed (1+ succeed))
	    (setq delmyself nil))))
    (values succeed delmyself force)))

(defun xdired-datetime-prompt (prompt old &optional errmsg)
  "DateTime prompt"
  (loop
    (let ((newstr (split-string
		   (read-string prompt
				:default (if old (format-date-string "%Y-%m-%d %H:%M:%S" old) ""))
		   " -:/.")))
      (if (= 6 (length newstr))
	  (let ((new (handler-case
			 (encode-universal-time (parse-integer (nth 5 newstr))
						(parse-integer (nth 4 newstr))
						(parse-integer (nth 3 newstr))
						(parse-integer (nth 2 newstr))
						(parse-integer (nth 1 newstr))
						(parse-integer (nth 0 newstr)))
		       (error (c)
			 (if errmsg (message errmsg))
			 nil))))
	    (if new (return new)))
	(return nil)))))

(defun xdired-chmod-operation (opr old)
  "Operands for chmod on FAT/NTFS"
  (let ((pn) (new old))
    (if (dotimes (i (length opr) t)
	  (let ((ch (char opr i)))
	    (case ch
	      (#\  nil)
	      (#\+ (setq pn #\+))
	      (#\- (setq pn #\-))
	      (t (case pn
		   (#\+
		     (case ch
		       ((#\a #\A) (setq new (logior new ed::*file-attribute-archive*)))
		       ((#\h #\H) (setq new (logior new ed::*file-attribute-hidden*)))
		       ((#\r #\R) (setq new (logior new ed::*file-attribute-readonly*)))
		       ((#\s #\S) (setq new (logior new ed::*file-attribute-system*)))
		       (t (return nil))))
		   (#\-
		     (case ch
		       ((#\a #\A) (setq new (logand new (lognot ed::*file-attribute-archive*))))
		       ((#\h #\H) (setq new (logand new (lognot ed::*file-attribute-hidden*))))
		       ((#\r #\R) (setq new (logand new (lognot ed::*file-attribute-readonly*))))
		       ((#\s #\S) (setq new (logand new (lognot ed::*file-attribute-system*))))
		       (t (return nil))))
		   (t (return nil)))))))
	new
      nil)))

(defun xdired-y-or-!-or-n-p (msg)
  "miniprompt for y-or-!-or-n"
  (interactive)
  (minibuffer-prompt "~A (y,! or n) " msg)
  (loop
    (case (read-char *keyboard*)
      ((#\y #\Y) (return :YES))
      ((#\n #\N) (return nil))
      (#\! (return :ALL))
      (#\C-g (quit)))))

(defun xdired-read-send-to-folder ()
  "Convert \"SendTo\" folder contents to *xdired-send-to-list*"
  (remove-if
   'null
   (let ((send-to-path (get-special-folder-location :send-to)))
     (mapcar #'(lambda (item)
		 (if (string-match "\\.lnk$" item)
		     (list (substitute-string (pathname-name item) " *" "")
			   (merge-pathnames item send-to-path))))
	     (directory send-to-path :show-dots nil)))))

;;; xdired.l ends here
