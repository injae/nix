;;; vterm-hangul-test.el --- ERT tests for vterm Korean hangul input -*- lexical-binding: t; -*-
;;; Commentary:
;; Run: M-x ert RET "^\\+vterm" RET
;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'hangul)
(require 'vterm-hangul)

;; Remove stale tests from previous implementations that are no longer valid.
(dolist (old-name '(+vterm-flush/sends-preedit-and-resets
                    +vterm-backspace/stale-queue-no-flag-sends-to-terminal
                    +vterm-backspace/fully-cleared-preedit-clears-flag
                    +vterm-hangul-key/two-chars-commits-first-preeds-second
                    +vterm-hangul-key/empty-capture-clears-preedit
                    +vterm-flush-key/enter-with-preedit))
  (when (ert-test-boundp old-name)
    (ert-delete-test old-name)))

;; Declare symbols from vterm to avoid byte-compile warnings.
(defvar vterm--term nil)
(declare-function +vterm--hangul-flush "vterm-hangul")
(declare-function +vterm--hangul-erase-preedit "vterm-hangul")
(declare-function +vterm--hangul-compose-key "vterm-hangul")
(declare-function +vterm--hangul-decompose-backspace "vterm-hangul")
(declare-function +vterm--self-insert-with-im "vterm-hangul")
(declare-function +vterm-toggle-korean "vterm-hangul")
(defvar +vterm--hangul-preedit-sent)
(defvar +vterm--hangul-captured)
(defvar +vterm--hangul-active)
(declare-function +vterm--after-evil-insert-clear-imf "vterm-hangul")
(defvar evil-insert-state-entry-hook nil)

;;; Helpers

(defmacro +vterm-test--env (&rest body)
  "Run BODY in a temp buffer with Korean vterm state initialized.
Saves and restores global hangul-queue to prevent test pollution."
  (declare (indent 0))
  `(let ((saved-queue (copy-sequence hangul-queue)))
     (unwind-protect
         (with-temp-buffer
           (setq-local vterm--term t)
           (setq-local +vterm--hangul-active t)
           (setq-local +vterm--hangul-preedit-sent "")
           (setq hangul-queue (make-vector +vterm--hangul-queue-length 0))
           ,@body)
       (setq hangul-queue saved-queue))))

(defun +vterm-test--press (key orig-fn)
  "Invoke +vterm--self-insert-with-im with KEY as last-command-event."
  (let ((last-command-event key))
    (+vterm--self-insert-with-im orig-fn)))

(defmacro +vterm-test--with-ops (compose-responses backspace-yields &rest body)
  "Run BODY in Korean vterm env with pre-queued mock responses.
COMPOSE-RESPONSES: list of captured strings for successive
  hangul2-input-method-internal calls; nil or missing entry means empty output.
BACKSPACE-YIELDS: list of decomposed-preedit chars for successive
  hangul-delete-backward-char calls; nil entry means decompose yields nothing.
Inside BODY, `sent' holds all strings passed to vterm-send-string, in order."
  (declare (indent 2))
  `(+vterm-test--env
     (let (compose-q bs-q sent)
       (setq compose-q (copy-sequence ,compose-responses)
             bs-q      (copy-sequence ,backspace-yields))
       (cl-letf (((symbol-function 'vterm-send-string)
                  (lambda (s) (setq sent (append sent (list s)))))
                 ((symbol-function 'hangul2-input-method-internal)
                  (lambda (_k)
                    (setq +vterm--hangul-captured (or (pop compose-q) ""))))
                 ((symbol-function 'hangul-delete-backward-char)
                  (lambda ()
                    (let ((ch (pop bs-q)))
                      (when ch (self-insert-command 1 (aref ch 0)))))))
         ,@body))))

;;; +vterm--hangul-capture-self-insert

(ert-deftest +vterm-capture/char-arg-captured ()
  "char argument is captured directly, ignoring last-command-event."
  (let ((+vterm--hangul-captured "")
        (last-command-event ?X))
    (+vterm--hangul-capture-self-insert 1 ?가)
    (should (equal +vterm--hangul-captured "가"))))

(ert-deftest +vterm-capture/last-cmd-event-fallback ()
  "With no char arg, falls back to last-command-event character."
  (let ((+vterm--hangul-captured "")
        (last-command-event ?나))
    (+vterm--hangul-capture-self-insert 1)
    (should (equal +vterm--hangul-captured "나"))))

(ert-deftest +vterm-capture/non-char-event-ignored ()
  "Symbol last-command-event (non-characterp) produces no capture."
  (let ((+vterm--hangul-captured "")
        (last-command-event 'escape))
    (+vterm--hangul-capture-self-insert 1)
    (should (equal +vterm--hangul-captured ""))))

(ert-deftest +vterm-capture/accumulates ()
  "Multiple calls accumulate all chars in sequence."
  (let ((+vterm--hangul-captured ""))
    (+vterm--hangul-capture-self-insert 1 ?가)
    (+vterm--hangul-capture-self-insert 1 ?나)
    (should (equal +vterm--hangul-captured "가나"))))

;;; +vterm--hangul-erase-preedit

(ert-deftest +vterm-erase-preedit/empty-noop ()
  "Empty preedit-sent: no DEL sent, state unchanged."
  (with-temp-buffer
    (setq-local +vterm--hangul-preedit-sent "")
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-erase-preedit))
      (should-not sent)
      (should (equal +vterm--hangul-preedit-sent "")))))

(ert-deftest +vterm-erase-preedit/sends-del-and-clears ()
  "Non-empty preedit-sent: sends DEL (127) and clears preedit-sent."
  (with-temp-buffer
    (setq-local +vterm--hangul-preedit-sent "가")
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-erase-preedit))
      (should (= (length sent) 1))
      (should (= (aref (car sent) 0) 127))
      (should (equal +vterm--hangul-preedit-sent "")))))

;;; +vterm--hangul-flush

(ert-deftest +vterm-flush/no-preedit-is-noop ()
  "flush does nothing when preedit-sent is empty string."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-flush))
      (should-not sent)
      (should (equal +vterm--hangul-preedit-sent "")))))

(ert-deftest +vterm-flush/clears-state ()
  "flush with active preedit clears preedit-sent and resets queue."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "가")
    (aset hangul-queue 0 1)
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-flush))
      (should-not sent)
      (should (equal +vterm--hangul-preedit-sent ""))
      (should (seq-every-p #'zerop hangul-queue)))))

;;; +vterm--hangul-compose-key (direct function tests)

(ert-deftest +vterm-compose-key/no-prior-sends-char-only ()
  "No old preedit: sends new preedit char without DEL."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'hangul2-input-method-internal)
                 (lambda (_) (setq +vterm--hangul-captured "가")))
                ((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-compose-key ?r))
      (should (equal sent '("가")))
      (should (equal +vterm--hangul-preedit-sent "가")))))

(ert-deftest +vterm-compose-key/with-prior-erases-then-sends ()
  "Existing preedit: sends DEL to erase old, then sends new char."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "ㄱ")
    (let (sent)
      (cl-letf (((symbol-function 'hangul2-input-method-internal)
                 (lambda (_) (setq +vterm--hangul-captured "가")))
                ((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-compose-key ?r))
      (should (member "\177" sent))
      (should (member "가" sent))
      (should (equal +vterm--hangul-preedit-sent "가")))))

(ert-deftest +vterm-compose-key/two-chars-commit-first-preedit-second ()
  "Two captured chars: first is committed to terminal, second becomes preedit."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'hangul2-input-method-internal)
                 (lambda (_) (setq +vterm--hangul-captured "가나")))
                ((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-compose-key ?s))
      (should (member "가" sent))
      (should (member "나" sent))
      (should (equal +vterm--hangul-preedit-sent "나")))))

(ert-deftest +vterm-compose-key/empty-capture-erases-only ()
  "No chars captured: only erases old preedit, clears preedit-sent."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "가")
    (let (sent)
      (cl-letf (((symbol-function 'hangul2-input-method-internal) #'ignore)
                ((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-compose-key ?r))
      (should (= (length sent) 1))
      (should (= (aref (car sent) 0) 127))
      (should (equal +vterm--hangul-preedit-sent "")))))

;;; +vterm--hangul-decompose-backspace (direct function tests)

(ert-deftest +vterm-decompose-backspace/yields-char-erases-and-sends ()
  "Decompose yields a char: sends DEL then the decomposed preedit char."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "각")
    (let (sent)
      (cl-letf (((symbol-function 'hangul-delete-backward-char)
                 (lambda () (self-insert-command 1 ?가)))
                ((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-decompose-backspace))
      (should (member "\177" sent))
      (should (member "가" sent))
      (should (equal +vterm--hangul-preedit-sent "가")))))

(ert-deftest +vterm-decompose-backspace/empty-yield-erases-only ()
  "Decompose yields nothing: sends only DEL, clears preedit-sent."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "ㄱ")
    (let (sent)
      (cl-letf (((symbol-function 'hangul-delete-backward-char) #'ignore)
                ((symbol-function 'vterm-send-string) (lambda (s) (push s sent))))
        (+vterm--hangul-decompose-backspace))
      (should (= (length sent) 1))
      (should (= (aref (car sent) 0) 127))
      (should (equal +vterm--hangul-preedit-sent "")))))

;;; +vterm--self-insert-with-im guard conditions

(ert-deftest +vterm-guard/no-vterm-term-passthrough ()
  "vterm--term nil: all keys bypass IME and go directly to orig-fn."
  (+vterm-test--env
    (setq-local vterm--term nil)
    (let ((orig-called nil))
      (+vterm-test--press ?r (lambda () (setq orig-called t)))
      (should orig-called))))

(ert-deftest +vterm-guard/non-char-event-passthrough ()
  "Non-characterp event (meta key value beyond Unicode range): passes to orig-fn."
  (+vterm-test--env
    (let ((orig-called nil)
          (last-command-event (+ ?r (lsh 1 27))))
      (+vterm--self-insert-with-im (lambda () (setq orig-called t)))
      (should orig-called))))

;;; +vterm-backspace behavior

(ert-deftest +vterm-backspace/no-preedit-sends-to-terminal ()
  "Backspace with no preedit and zero queue reaches terminal."
  (+vterm-test--env
    (let ((orig-called nil))
      (+vterm-test--press ?\d (lambda () (setq orig-called t)))
      (should orig-called))))

(ert-deftest +vterm-backspace/stale-queue-no-preedit-sends-to-terminal ()
  "Stale non-zero hangul-queue without preedit flag must not intercept backspace."
  (+vterm-test--env
    (aset hangul-queue 0 1)
    (setq +vterm--hangul-preedit-sent "")
    (let ((orig-called nil))
      (+vterm-test--press ?\d (lambda () (setq orig-called t)))
      (should orig-called)
      (should (equal +vterm--hangul-preedit-sent "")))))

(ert-deftest +vterm-backspace/with-preedit-decomposes-not-terminal ()
  "Backspace with active preedit decomposes syllable; orig-fn not called."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "각")
    (aset hangul-queue 0 1)
    (let (sent orig-called)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul-delete-backward-char)
                 (lambda () (self-insert-command 1 ?가))))
        (+vterm-test--press ?\d (lambda () (setq orig-called t))))
      (should-not orig-called)
      (should (member "\177" sent))
      (should (member "가" sent))
      (should (equal +vterm--hangul-preedit-sent "가")))))

(ert-deftest +vterm-backspace/fully-cleared-preedit-sends-erase-only ()
  "Backspace that empties composition sends only erase, clears preedit-sent."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "ㄱ")
    (aset hangul-queue 0 1)
    (let (sent orig-called)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul-delete-backward-char) #'ignore))
        (+vterm-test--press ?\d (lambda () (setq orig-called t))))
      (should-not orig-called)
      (should (= (length sent) 1))
      (should (= (aref (car sent) 0) 127))
      (should (equal +vterm--hangul-preedit-sent "")))))

;;; Non-hangul key flush (the (t ...) cond branch)
;; Note: ?\r (13) has (control) modifier → bypasses Korean handler entirely.
;; Use non-modifier printable keys to exercise the flush branch.

(ert-deftest +vterm-flush-key/punct-with-preedit ()
  "Punctuation with active preedit: flush state (no vterm-send), call orig-fn."
  (+vterm-test--with-ops '() '()
    (setq +vterm--hangul-preedit-sent "가")
    (let (orig-called)
      (+vterm-test--press ?. (lambda () (setq orig-called t)))
      (should orig-called)
      (should (equal +vterm--hangul-preedit-sent ""))
      (should-not sent))))

(ert-deftest +vterm-flush-key/no-preedit-passthrough-only ()
  "Non-hangul key without preedit: orig-fn called, no send."
  (+vterm-test--with-ops '() '()
    (let (orig-called)
      (+vterm-test--press ?. (lambda () (setq orig-called t)))
      (should orig-called)
      (should-not sent))))

(ert-deftest +vterm-flush-key/ctrl-bypasses-korean-handler ()
  "Control key (?\r) has (control) modifier: bypasses Korean handler.
Preedit state is left untouched — potential stale state after Enter."
  (+vterm-test--with-ops '() '()
    (setq +vterm--hangul-preedit-sent "가")
    (let (orig-called)
      (+vterm-test--press ?\r (lambda () (setq orig-called t)))
      (should orig-called)
      (should (equal +vterm--hangul-preedit-sent "가")))))

;;; Hangul key dispatch (via self-insert-with-im)

(ert-deftest +vterm-hangul-key/single-char-sets-preedit ()
  "Hangul key producing one captured char sends it inline; preedit-sent set."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal)
                 (lambda (_key) (setq +vterm--hangul-captured "가"))))
        (+vterm-test--press ?r #'ignore))
      (should (equal sent '("가")))
      (should (equal +vterm--hangul-preedit-sent "가")))))

(ert-deftest +vterm-hangul-key/two-chars-commits-first-sends-second ()
  "Hangul key producing two captured chars: commits first, sends second inline."
  (+vterm-test--env
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal)
                 (lambda (_key) (setq +vterm--hangul-captured "가나"))))
        (+vterm-test--press ?s #'ignore))
      (should (member "가" sent))
      (should (member "나" sent))
      (should (equal +vterm--hangul-preedit-sent "나")))))

(ert-deftest +vterm-hangul-key/replaces-old-preedit ()
  "Hangul key with existing preedit erases old before sending new."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "ㄱ")
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal)
                 (lambda (_key) (setq +vterm--hangul-captured "가"))))
        (+vterm-test--press ?r #'ignore))
      (should (member "\177" sent))
      (should (member "가" sent))
      (should (equal +vterm--hangul-preedit-sent "가")))))

(ert-deftest +vterm-hangul-key/empty-capture-erases-preedit ()
  "Hangul key producing no captured chars erases preedit if present."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "가")
    (let (sent)
      (cl-letf (((symbol-function 'vterm-send-string) (lambda (s) (push s sent)))
                ((symbol-function 'hangul2-input-method-internal) #'ignore))
        (+vterm-test--press ?r #'ignore))
      (should (= (length sent) 1))
      (should (= (aref (car sent) 0) 127))
      (should (equal +vterm--hangul-preedit-sent "")))))

;;; Korean mode off

(ert-deftest +vterm-korean-off/passes-through-to-orig ()
  "With +vterm--hangul-active nil, all keys go straight to orig-fn."
  (+vterm-test--env
    (setq-local +vterm--hangul-active nil)
    (let ((orig-called nil))
      (+vterm-test--press ?r (lambda () (setq orig-called t)))
      (should orig-called))))

;;; +vterm-toggle-korean

(ert-deftest +vterm-toggle-korean/enables ()
  "Toggle ON: sets +vterm--hangul-active, current-input-method, resets queue."
  (+vterm-test--env
    (setq-local +vterm--hangul-active nil)
    (aset hangul-queue 0 1)
    (+vterm-toggle-korean)
    (should +vterm--hangul-active)
    (should (equal current-input-method "korean-hangul"))
    (should-not input-method-function)
    (should (seq-every-p #'zerop hangul-queue))))

(ert-deftest +vterm-toggle-korean/disables ()
  "Toggle OFF: clears +vterm--hangul-active, input-method-function, current-input-method."
  (+vterm-test--env
    ;; +vterm--hangul-active already set by env
    (+vterm-toggle-korean)
    (should-not +vterm--hangul-active)
    (should-not input-method-function)
    (should-not current-input-method)))

(ert-deftest +vterm-toggle-korean/disable-clears-preedit-state ()
  "Toggle OFF with active preedit: flush clears preedit-sent and queue."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "가")
    (aset hangul-queue 0 1)
    (+vterm-toggle-korean)
    (should (equal +vterm--hangul-preedit-sent ""))
    (should (seq-every-p #'zerop hangul-queue))))

;;; +vterm--after-evil-insert-clear-imf

(ert-deftest +vterm-evil-hook/active-clears-imf ()
  "When Korean active, hook clears input-method-function."
  (with-temp-buffer
    (setq-local +vterm--hangul-active t)
    (setq-local input-method-function #'ignore)
    (+vterm--after-evil-insert-clear-imf)
    (should-not input-method-function)))

(ert-deftest +vterm-evil-hook/inactive-preserves-imf ()
  "When Korean inactive, hook leaves input-method-function unchanged."
  (with-temp-buffer
    (setq-local +vterm--hangul-active nil)
    (setq-local input-method-function #'ignore)
    (+vterm--after-evil-insert-clear-imf)
    (should (eq input-method-function #'ignore))))

;;; Toggle Korean — evil hook registration

(ert-deftest +vterm-toggle-korean/enables-adds-evil-hook ()
  "Toggle ON adds +vterm--after-evil-insert-clear-imf to evil-insert-state-entry-hook buffer-locally."
  (+vterm-test--env
    (setq-local +vterm--hangul-active nil)
    (+vterm-toggle-korean)
    (should (memq #'+vterm--after-evil-insert-clear-imf evil-insert-state-entry-hook))))

(ert-deftest +vterm-toggle-korean/disables-removes-evil-hook ()
  "Toggle OFF removes +vterm--after-evil-insert-clear-imf from evil-insert-state-entry-hook."
  (+vterm-test--env
    (add-hook 'evil-insert-state-entry-hook #'+vterm--after-evil-insert-clear-imf nil t)
    (+vterm-toggle-korean)
    (should-not (memq #'+vterm--after-evil-insert-clear-imf evil-insert-state-entry-hook))))

;;; hangul-queue isolation (cross-buffer contamination)

(ert-deftest +vterm-queue-contamination/enable-zeros-queue-despite-global ()
  "Enable Korean zeros buffer-local queue even when global has stale state.
Regression: without make-local-variable, global contamination from another
buffer's composition bleeds into vterm backspace decompose, producing an
unexpected character (the stale jamo) as preedit."
  (let ((saved-queue (copy-sequence hangul-queue)))
    (unwind-protect
        (progn
          ;; Contaminate global (simulates leaving another buffer mid-composition)
          (setq hangul-queue (make-vector +vterm--hangul-queue-length 0))
          (aset hangul-queue 0 99)
          (with-temp-buffer
            (setq-local vterm--term t)
            (setq-local +vterm--hangul-active nil)
            (setq-local +vterm--hangul-preedit-sent "")
            ;; Enable: makes hangul-queue buffer-local, zeroed
            (+vterm-toggle-korean)
            (should (seq-every-p #'zerop hangul-queue))
            ;; Buffer-local modification must not touch global
            (aset hangul-queue 0 42)
            (should (= (aref (default-value 'hangul-queue) 0) 99))))
      (setq hangul-queue saved-queue))))

;;; Add-operation sequences

(ert-deftest +vterm-seq-add/first-key-sets-preedit ()
  "First hangul keypress sends one char as inline preedit."
  (+vterm-test--with-ops '("ㄱ") '()
    (+vterm-test--press ?r #'ignore)
    (should (equal sent '("ㄱ")))
    (should (equal +vterm--hangul-preedit-sent "ㄱ"))))

(ert-deftest +vterm-seq-add/second-key-erases-then-sends-new-preedit ()
  "Second keypress erases previous preedit and sends new one inline."
  (+vterm-test--with-ops '("ㄱ" "가") '()
    (+vterm-test--press ?r #'ignore)
    (+vterm-test--press ?k #'ignore)
    (should (equal sent '("ㄱ" "\177" "가")))
    (should (equal +vterm--hangul-preedit-sent "가"))))

(ert-deftest +vterm-seq-add/two-char-capture-commits-first-preeds-second ()
  "Keypress returning two chars: first committed to terminal, second becomes preedit."
  (+vterm-test--with-ops '("ㄱ" "가나") '()
    (+vterm-test--press ?r #'ignore)
    (+vterm-test--press ?k #'ignore)
    (should (equal sent '("ㄱ" "\177" "가" "나")))
    (should (equal +vterm--hangul-preedit-sent "나"))))

;;; Delete-operation sequences

(ert-deftest +vterm-seq-del/backspace-decomposes-one-step ()
  "Backspace on a composite preedit decomposes it one step."
  (+vterm-test--with-ops '() '("가")
    (setq +vterm--hangul-preedit-sent "각")
    (+vterm-test--press ?\d #'ignore)
    (should (equal sent '("\177" "가")))
    (should (equal +vterm--hangul-preedit-sent "가"))))

(ert-deftest +vterm-seq-del/two-backspaces-clear-composition ()
  "Two backspaces: first decomposes to preedit, second fully clears it."
  (+vterm-test--with-ops '() '("가" nil)
    (setq +vterm--hangul-preedit-sent "각")
    (+vterm-test--press ?\d #'ignore)
    (+vterm-test--press ?\d #'ignore)
    (should (equal sent '("\177" "가" "\177")))
    (should (equal +vterm--hangul-preedit-sent ""))))

;;; Mixed add/delete sequences

(ert-deftest +vterm-seq-mixed/compose-then-decompose ()
  "Compose a syllable then backspace decomposes it to consonant preedit."
  (+vterm-test--with-ops '("가") '("ㄱ")
    (+vterm-test--press ?r #'ignore)
    (+vterm-test--press ?\d #'ignore)
    (should (equal sent '("가" "\177" "ㄱ")))
    (should (equal +vterm--hangul-preedit-sent "ㄱ"))))

(ert-deftest +vterm-seq-mixed/decompose-to-empty-then-compose ()
  "Backspace clears single-consonant preedit; next key starts fresh."
  (+vterm-test--with-ops '("나") '(nil)
    (setq +vterm--hangul-preedit-sent "ㄱ")
    (+vterm-test--press ?\d #'ignore)
    (should (equal +vterm--hangul-preedit-sent ""))
    (+vterm-test--press ?r #'ignore)
    (should (equal sent '("\177" "나")))
    (should (equal +vterm--hangul-preedit-sent "나"))))

;;; vterm-send-backspace advice tests

(declare-function +vterm--send-backspace-with-im "vterm-hangul")
(declare-function +vterm--send-return-flush-im "vterm-hangul")

(defmacro +vterm-test--backspace-env (&rest body)
  "Env for vterm-send-backspace advice tests: active Korean, mock vterm-send-string."
  `(+vterm-test--env
     (let (sent)
       (cl-letf (((symbol-function 'vterm-send-string)
                  (lambda (s) (setq sent (append sent (list s))))))
         ,@body))))

(ert-deftest +vterm-backspace-advice/preedit-decomposes ()
  "With preedit, advice calls decompose instead of orig-fn."
  (+vterm-test--backspace-env
    (setq +vterm--hangul-preedit-sent "가")
    (aset hangul-queue 0 9) (aset hangul-queue 2 39)  ; ㄱ+ㅏ state
    (let (orig-called)
      (cl-letf (((symbol-function 'hangul-delete-backward-char)
                 (lambda ()
                   (aset hangul-queue 2 0)
                   (self-insert-command 1 (aref "ㄱ" 0)))))
        (+vterm--send-backspace-with-im (lambda () (setq orig-called t))))
      (should-not orig-called)
      (should (equal +vterm--hangul-preedit-sent "ㄱ"))
      (should (member "\177" sent)))))

(ert-deftest +vterm-backspace-advice/no-preedit-calls-orig ()
  "Without preedit, advice passes through to orig-fn."
  (+vterm-test--backspace-env
    (setq +vterm--hangul-preedit-sent "")
    (let (orig-called)
      (+vterm--send-backspace-with-im (lambda () (setq orig-called t)))
      (should orig-called)
      (should-not sent))))

(ert-deftest +vterm-backspace-advice/korean-inactive-calls-orig ()
  "Korean inactive: advice always passes through."
  (+vterm-test--env
    (setq-local +vterm--hangul-active nil)
    (setq +vterm--hangul-preedit-sent "가")
    (let (orig-called)
      (+vterm--send-backspace-with-im (lambda () (setq orig-called t)))
      (should orig-called))))

(ert-deftest +vterm-return-advice/preedit-flushed ()
  "Enter flushes preedit state and calls orig-fn."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "가")
    (setq hangul-queue (make-vector +vterm--hangul-queue-length 0))
    (aset hangul-queue 0 9)
    (let (orig-called)
      (+vterm--send-return-flush-im (lambda () (setq orig-called t)))
      (should orig-called)
      (should (equal +vterm--hangul-preedit-sent ""))
      (should (seq-every-p #'zerop hangul-queue)))))

(ert-deftest +vterm-return-advice/no-preedit-calls-orig ()
  "Enter without preedit calls orig-fn, state unchanged."
  (+vterm-test--env
    (setq +vterm--hangul-preedit-sent "")
    (let (orig-called)
      (+vterm--send-return-flush-im (lambda () (setq orig-called t)))
      (should orig-called)
      (should (equal +vterm--hangul-preedit-sent "")))))

;;; Scenario (integration) tests — simulate full terminal state

(defmacro +vterm-test--scenario (compose-seq bs-seq &rest body)
  "Integration test: tracks terminal string through compose/backspace/return.
COMPOSE-SEQ: list of strings captured per hangul keypress.
BS-SEQ: list of strings/nils per backspace call (nil = queue emptied, no new preedit).
Binds inside BODY:
  `term'  — current terminal string (DELs applied)
  `press' — (press KEY) simulate a keypress through +vterm--self-insert-with-im
  `bs'    — (bs) simulate vterm-send-backspace through our advice
  `ret'   — (ret) simulate vterm-send-return through our advice"
  (declare (indent 2))
  `(+vterm-test--env
     (let ((term "")
           (compose-q (copy-sequence ,compose-seq))
           (bs-q      (copy-sequence ,bs-seq)))
       (cl-letf (((symbol-function 'vterm-send-string)
                  (lambda (s)
                    (dolist (c (string-to-list s))
                      (if (= c 127)
                          (setq term (if (> (length term) 0)
                                         (substring term 0 -1)
                                       ""))
                        (setq term (concat term (string c)))))))
                 ((symbol-function 'hangul2-input-method-internal)
                  (lambda (_k)
                    (setq +vterm--hangul-captured (or (pop compose-q) ""))))
                 ((symbol-function 'hangul-delete-backward-char)
                  (lambda ()
                    (let ((ch (pop bs-q)))
                      (when ch (self-insert-command 1 (aref ch 0)))))))
         (cl-flet ((press (key) (+vterm-test--press key #'ignore))
                   (bs    ()   (+vterm--send-backspace-with-im
                                (lambda ()
                                  (setq term (if (> (length term) 0)
                                                 (substring term 0 -1)
                                               "")))))
                   (ret   ()   (+vterm--send-return-flush-im #'ignore)))
           ,@body)))))

(ert-deftest +vterm-scenario/delete-syllable-yields-empty ()
  "Type 가 (ㄱ+ㅏ, 2 jasos), backspace twice → terminal empty."
  (+vterm-test--scenario '("ㄱ" "가") '("ㄱ" nil)
    (press ?f)                          ; preedit: ㄱ
    (press ?k)                          ; preedit: 가
    (should (equal term "가"))
    (bs)                                ; preedit: ㄱ
    (should (equal term "ㄱ"))
    (bs)                                ; preedit: (empty)
    (should (equal term ""))))

(ert-deftest +vterm-scenario/committed-char-survives-backspace ()
  "가 committed before 나 preedit: backspacing through 나 leaves 가 untouched."
  ;; compose: ㄱ → 가 → 간 (jongseong added) → "가나" (split, two chars committed+preedit)
  (+vterm-test--scenario '("ㄱ" "가" "간" "가나") '("ㄴ" nil)
    (press ?f)                          ; preedit: ㄱ
    (press ?k)                          ; preedit: 가
    (press ?s)                          ; preedit: 간 (ㄴ as jongseong)
    (press ?k)                          ; committed: 가 / preedit: 나
    (should (equal term "가나"))
    (bs)                                ; 나 → ㄴ preedit, 가 intact
    (should (equal term "가ㄴ"))
    (bs)                                ; ㄴ cleared, 가 still intact
    (should (equal term "가"))))

(ert-deftest +vterm-scenario/backspace-then-retype-no-spurious-del ()
  "After backspace clears all preedit, retyping starts clean with no spurious DEL."
  ;; compose: ㄱ → 가 (first word), then ㄴ → 나 (retyped after delete)
  (+vterm-test--scenario '("ㄱ" "가" "ㄴ" "나") '("ㄱ" nil)
    (press ?f)                          ; preedit: ㄱ
    (press ?k)                          ; preedit: 가
    (bs)                                ; 가 → ㄱ
    (bs)                                ; ㄱ → empty
    (should (equal term ""))
    (press ?s)                          ; fresh start: preedit ㄴ (no DEL sent)
    (press ?k)                          ; preedit: 나
    (should (equal term "나"))))

(provide 'vterm-hangul-test)
;;; vterm-hangul-test.el ends here