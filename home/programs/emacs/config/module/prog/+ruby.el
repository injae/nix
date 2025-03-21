;;; +ruby.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package ruby-mode :ensure nil :after exec-path-from-shell
:mode "\\.rb\\'"
:mode "Rakefile\\'"
:mode "Gemfile\\'"
:mode "Berksfile\\'"
:mode "Vagrantfile\\'"
:interpreter "ruby"
:custom (ruby-indent-level 4)
        (ruby-indent-tabs-mode nil)
)

(use-package rvm
:after ruby-mode
:config (rvm-use-default)
)

(use-package yari :after ruby-mode)
 
(use-package rubocop :after (ruby-mode exec-path-from-shell) :disabled
:ensure-system-package (rubocop . "gem install rubocop")
:init (add-hook 'ruby-mode-hook 'rubocop-mode)
)

(use-package robe :after (ruby-mode exec-path-from-shell) :disabled
:ensure-system-package (pry . "gem install pry pry-doc")
:init (add-hook 'ruby-mode-hook 'robe-mode)
)

(use-package ruby-tools :after ruby-mode
:init (add-hook 'ruby-mode-hook 'ruby-tools-mode)
)

(provide '+ruby)
;;; +ruby.el ends here
