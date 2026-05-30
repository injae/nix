;;; +terminal-test.el --- ERT tests for vterm Korean hangul input -*- lexical-binding: t; -*-
;;; Commentary:
;; Run: M-x ert RET "^\\+vterm" RET
;;; Code:

(require 'ert)
(require 'cl-lib)

;; Declare symbols from +terminal.el and vterm to avoid byte-compile warnings.
(defvar vterm--term nil)
(declare-function +vterm--hangul-flush "+terminal")
(declare-function +vterm--self-insert-with-im "+terminal")
(defvar +vterm--hangul-has-preedit)
(defvar +vterm--hangul-captured)

;;; Helpers

(defmacro +vterm-test--env (&rest body)
  "Run BODY in a temp buffer with Korean vterm state initialized.
Saves and restores global hangul-queue to prevent test pollution."
  (declare (indent 0))
  `(let ((saved-queue (copy-sequence hangul-queue)))
     (unwind-protect
         (with-temp-buffer
           (setq-local vterm--term t)
           (setq-local input-method-function #'hangul2-input-method)
           (setq-local +vterm--hangul-has-preedit nil)
           (setq hangul-queue (make-vector 6 0))
           ,@body)
       (setq hangul-queue saved-queue))))

(defun +vterm-test--press (key orig-fn)
  "Invoke +vterm--self-insert-with-im with KEY as last-command-event."
  (let ((last-command-event key))
    (+vterm--self-insert-with-im orig-fn)))

;;; +vterm--hangul-flush

(ert-deftest +vterm-flush/no-preedit-is-noop ()
  "flush does nothing when has-preedit flag is nil."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-flush))
      (should-not sent)
      (should-not +vterm--hangul-has-preedit))))

(ert-deftest +vterm-flush/sends-preedit-and-resets ()
  "flush sends the preedit char, clears queue and flag."
  (+vterm-test--env
    (setq +vterm--hangul-has-preedit t)
    (aset hangul-queue 0 1)
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul-insert-character)
                 (lambda (&rest _) (self-insert-command 1 ?가))))
        (+vterm--hangul-flush))
      (should (equal sent '("가")))
      (should-not +vterm--hangul-has-preedit)
      (should (seq-every-p #'zerop hangul-queue)))))

;;; Backspace behavior

(ert-deftest +vterm-backspace/no-preedit-sends-to-terminal ()
  "Backspace with no preedit and zero queue reaches terminal."
  (+vterm-test--env
    (let ((orig-called nil))
      (+vterm-test--press ?\d (lambda () (setq orig-called t)))
      (should orig-called))))

(ert-deftest +vterm-backspace/stale-queue-no-flag-sends-to-terminal ()
  "Stale non-zero hangul-queue without preedit flag must not intercept backspace."
  (+vterm-test--env
    ;; Simulate cross-buffer queue contamination: queue non-zero but no preedit here.
    (aset hangul-queue 0 1)
    (setq +vterm--hangul-has-preedit nil)
    (let ((orig-called nil))
      (+vterm-test--press ?\d (lambda () (setq orig-called t)))
      (should orig-called)
      (should-not +vterm--hangul-has-preedit))))

(ert-deftest +vterm-backspace/with-preedit-decomposes-not-terminal ()
  "Backspace with active preedit decomposes syllable; orig-fn not called."
  (+vterm-test--env
    (setq +vterm--hangul-has-preedit t)
    (aset hangul-queue 0 1)
    (let ((orig-called nil))
      (cl-letf (((symbol-function 'hangul-delete-backward-char)
                 (lambda () (self-insert-command 1 ?ㄱ))))
        (+vterm-test--press ?\d (lambda () (setq orig-called t))))
      (should-not orig-called)
      (should +vterm--hangul-has-preedit))))

(ert-deftest +vterm-backspace/fully-cleared-preedit-clears-flag ()
  "Backspace that empties composition clears the preedit flag."
  (+vterm-test--env
    (setq +vterm--hangul-has-preedit t)
    (aset hangul-queue 0 1)
    (let ((orig-called nil))
      (cl-letf (((symbol-function 'hangul-delete-backward-char) #'ignore))
        (+vterm-test--press ?\d (lambda () (setq orig-called t))))
      (should-not orig-called)
      (should-not +vterm--hangul-has-preedit))))

;;; Space / non-hangul key

(ert-deftest +vterm-space/no-preedit-sends-space-only ()
  "Space with no preedit: no flush, orig-fn called."
  (+vterm-test--env
    (let (sent orig-called)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm-test--press ?\s (lambda () (setq orig-called t))))
      (should-not sent)
      (should orig-called))))

(ert-deftest +vterm-space/with-preedit-flushes-then-sends-space ()
  "Space with preedit: commits preedit then sends space via orig-fn."
  (+vterm-test--env
    (setq +vterm--hangul-has-preedit t)
    (aset hangul-queue 0 1)
    (let (sent orig-called)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul-insert-character)
                 (lambda (&rest _) (self-insert-command 1 ?가))))
        (+vterm-test--press ?\s (lambda () (setq orig-called t))))
      (should (equal sent '("가")))
      (should orig-called)
      (should-not +vterm--hangul-has-preedit))))

;;; Hangul key input

(ert-deftest +vterm-hangul-key/single-char-sets-preedit ()
  "Hangul key producing one captured char sets preedit flag; nothing sent."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal)
                 (lambda (_key) (setq +vterm--hangul-captured "가"))))
        (+vterm-test--press ?r #'ignore))
      (should-not sent)
      (should +vterm--hangul-has-preedit))))

(ert-deftest +vterm-hangul-key/two-chars-commits-first-preeds-second ()
  "Hangul key producing two captured chars commits first char only."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal)
                 (lambda (_key) (setq +vterm--hangul-captured "가나"))))
        (+vterm-test--press ?s #'ignore))
      (should (equal sent '("가")))
      (should +vterm--hangul-has-preedit))))

(ert-deftest +vterm-hangul-key/empty-capture-clears-preedit ()
  "Hangul key producing no captured chars clears the preedit flag."
  (+vterm-test--env
    (setq +vterm--hangul-has-preedit t)
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal) #'ignore))
        (+vterm-test--press ?r #'ignore))
      (should-not sent)
      (should-not +vterm--hangul-has-preedit))))

;;; Korean mode off

(ert-deftest +vterm-korean-off/passes-through-to-orig ()
  "With input-method-function nil, all keys go straight to orig-fn."
  (+vterm-test--env
    (setq-local input-method-function nil)
    (let ((orig-called nil))
      (+vterm-test--press ?r (lambda () (setq orig-called t)))
      (should orig-called))))

(provide '+terminal-test)
;;; +terminal-test.el ends here