;;; -*- Mode: Lisp; Package: xtared -*-
;;; This file is not part of xyzzy.
;;; 
;;; pseudo tar ball editor for xyzzy
;;; written by EXCWSM 2022
;;;
;;; usage:
;;;   (require "xtared")
;;;   (global-set-key '(#\C-x #\t #\z) 'xtared)

(provide "xtared")

(defpackage "xtared"
  (:use "lisp" "system" "editor")
  (:internal-size 137)
  (:external-size 7))
(use-package "xtared")
(in-package "xtared")

(export '(*xtared-map*
	  *xtared-color-keywords*
	  xtared
	  xtared-other-window
	  ))

(defvar *xtared-map* nil "Keymap for xtared-mode")
(unless *xtared-map*
  (setf *xtared-map* (make-sparse-keymap))
  (define-key *xtared-map* '(#\ESC #\C-h) 'xtared-unmark-all-files)
  (define-key *xtared-map* #\M-C-h 'xtared-unmark-all-files)
  (define-key *xtared-map* #\C-h 'xtared-unmark-backward)
  (define-key *xtared-map* #\RET 'xtared-find-file)
  (define-key *xtared-map* #\SPC 'next-line)
  (define-key *xtared-map* #\A 'xtared-do-add)
  (define-key *xtared-map* #\C 'xtared-do-extract)
  (define-key *xtared-map* #\d 'xtared-flag)
  (define-key *xtared-map* #\D 'xtared-do-delete)
  (define-key *xtared-map* #\g 'xtared-reload)
  (define-key *xtared-map* #\m 'xtared-mark)
  (define-key *xtared-map* #\n 'next-line)
  (define-key *xtared-map* #\o 'xtared-find-file-other-window)
  (define-key *xtared-map* #\p 'previous-line)
  (define-key *xtared-map* #\q #'(lambda () (interactive) (delete-buffer (selected-buffer))))
  (define-key *xtared-map* #\s 'xtared-sort-next)
  (define-key *xtared-map* #\t 'xtared-toggle-marks)
  (define-key *xtared-map* #\u 'xtared-unmark)
  (define-key *xtared-map* #\U 'xtared-unmark-all-marks)
  (define-key *xtared-map* #\v 'xtared-find-file)
  (define-key *xtared-map* #\x 'xtared-do-flagged-delete)
  (define-key *xtared-map* #\Z 'xtared-do-extract-all)
  (define-key *xtared-map* '(#\ESC #\=) 'xtared-count-items)
  (define-key *xtared-map* #\M-= 'xtared-count-items)
  (define-key *xtared-map* '(#\* #\.) 'xtared-mark-extension)
  (define-key *xtared-map* '(#\* #\*) 'xtared-mark-executables)
  (define-key *xtared-map* '(#\* #\/) 'xtared-mark-directories)
  (define-key *xtared-map* '(#\* #\c) 'xtared-change-marks)
  (define-key *xtared-map* '(#\% #\m) 'xtared-mark-regexp)
  )

(defvar *xtared-color-keywords*
  '(("^  [\-A]S[\-R][\-H]" nil (:color 10 0 :line))
    ("^  [\-A][\-S][\-R]H" nil (:color 10 0 :line))
    ("^\*" nil (:keyword 1 :bold :line))
    ("^D" nil (:color 0 1 :bold :line))
    )
  "Color keywords for xtared-mode")

(defvar *xtared-sort-functions*
  (list (list "name"
	      #'(lambda (item1 item2)
		  (string-lessp (nth 0 item1) (nth 0 item2))))
	(list "date"
	      #'(lambda (item1 item2)
		  (let ((i1d (nth 3 item1))
			(i2d (nth 3 item2)))
		    (setq i1d (+ (* (nth 0 i1d) 10000000000)
				 (* (nth 1 i1d) 100000000)
				 (* (nth 2 i1d) 1000000)
				 (* (nth 3 i1d) 10000)
				 (* (nth 4 i1d) 100)
				 (nth 5 i1d)))
		    (setq i2d (+ (* (nth 0 i2d) 10000000000)
				 (* (nth 1 i2d) 100000000)
				 (* (nth 2 i2d) 1000000)
				 (* (nth 3 i2d) 10000)
				 (* (nth 4 i2d) 100)
				 (nth 5 i2d)))
		    (if (= i1d i2d)
			(string-lessp (nth 0 item1) (nth 0 item2))
		      (< i1d i2d)))))
	(list "size"
	      #'(lambda (item1 item2)
		  (let ((i1s (nth 2 item1))
			(i2s (nth 2 item2)))
		    (if (= i1s i2s)
			(string-lessp (nth 0 item1) (nth 0 item2))
		      (< i1s i2s))))))
  "Sort functions")

;;======================================================================
;;
;;  interactives
;;
;;======================================================================

(defun xtared (afile)
  "xtared"
  (interactive "fxTared: ")
  (let ((buf (xtared--find-archive afile)))
    (if buf (switch-to-buffer buf))))

(defun xtared-other-window (afile)
  "xtared in another window"
  (interactive "fxTared: ")
  (let ((buf (xtared--find-archive afile)))
    (if buf (switch-to-buffer-other-window buf))))

(defun xtared-mark ()
  "Mark *"
  (interactive)
  (xtared--mark "*"))

(defun xtared-flag ()
  "Mark D"
  (interactive)
  (xtared--mark "D"))

(defun xtared-unmark ()
  "Unmark the current item or all items"
  (interactive)
  (xtared--mark " "))

(defun xtared-unmark-backward ()
  "Unmark the current item"
  (interactive)
  (xtared--mark " " 'previous-line))

(defun xtared-unmark-all-marks ()
  "Remove all marks"
  (interactive)
  (xtared-apply-lines
   (point-min) (point-max)
   nil
   #'(lambda () (xtared-mark-current-line " "))))

(defun xtared-toggle-marks (&optional (markch "*"))
  "Toggle marks: marked files become unmarked, vice versa."
  (interactive)
  (xtared-apply-lines
   (point-min) (point-max)
   nil
   #'(lambda () (xtared-mark-current-line markch " "))))

(defun xtared-mark-regexp (regexp)
  "Mark all items matching regexp for use in later commands."
  (interactive "sMark files (regexp): ")
  (if (< 0 (length regexp))
      (let ((re (compile-regexp regexp t)))
	(message "~:D matching items marked"
		 (xtared-apply-lines
		  (point-min) (point-max)
		  #'(lambda () (string-match re (xtared-get-filename)))
		  #'xtared-mark-current-line)))))

(defun xtared-mark-extension (ext)
  "Mark all items with a certain extension for use in later commands."
  (interactive "sMark extension: ")
  (if (< 0 (length ext))
      (let ((re-ext (compile-regexp (format nil "\\.~A$" (quote-string ext #\. #\\)) t)))
	(message "~:D matching items marked"
		 (xtared-apply-lines
		  (point-min) (point-max)
		  #'(lambda () (string-match re-ext (xtared-get-filename)))
		  #'xtared-mark-current-line)))))

(defun xtared-mark-directories ()
  "Mark all directories for use in later commands."
  (interactive)
  (message "~:D directory items marked"
	   (xtared-apply-lines
	    (point-min) (point-max)
	    #'(lambda () (let ((ch (char (buffer-substring (progn (goto-eol) (- (point) 1)) (point)) 0)))
			   (or (char= ch #\\) (char= ch #\/))))
	    #'xtared-mark-current-line)))

(defun xtared-mark-executables ()
  "Mark all executable files for use in later commands."
  (interactive)
  (let ((re (compile-regexp "\\.exe$" t)))
    (message "~:D matching items marked"
	     (xtared-apply-lines
	      (point-min) (point-max)
	      #'(lambda () (string-match re (xtared-get-filename)))
	      #'xtared-mark-current-line))))

(defun xtared-change-marks (&optional old new)
  "Change all #\\old marks to #\\new marks."
  (interactive)
  (unless old (setq old (progn (minibuffer-prompt "Change (old mark)") (read-char *keyboard*))))
  (if (eq old #\C-g) (quit))
  (unless new (setq new (progn (minibuffer-prompt "Change ~C marks to (new mark)" old) (read-char *keyboard*))))
  (if (eq new #\C-g) (quit))
  (if (and (not (eq old new)) (characterp old) (characterp new))
    (progn
      (setq new (string new))
      (xtared-apply-lines
       (point-min) (point-max)
       #'(lambda () (char= (char (buffer-substring (progn (goto-bol) (point)) (1+ (point))) 0) old))
       #'(lambda () (xtared-mark-current-line new))))))

(defun xtared-unmark-all-files (&optional markch)
  "Remove a specific mark from every file."
  (interactive)
  (unless markch (setq markch (progn (minibuffer-prompt "Remove marks (RET means all):") (read-char *keyboard*))))
  (if (or (null markch) (char= markch #\C-g)) (quit))
  (let ((test-func (if (char= markch #\RET)
		       nil
		     #'(lambda () (char= (char (buffer-substring (progn (goto-bol) (point)) (1+ (point))) 0) markch)))))
    (xtared-apply-lines
     (point-min) (point-max)
     test-func
     #'(lambda () (xtared-mark-current-line " ")))))

(defun xtared-sort-next ()
  "Toggle sort order."
  (interactive)
  (xtared-set-sort-next)
  (xtared--sort)
  (xtared-set-mode-name))

(defun xtared-reload ()
  "Reload"
  (interactive)
  (let ((marklist) (eol))
    (save-excursion
      (goto-char (point-min))
      (next-line 2)
      (while (< (setq eol (progn (goto-eol) (point))) (point-max))
	(let ((m (buffer-substring (progn (goto-bol) (point)) (1+ (point)))))
	  (unless (string= m " ")
	    (setq marklist (append marklist (list (list (buffer-substring (progn (goto-column *xtared-file-name-column*) (point)) eol) m))))))
	(next-line)))
    (xtared-load (get-buffer-alternate-file-name) marklist)))

(defun xtared-do-add (file)
  "Add to archive file"
  (interactive "fAdd file: ")
  (if (create-archive (get-buffer-alternate-file-name) (list file) (directory-namestring file))
      (xtared-reload)))

(defun xtared-do-extract ()
  "Extract all marked files, or copy the current file."
  (interactive)
  (let ((items (xtared-get-marked-or-current)))
    (if (= 0 (length items)) (quit))
    (message "~A" (get-buffer-alternate-file-name))
    (let ((dest (read-directory-name (concat "Extract "
					     (if (= 1 (length items)) (car items) (format nil "[~D items]" (length items)))
					     " to: ")
				     :default (default-directory))))
      (long-operation (apply 'extract-archive (append (list (get-buffer-alternate-file-name) (truename dest)) items))))))

(defun xtared-do-extract-all ()
  "Extract all files."
  (interactive)
  (message "~A" (get-buffer-alternate-file-name))
  (let ((dest (read-directory-name "Extract [ALL] to: "
				   :default (default-directory))))
    (long-operation (extract-archive (get-buffer-alternate-file-name) (truename dest)))))

(defun xtared-do-delete ()
  "Delete the current file."
  (interactive)
  (let ((fn (xtared-get-filename)))
    (if fn (xtared--delete (list fn)))))

(defun xtared-do-flagged-delete ()
  "Delete all flagged files"
  (interactive)
  (xtared--delete (xtared-get-marked-files "D")))

(defun xtared-count-items (&optional (markch "*"))
  "Count the number of items."
  (interactive)
  (let ((point-start) (point-end) (test-funcion)
	(total-bytes 0))
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
    (let ((total-items
	   (xtared-apply-lines
	    point-start point-end
	    test-function
	    #'(lambda ()
		(let ((item (xtared-detail-line-to-values (buffer-substring (progn (goto-bol) (point)) (progn (goto-eol) (point))))))
		  (setq total-bytes (+ (nth 2 item) total-bytes)))))))
      (message "~A ~:D items ~:D bytes."
	       (if (pre-selection-p)
		   "Selection has"
		 (concat "\"" markch "\""))
	       total-items total-bytes))))

;;======================================================================
;;
;;  functions
;;
;;======================================================================

(defun xtared--find-archive (afile)
  (setq afile (truename afile))
  (or (enum-buffers
       #'(lambda (buf)
	   (if (and (eql (buffer-local-value buf 'buffer-mode) 'xtared-mode)
		    (path-equal afile (get-buffer-alternate-file-name buf)))
	       buf)))
      (save-window-excursion
	(let ((newBuf (create-new-buffer (file-namestring afile))))
	  (if newBuf
	      (progn
		(set-buffer newBuf)
		(xtared-mode)
		(if (xtared-load afile)
		    newBuf
		  (progn (kill-buffer newBuf) nil))))))))

(defun xtared-mode ()
  "xtared mode"
  (kill-all-local-variables)
  (setup-temp-buffer (selected-buffer))
  (setq buffer-mode 'xtared-mode)
  (use-keymap *xtared-map*)
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list (compile-regexp-keyword-list *xtared-color-keywords*))
  (make-local-variable '*xtared-sort-order*)
  (unless *xtared-sort-order*
    (setq *xtared-sort-order* (car *xtared-sort-functions*)))
  (make-local-variable '*xtared-file-name-column*)
  (setq *xtared-file-name-column* (length (xtared-format-detail-line nil)))
  (make-local-variable 'paragraph-start)
  (setq paragraph-start "^[\\*D] ")
  (xtared-set-mode-name)
  (run-hooks '*xtared-mode-hook*))

(defun xtared-set-mode-name ()
  (setq mode-name (if *xtared-sort-order* (concat "xtared(" (car *xtared-sort-order*) ")")
		    "xtared")))

(defun xtared-load (afile &optional marklist)
  (let ((items))
    (if (handler-case
	    (long-operation (setq items (list-archive afile)))
	  (error (c)
	    (message-box (si:*condition-string c) "(list-archive) failed - xyzzy" '(:ok :exclamation))
	    nil))
	(let ((total 0))
	  (set-buffer-alternate-file-name afile)
	  (set-default-directory (directory-namestring afile))
	  (mapc #'(lambda (item)
		    (setq total (+ total (nth 2 item))))
		(if *xtared-sort-order*
		    (sort items (cadr *xtared-sort-order*))
		  items))
	  (setq buffer-read-only nil)
	  (erase-buffer (selected-buffer))
	  (let ((afile-length (file-length afile)))
	    (insert "  " (map-slash-to-backslash (truename afile)) "\n"
		    (format nil "  archive size is ~:D bytes, contains ~:D bytes.~A\n"
			    afile-length
			    total
			    (if (= 0 total) "" (format nil " (~,2F%)" (* 100 (/ afile-length total)))))))
	  (mapc (if marklist
		    #'(lambda (item)
			(insert (xtared-format-detail-line (append item (list (cadr (assoc (car item) marklist :test 'string=))))) "\n"))
		  #'(lambda (item) (insert (xtared-format-detail-line item) "\n")))
		items)
	  (set-buffer-modified-p nil)
	  (setq buffer-read-only t)
	  t))))

(defun xtared-get-filename ()
  "Get filename on the current item"
  (if (<= (current-line-number) 2)
      nil
    (save-excursion
      (let ((eol (progn (goto-eol) (point))))
	(if (< eol (point-max))
	    (buffer-substring (progn (goto-column *xtared-file-name-column*) (point)) eol)
	  nil)))))

(defun xtared-get-marked-files (&optional (markch "*"))
  "Get marked items"
  (let ((result))
    (save-excursion
      (goto-char (point-min))
      (next-line 2)
      (while (not (progn (goto-eol) (eobp)))
	(if (string= (buffer-substring (progn (goto-bol) (point)) (1+ (point))) markch)
	    (setq result (append result (list (xtared-get-filename)))))
	(next-line)))
    result))

(defun xtared-get-marked-or-current (&optional (markch "*"))
  "Get marked items or the current item."
  (or (xtared-get-marked-files markch)
      (let ((fn (xtared-get-filename))) (if fn (list fn)))))

(defun xtared-find-file ()
  "Visit"
  (interactive)
  (let ((fn (xtared-get-filename)))
    (if (and (stringp fn)
	     (not (string-match "[\\\\/]$" fn)))
	(if (find-file-in-archive (get-buffer-alternate-file-name) fn)
	    (setq buffer-read-only t)))))

(defun xtared-find-file-other-window ()
  (interactive)
  (let ((newBuf (save-window-excursion (if (xtared-find-file) (selected-buffer)))))
    (if newBuf
	(switch-to-buffer-other-window newBuf))))

(defun xtared--delete (items)
  "Delete file in archive"
  (if (and (listp items)
	   (< 0 (length items))
	   (progn
	     (message "~A" (get-buffer-alternate-file-name))
	     (y-or-n-p "Delete ~A ?" (if (= 1 (length items))
					 (car items)
				       (format nil "[~D items]" (length items))))))
      (long-operation (apply 'delete-file-in-archive (append (list (get-buffer-alternate-file-name)) items)))))

(defun xtared-apply-lines (point-start point-end test-function do-function)
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

(defun xtared--mark (markch &optional (move-function 'next-line))
  (cond ((pre-selection-p)
	 (xtared-apply-lines
	  (min (selection-mark) (selection-point))
	  (max (selection-mark) (selection-point))
	  nil
	  #'(lambda () (xtared-mark-current-line markch))))
	((= 1 (current-line-number))
	 (xtared-apply-lines
	  (point-min) (point-max)
	  nil
	  #'(lambda () (xtared-mark-current-line markch))))
	((< 2 (current-line-number))
	 (if (save-excursion
	       (if (< (progn (goto-eol) (point)) (point-max))
		   (progn
		     (setq buffer-read-only nil)
		     (xtared-mark-current-line markch)
		     (setq buffer-read-only t)
		     (set-buffer-modified-p nil)
		     t)))
	     (funcall move-function)))))

(defun xtared-mark-current-line (&optional (markch "*") unmarkch)
  (goto-bol)
  (let ((new (if unmarkch
		 (let ((old (buffer-substring (point) (1+ (point)))))
		   (cond ((string= old markch) unmarkch)
			 ((string= old unmarkch) markch)))
	       markch)))
    (if new (progn (delete-char 1) (insert new)))))

(defun xtared-set-sort-next ()
  "Toggle sort order"
  (setq *xtared-sort-order*
	(let ((next (cadr (member-if #'(lambda (item) (eq item *xtared-sort-order*))
				     *xtared-sort-functions*))))
	  (or next
	      (car *xtared-sort-functions*)))))

(defun xtared--sort ()
  "Sort"
  (unless *xtared-sort-order*
    (unless (setq *xtared-sort-order* (car *xtared-sort-functions*))
      (quit)))
  (let ((header) (items))
    (setq header (buffer-substring (progn (goto-char (point-min)) (point)) (progn (next-line) (goto-eol) (point))))
    (next-line)
    (while (not (progn (goto-eol) (eobp)))
      (let ((eol (point)))
	(setq items (append items (list (xtared-detail-line-to-values (buffer-substring (progn (goto-bol) (point)) eol))))))
      (next-line))
    (setq items (sort items (cadr *xtared-sort-order*)))
    (setq buffer-read-only nil)
    (erase-buffer (selected-buffer))
    (insert header "\n")
    (mapc #'(lambda (item) (insert (xtared-format-detail-line item) "\n")) items)
    (setq buffer-read-only t)
    (set-buffer-modified-p nil)
    (goto-char (point-min))))

(defun xtared-format-detail-line (item)
  (format nil "~1A ~@6A ~12A ~19A ~A"
	  (or (nth 4 item) " ") ;; mark
	  (or (nth 1 item) "") ;; attribute
	  (let ((size (nth 2 item))) ;; size
	    (if (numberp size)
		(cond ((<= 100000000000 size)
		       (format nil "~:DM" (ceiling size 1000000)))
		      ((<= 100000000 size)
		       (format nil "~:DK" (ceiling size 1000)))
		      (t
		       (format nil "~:D" size)))
	      (or (nth 2 item) "")))
	  (let ((datetime (nth 3 item)))
	    (if datetime ;; YYYY-MM-DD HH:MM:SS
		(format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
			(nth 0 datetime) (nth 1 datetime) (nth 2 datetime)
			(nth 3 datetime) (nth 4 datetime) (nth 5 datetime))
	      ""))
	  (or (nth 0 item) "") ;; file name
	  ))

(defun xtared-detail-line-to-values (line)
  (let ((items (split-string line #\  nil)))
    (if (< 1 (length (nth 0 items)))
	(setq items (append (list "") items)))
    (list (substring line *xtared-file-name-column*) ;; file name
	  (nth 1 items) ;; attribute
	  (let ((size (nth 2 items))) ;; size
	    (cond ((not (stringp size)) 0)
		  ((string-match "[Kk]$" size)
		   (* 1000 (parse-integer (substitute-string size "[,Kk]" ""))))
		  ((string-match "[Mm]$" size)
		   (* 1000000 (parse-integer (substitute-string size "[,Mm]" ""))))
		  (t
		   (parse-integer (substitute-string size "," "")))))
	  (append (mapcar 'parse-integer (split-string (nth 3 items) "-/:.")) ;; date
		  (mapcar 'parse-integer (split-string (nth 4 items) "-/:."))) ;; time
	  (nth 0 items) ;; mark
	  )))

;;; xtared.l ends here
