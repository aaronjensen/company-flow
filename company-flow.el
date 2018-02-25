;;; company-flow.el --- Flow backend for company-mode  -*- lexical-binding: t -*-

;; Copyright (C) 2016 by Aaron Jensen

;; Author: Aaron Jensen <aaronjensen@gmail.com>
;; URL: https://github.com/aaronjensen/company-flow
;; Version: 0.1.0
;; Package-Requires: ((company "0.8.0") (dash "2.13.0"))

;;; Commentary:

;; This package adds support for flow to company. It requires
;; flow to be in your path.

;; To use it, add to your company-backends:

;;   (eval-after-load 'company
;;     '(add-to-list 'company-backends 'company-flow))

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'company)
(require 'dash)

(defgroup company-flow ()
  "Flow company backend."
  :group 'company
  :prefix "company-flow-")

(defcustom company-flow-executable "flow"
  "Flow executable to run."
  :group 'company-flow
  :type 'string)
(make-variable-buffer-local 'company-flow-executable)

(defcustom company-flow-modes '(
                                js-mode
                                js-jsx-mode
                                js2-mode
                                js2-jsx-mode
                                rjsx-mode
                                web-mode
                                )
  "List of major modes where company-flow will be providing completions."
  :type '(choice (const :tag "All" nil)
                 (repeat (symbol :tag "Major mode")))
  :group 'company-flow)

(defun company-flow--handle-signal (process _event)
  (when (memq (process-status process) '(signal exit))
    (let ((callback (process-get process 'company-flow-callback))
          (prefix (process-get process 'company-flow-prefix)))
      (if (and (eq (process-status process) 'exit)
               (eq (process-exit-status process) 0))
          (funcall callback (->> process
                                 company-flow--get-output
                                 company-flow--parse-output
                                 ;; Remove nils
                                 (--filter it)))
        (funcall callback nil)))))

(defun company-flow--make-candidate (line)
  "Creates a candidate with a meta property from LINE.

LINE is expected to look like:
registrationSuccess () => {type: 'REGISTRATION_SUCCESS'}"
  (let ((first-space (string-match " " line)))
    (when first-space
      (let ((text (substring line 0 first-space))
            (meta (substring line (+ 1 first-space))))
        (propertize text 'meta meta)))))

(defun company-flow--parse-output (output)
  (when (not (equal output "Error: not enough type information to autocomplete\n"))
    (mapcar 'company-flow--make-candidate
            (split-string output "\n"))))

(defun company-flow--get-output (process)
  "Get the complete output of PROCESS."
  (with-demoted-errors "Error while retrieving process output: %S"
    (let ((pending-output (process-get process 'company-flow-pending-output)))
      (apply #'concat (nreverse pending-output)))))

(defun company-flow--receive-checker-output (process output)
  "Receive a syntax checking PROCESS OUTPUT."
  (push output (process-get process 'company-flow-pending-output)))

(defun company-flow--process-send-buffer (process)
  "Send all contents of current buffer to PROCESS.

Sends all contents of the current buffer to the standard input of
PROCESS, and terminates standard input with EOF."
  (save-restriction
    (widen)
    (process-send-region process (point-min) (point-max)))
  ;; flow requires EOF be on its own line
  (process-send-string process "\n")
  (process-send-eof process))

(defun company-flow--candidates-query (prefix callback)
  (let* ((line (line-number-at-pos (point)))
         (col (+ 1 (current-column)))
         (command (list (executable-find company-flow-executable)
                        "autocomplete"
                        "--quiet"
                        buffer-file-name
                        (number-to-string line)
                        (number-to-string col)))
         (process-connection-type nil)
         (process (apply 'start-process "company-flow" nil command)))
    (set-process-sentinel process #'company-flow--handle-signal)
    (set-process-filter process #'company-flow--receive-checker-output)
    (process-put process 'company-flow-callback callback)
    (process-put process 'company-flow-prefix prefix)
    (company-flow--process-send-buffer process)))

(defun company-flow--prefix ()
  "Grab prefix for flow."
  (and (or (null company-flow-modes)
           (-contains? company-flow-modes major-mode))
       company-flow-executable
       (executable-find company-flow-executable)
       buffer-file-name
       (file-exists-p buffer-file-name)
       (not (company-in-string-or-comment))
       (locate-dominating-file buffer-file-name ".flowconfig")
       (or (company-grab-symbol-cons "\\." 1)
           'stop)))

(defun company-flow--annotation (candidate)
  (format " %s" (get-text-property 0 'meta candidate)))

(defun company-flow--meta (candidate)
  (format "%s: %s" candidate (get-text-property 0 'meta candidate)))

(defvar-local company-flow--debounce-state nil)

(defun company-flow--debounce-callback (prefix callback)
  (lambda (candidates)
    (let ((current-prefix (car company-flow--debounce-state))
          (current-callback (cdr company-flow--debounce-state)))
      (when (and current-prefix
                 (company-flow--string-prefix-p prefix current-prefix))
        (setq company-flow--debounce-state nil)
        (funcall current-callback (all-completions current-prefix candidates))))))

(defun company-flow--prefix-to-string (prefix)
  "Return a string or nil from a prefix.
  `company-grab-symbol-cons' can return (\"prefix\" . t) or just
  \"prefix\", but we only care about the string."
  (if (consp prefix)
      (car prefix)
    prefix))

(defun company-flow--string-prefix-p (a b)
  (string-prefix-p (company-flow--prefix-to-string a) (company-flow--prefix-to-string b)))

(defun company-flow--debounce-async (prefix candidate-fn)
  "Return a function that will properly debounce candidate queries by comparing the
in-flight query's prefix to PREFIX. CANDIDATE-FN should take two arguments, PREFIX
and the typical async callback.

Note that the candidate list provided to the callback by CANDIDATE-FN will be
filtered via `all-completions' with the most current prefix, so it is not necessary
to do this filtering in CANDIDATE-FN.

Use like:

  (cons :async (company-flow--debounce-async arg 'your-query-fn))"
  (lambda (callback)
    (let ((current-prefix (car company-flow--debounce-state)))
      (unless (and current-prefix
                   (company-flow--string-prefix-p prefix current-prefix))
        (funcall candidate-fn prefix (company-flow--debounce-callback prefix callback)))
      (setq company-flow--debounce-state (cons (company-flow--prefix-to-string prefix) callback)))))

;;;###autoload
(defun company-flow (command &optional arg &rest _args)
  (interactive (list 'interactive))
  (pcase command
    (`interactive (company-begin-backend 'company-flow))
    (`prefix (company-flow--prefix))
    (`annotation (company-flow--annotation arg))
    (`meta (company-flow--meta arg))
    (`sorted t)
    (`candidates (cons :async (company-flow--debounce-async arg 'company-flow--candidates-query)))))

(provide 'company-flow)
;;; company-flow.el ends here
