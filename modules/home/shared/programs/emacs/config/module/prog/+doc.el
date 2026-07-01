;;; +doc.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package eldoc :ensure nil
  :hook (emacs-startup . global-eldoc-mode))

(use-package eldoc-box
  :preface
  ;; hover-mode의 공유 childframe은 글로벌 타이머로만 정리돼 버퍼/윈도우
  ;; 전환 시 이전 버퍼 내용이 남는다. 전환 시점에 명시적으로 숨긴다.
  (defun +eldoc-box-quit-on-window-change (&rest _)
    (eldoc-box-quit-frame))
  :hook (eldoc-mode . eldoc-box-hover-mode)
  :custom
  (eldoc-box-max-pixel-width 600)
  (eldoc-box-max-pixel-height 400)
  (eldoc-box-clear-with-C-g t)
  :config
  (add-hook 'window-selection-change-functions #'+eldoc-box-quit-on-window-change)
  (add-hook 'window-buffer-change-functions #'+eldoc-box-quit-on-window-change))


(provide '+doc)
;;; +doc.el ends here
