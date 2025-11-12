((ace-window :source "elpaca-menu-lock-file" :recipe
     (:package "ace-window" :repo "abo-abo/ace-window" :fetcher github
         :files
         ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
             "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
             "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
             "docs/*.texinfo"
             (:exclude ".dir-locals.el" "test.el" "tests.el"
                 "*-test.el" "*-tests.el" "LICENSE" "README*"
                 "*-pkg.el"))
         :source "MELPA" :protocol https :inherit t :depth treeless
         :ref "77115afc1b0b9f633084cf7479c767988106c196"))
    (affe :source "elpaca-menu-lock-file" :recipe
        (:package "affe" :repo "minad/affe" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9afd5cecfc17a2b07b33f3581d601f2e2f5b6de6"))
    (agenix :source "elpaca-menu-lock-file" :recipe
        (:package "agenix" :repo "t4ccer/agenix.el" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "36ad60f0b7f2a12b730c6f568fcfd4daf2581158"))
    (aio :source "elpaca-menu-lock-file" :recipe
        (:package "aio" :fetcher github :repo "skeeto/emacs-aio"
            :files ("aio.el" "README.md" "UNLICENSE") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "da93523e235529fa97d6f251319d9e1d6fc24a41"))
    (alert :source "elpaca-menu-lock-file" :recipe
        (:package "alert" :fetcher github :repo "jwiegley/alert"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "7774b5fd2feb98d4910ff06435d08c19fba93e26"))
    (all-the-icons :source "elpaca-menu-lock-file" :recipe
        (:package "all-the-icons" :repo "domtronn/all-the-icons.el"
            :fetcher github :files (:defaults "data") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "4778632b29c8c8d2b7cd9ce69535d0be01d846f9"))
    (all-the-icons-completion :source "elpaca-menu-lock-file" :recipe
        (:package "all-the-icons-completion" :repo
            "iyefrat/all-the-icons-completion" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4c8bcad8033f5d0868ce82ea3807c6cd46c4a198"))
    (all-the-icons-dired :source "elpaca-menu-lock-file" :recipe
        (:package "all-the-icons-dired" :repo
            "wyuenho/all-the-icons-dired" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e157f0668f22ed586aebe0a2c0186ab07702986c"))
    (all-the-icons-ibuffer :source "elpaca-menu-lock-file" :recipe
        (:package "all-the-icons-ibuffer" :repo
            "seagle0128/all-the-icons-ibuffer" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5357ab96f4dc9d0940d5a1e2e43302e1a04a14b2"))
    (all-the-icons-nerd-fonts :source "elpaca-menu-lock-file" :recipe
        (:package "all-the-icons-nerd-fonts" :fetcher github :repo
            "mohkale/all-the-icons-nerd-fonts" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :host github :ref
            "67a9cc9de2d2d4516cbfb752879b1355234cb42a"))
    (annalist :source "elpaca-menu-lock-file" :recipe
        (:package "annalist" :fetcher github :repo
            "noctuid/annalist.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e1ef5dad75fa502d761f70d9ddf1aeb1c423f41d"))
    (apheleia :source "elpaca-menu-lock-file" :recipe
        (:package "apheleia" :fetcher github :repo
            "radian-software/apheleia" :files
            (:defaults ("scripts" "scripts/formatters")) :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "7eaaf3f45703d49e494f6dd0555633cf6b355817"))
    (async :source "elpaca-menu-lock-file" :recipe
        (:package "async" :repo "jwiegley/emacs-async" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "bb3f31966ed65a76abe6fa4f80a960a2917f554e"))
    (atomic-chrome :source "elpaca-menu-lock-file" :recipe
        (:package "atomic-chrome" :repo "alpha22jp/atomic-chrome"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "072a137a19d7e6a300ca3e87c0e142a7f4ccb5fb"))
    (auto-yasnippet :source "elpaca-menu-lock-file" :recipe
        (:package "auto-yasnippet" :fetcher github :repo
            "abo-abo/auto-yasnippet" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6a9e406d0d7f9dfd6dff7647f358cb05a0b1637e"))
    (avy :source "elpaca-menu-lock-file" :recipe
        (:package "avy" :repo "abo-abo/avy" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "933d1f36cca0f71e4acb5fac707e9ae26c536264"))
    (bazel :source "elpaca-menu-lock-file" :recipe
        (:package "bazel" :repo "bazelbuild/emacs-bazel-mode" :fetcher
            github :old-names (bazel-mode) :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "769b30dc18282564d614d7044195b5a0c1a0a5f3"))
    (blamer :source "elpaca-menu-lock-file" :recipe
        (:package "blamer" :repo "Artawower/blamer.el" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8a79c1f370f7c5f041c980e0b727960462c192ba"))
    (browse-at-remote :source "elpaca-menu-lock-file" :recipe
        (:package "browse-at-remote" :repo
            "rmuslimov/browse-at-remote" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "76aa27dfd469fcae75ed7031bb73830831aaccbf"))
    (browser-hist :source "elpaca-menu-lock-file" :recipe
        (:package "browser-hist" :fetcher github :repo
            "agzam/browser-hist.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1cd80081feaab99fef9e8eadd55d68b3cef90144"))
    (buffer-move :source "elpaca-menu-lock-file" :recipe
        (:package "buffer-move" :fetcher github :repo
            "lukhas/buffer-move" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e7800b3ab1bd76ee475ef35507ec51ecd5a3f065"))
    (cape :source "elpaca-menu-lock-file" :recipe
        (:package "cape" :repo "minad/cape" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "c9191ee9e13e86a7b40c3d25c8bf7907c085a1cf"))
    (cargo :source "elpaca-menu-lock-file" :recipe
        (:package "cargo" :repo "kwrooijen/cargo.el" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "7f8466063381eed05d4e222ce822b1dd44e3bf17"))
    (cfrs :source "elpaca-menu-lock-file" :recipe
        (:package "cfrs" :repo "Alexander-Miller/cfrs" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "f3a21f237b2a54e6b9f8a420a9da42b4f0a63121"))
    (closql :source "elpaca-menu-lock-file" :recipe
        (:package "closql" :fetcher github :repo "magit/closql" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "c90bb6536307d26943442a69137d6f03675aa2d7"))
    (cmake-mode :source "elpaca-menu-lock-file" :recipe
        (:package "cmake-mode" :fetcher git :url
            "https://gitlab.kitware.com/cmake/cmake.git" :files
            ("Auxiliary/*.el") :source "MELPA" :protocol https
            :inherit t :depth treeless :ref
            "38bcc1d01405ecaee97322771fa25c01f425448c"))
    (combobulate :source "elpaca-menu-lock-file" :recipe
        (:source nil :protocol https :inherit t :depth treeless :type
            git :host github :repo "mickeynp/combobulate" :package
            "combobulate" :ref
            "59b64d66d66eb84da6a2cedd152b1692378af674"))
    (command-log-mode :source "elpaca-menu-lock-file" :recipe
        (:package "command-log-mode" :fetcher github :repo
            "lewang/command-log-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "af600e6b4129c8115f464af576505ea8e789db27"))
    (compile-multi :source "elpaca-menu-lock-file" :recipe
        (:package "compile-multi" :fetcher github :repo
            "mohkale/compile-multi" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "19d16d8871b5f19f5625e1a66c1dc46a7c3f6a3a"))
    (compile-multi-embark :source "elpaca-menu-lock-file" :recipe
        (:package "compile-multi-embark" :fetcher github :repo
            "mohkale/compile-multi" :files
            ("extensions/compile-multi-embark/compile-multi-embark*.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "19d16d8871b5f19f5625e1a66c1dc46a7c3f6a3a"))
    (consult :source "elpaca-menu-lock-file" :recipe
        (:package "consult" :repo "minad/consult" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "59fd94d147503e519631077369a60719763e7f33"))
    (consult-dir :source "elpaca-menu-lock-file" :recipe
        (:package "consult-dir" :fetcher github :repo
            "karthink/consult-dir" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4532b8d215d16b0159691ce4dee693e72d71e0ff"))
    (consult-eglot :source "elpaca-menu-lock-file" :recipe
        (:package "consult-eglot" :fetcher github :repo
            "mohkale/consult-eglot" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "b71499f4b93bfea4e2005564c25c5bb0f9e73199"))
    (consult-flycheck :source "elpaca-menu-lock-file" :recipe
        (:package "consult-flycheck" :fetcher github :repo
            "minad/consult-flycheck" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8067363ee33c01d339d9f18091dce5f18e3b97ee"))
    (consult-flyspell :source "elpaca-menu-lock-file" :recipe
        (:package "consult-flyspell" :repo "OlMon/consult-flyspell"
            :fetcher gitlab :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "7011e6634598530ea2d874e7e7389dc1bb94e1ca"))
    (consult-gh :source "elpaca-menu-lock-file" :recipe
        (:package "consult-gh" :fetcher github :repo
            "armindarvish/consult-gh" :files (:defaults "*.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "c3513c6e66fe2871d54a32b4c469c26aa5db4da5"))
    (consult-lsp :source "elpaca-menu-lock-file" :recipe
        (:package "consult-lsp" :fetcher github :repo
            "gagbo/consult-lsp" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "aef321d03907ca6926b0cf20ca85f672c4744000"))
    (consult-projectile :source "elpaca-menu-lock-file" :recipe
        (:package "consult-projectile" :fetcher gitlab :repo
            "OlMon/consult-projectile" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "400439c56d17bca7888f7d143d8a11f84900a406"))
    (consult-yasnippet :source "elpaca-menu-lock-file" :recipe
        (:package "consult-yasnippet" :fetcher github :repo
            "mohkale/consult-yasnippet" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "a3482dfbdcbe487ba5ff934a1bb6047066ff2194"))
    (copilot :source "elpaca-menu-lock-file" :recipe
        (:package "copilot" :fetcher github :repo "zerolfx/copilot.el"
            :files ("dist" "*.el") :source "MELPA" :protocol https
            :inherit t :depth treeless :host github :ref
            "fe3f51b636dea1c9ac55a0d5dc5d7df02dcbaa48"))
    (corfu :source "elpaca-menu-lock-file" :recipe
        (:package "corfu" :repo "minad/corfu" :files
            (:defaults "extensions/*") :fetcher github :source "MELPA"
            :protocol https :inherit t :depth treeless :includes
            (corfu-history corfu-popupinfo) :ref
            "77e639bc6b982be09f355390beef6f200936109a"))
    (cov :source "elpaca-menu-lock-file" :recipe
        (:package "cov" :fetcher github :repo "AdamNiederer/cov"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "7a3599e42d4fe943b912701e04beffcf2ec812d2"))
    (daemons :source "elpaca-menu-lock-file" :recipe
        (:package "daemons" :fetcher github :repo "cbowdon/daemons.el"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "7b08ce315c0be901d88c1099483f9607c653712e"))
    (dash :source "elpaca-menu-lock-file" :recipe
        (:package "dash" :fetcher github :repo "magnars/dash.el"
            :files ("dash.el" "dash.texi") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "fcb5d831fc08a43f984242c7509870f30983c27c"))
    (dashboard :source "elpaca-menu-lock-file" :recipe
        (:package "dashboard" :fetcher github :repo
            "emacs-dashboard/emacs-dashboard" :files
            (:defaults "banners") :source "MELPA" :protocol https
            :inherit t :depth treeless :ref
            "f07661b39bec3683cf9edb7b1c58f6e658b6f764"))
    (default-text-scale :source "elpaca-menu-lock-file" :recipe
        (:package "default-text-scale" :fetcher github :repo
            "purcell/default-text-scale" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e23b3f8d402dd3871ee5e6dacd10fda223128896"))
    (diff-hl :source "elpaca-menu-lock-file" :recipe
        (:package "diff-hl" :fetcher github :repo "dgutov/diff-hl"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9b032018fda8eb6c241bba1ec0e5c354ad523b2c"))
    (difftastic :source "elpaca-menu-lock-file" :recipe
        (:package "difftastic" :fetcher github :repo
            "pkryger/difftastic.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "57456cc42949f3d908800405de3c9cdb6448dbb0"))
    (disaster :source "elpaca-menu-lock-file" :recipe
        (:package "disaster" :repo "jart/disaster" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8b445913221feb0c196e943106643040118bcd77"))
    (docker :source "elpaca-menu-lock-file" :recipe
        (:package "docker" :fetcher github :repo "Silex/docker.el"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "464105ed8b193d8133a7d9e2b400876514cc4c95"))
    (docker-compose-mode :source "elpaca-menu-lock-file" :recipe
        (:package "docker-compose-mode" :repo
            "meqif/docker-compose-mode" :fetcher github :files
            (:defaults (:exclude "docker-compose-mode-helpers.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "abaa4f3aeb5c62d7d16e186dd7d77f4e846e126a"))
    (dockerfile-mode :source "elpaca-menu-lock-file" :recipe
        (:package "dockerfile-mode" :fetcher github :repo
            "spotify/dockerfile-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8135740bfc6ad96ab82d39d9fe68dbce56180f4c"))
    (doom-modeline :source "elpaca-menu-lock-file" :recipe
        (:package "doom-modeline" :repo "seagle0128/doom-modeline"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "a85cb28da8bcb29be232e21879f0f5a1e8551b8c"))
    (doom-themes :source "elpaca-menu-lock-file" :recipe
        (:package "doom-themes" :fetcher github :repo
            "doomemacs/themes" :files
            (:defaults "themes/*.el" "themes/*/*.el" "extensions/*.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "729ad034631cba41602ad9191275ece472c21941"))
    (dotenv-mode :source "elpaca-menu-lock-file" :recipe
        (:package "dotenv-mode" :repo "preetpalS/emacs-dotenv-mode"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e3701bf739bde44f6484eb7753deadaf691b73fb"))
    (dumb-jump :source "elpaca-menu-lock-file" :recipe
        (:package "dumb-jump" :repo "jacktasia/dumb-jump" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "42f97dea503367bf45c53a69de959177b06b0f59"))
    (eglot-booster :source "elpaca-menu-lock-file" :recipe
        (:source nil :protocol https :inherit t :depth treeless :host
            github :repo "jdtsmith/eglot-booster" :package
            "eglot-booster" :ref
            "1260d2f7dd18619b42359aa3e1ba6871aa52fd26"))
    (eldoc-box :source "elpaca-menu-lock-file" :recipe
        (:package "eldoc-box" :repo "casouri/eldoc-box" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "fb1ae42c37c5f3bb80b441b2fdfada914891a714"))
    (elfeed :source "elpaca-menu-lock-file" :recipe
        (:package "elfeed" :repo "skeeto/elfeed" :fetcher github
            :files (:defaults "README.md") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "a39fb78e34ee25dc8baea83376f929d7c128344f"))
    (elisp-refs :source "elpaca-menu-lock-file" :recipe
        (:package "elisp-refs" :repo "Wilfred/elisp-refs" :fetcher
            github :files (:defaults (:exclude "elisp-refs-bench.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "541a064c3ce27867872cf708354a65d83baf2a6d"))
    (elisp-slime-nav :source "elpaca-menu-lock-file" :recipe
        (:package "elisp-slime-nav" :repo "purcell/elisp-slime-nav"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "0b97339c552cac92788cab7c0724ca7ba160cd0e"))
    (elpaca :source
        "elpaca-menu-lock-file" :recipe
        (:source nil :protocol https :inherit ignore :depth 1 :repo
            "https://github.com/progfolio/elpaca.git" :ref
            "b5ef5f19ac1224853234c9acdac0ec9ea1c440a1" :files
            (:defaults "elpaca-test.el" (:exclude "extensions"))
            :build (:not elpaca--activate-package) :package "elpaca"))
    (elpaca-use-package :source "elpaca-menu-lock-file" :recipe
        (:package "elpaca-use-package" :wait t :repo
            "https://github.com/progfolio/elpaca.git" :files
            ("extensions/elpaca-use-package.el") :main
            "extensions/elpaca-use-package.el" :build
            (:not elpaca--compile-info) :source "Elpaca extensions"
            :protocol https :inherit t :depth treeless :ref
            "b5ef5f19ac1224853234c9acdac0ec9ea1c440a1"))
    (elquery :source "elpaca-menu-lock-file" :recipe
        (:package "elquery" :fetcher github :repo
            "AdamNiederer/elquery" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "38f3bd41096cb270919b06095da0b9ac1add4598"))
    (elysium :source "elpaca-menu-lock-file" :recipe
        (:package "elysium" :fetcher github :repo "lanceberge/elysium"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "049ad3091baf3ce578791187c5e5e4f932c26044"))
    (emacsql :source "elpaca-menu-lock-file" :recipe
        (:package "emacsql" :fetcher github :repo "magit/emacsql"
            :files (:defaults "README.md" "sqlite") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "ce7ad75af5ebb6b34f4520969e951be84cc768f2"))
    (embark :source "elpaca-menu-lock-file" :recipe
        (:package "embark" :repo "oantolin/embark" :fetcher github
            :files ("embark.el" "embark-org.el" "embark.texi") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "923d0ec52e2e3e0ae44e497c31c7888e87d08a8f"))
    (embark-consult :source "elpaca-menu-lock-file" :recipe
        (:package "embark-consult" :repo "oantolin/embark" :fetcher
            github :files ("embark-consult.el") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "923d0ec52e2e3e0ae44e497c31c7888e87d08a8f"))
    (emojify :source "elpaca-menu-lock-file" :recipe
        (:package "emojify" :fetcher github :repo
            "iqbalansari/emacs-emojify" :files
            (:defaults "data" "images") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "1b726412f19896abf5e4857d4c32220e33400b55"))
    (envrc :source "elpaca-menu-lock-file" :recipe
        (:package "envrc" :fetcher github :repo "purcell/envrc" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4ca2166ac72e756d314fc2348ce1c93d807c1a14"))
    (evil :source "elpaca-menu-lock-file" :recipe
        (:package "evil" :repo "emacs-evil/evil" :fetcher github
            :files
            (:defaults "doc/build/texinfo/evil.texi"
                (:exclude "evil-test-helpers.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "682e87fce99f39ea3155f11f87ee56b6e4593304"))
    (evil-args :source "elpaca-menu-lock-file" :recipe
        (:package "evil-args" :fetcher github :repo
            "wcsmith/evil-args" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "a8151556f63c9d45d0c44c8a7ef9e5a542f3cdc7"))
    (evil-collection :source "elpaca-menu-lock-file" :recipe
        (:package "evil-collection" :fetcher github :repo
            "emacs-evil/evil-collection" :files (:defaults "modes")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4748cfb78488fce96812130e0b53aae6d042ca6d"))
    (evil-escape :source "elpaca-menu-lock-file" :recipe
        (:package "evil-escape" :fetcher github :repo
            "emacsorphanage/evil-escape" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "aebd1a78a6bd33e5164e7552096b3fe1172d3012"))
    (evil-extra-operator :source "elpaca-menu-lock-file" :recipe
        (:package "evil-extra-operator" :fetcher github :repo
            "Dewdrops/evil-extra-operator" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "fb249889acacc3e28869491195391fa6f617ae56"))
    (evil-goggles :source "elpaca-menu-lock-file" :recipe
        (:package "evil-goggles" :repo "edkolev/evil-goggles" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "34ca276a85f615d2b45e714c9f8b5875bcb676f3"))
    (evil-indent-plus :source "elpaca-menu-lock-file" :recipe
        (:package "evil-indent-plus" :fetcher github :repo
            "TheBB/evil-indent-plus" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "f392696e4813f1d3a92c7eeed333248914ba6dae"))
    (evil-lion :source "elpaca-menu-lock-file" :recipe
        (:package "evil-lion" :fetcher github :repo
            "edkolev/evil-lion" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5a0bca151466960e090d1803c4c5ded88875f90a"))
    (evil-matchit :source "elpaca-menu-lock-file" :recipe
        (:package "evil-matchit" :fetcher github :repo
            "redguardtoo/evil-matchit" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8a94e56bd2987c6d0c1a85fbf189f9a86e623cde"))
    (evil-multiedit :source "elpaca-menu-lock-file" :recipe
        (:package "evil-multiedit" :repo "hlissner/evil-multiedit"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "23b53bc8743fb82a8854ba907b1d277374c93a79"))
    (evil-nerd-commenter :source "elpaca-menu-lock-file" :recipe
        (:package "evil-nerd-commenter" :fetcher github :repo
            "redguardtoo/evil-nerd-commenter" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "ae52c5070a48793e2c24474c9c8dbf20175d18a0"))
    (evil-numbers :source "elpaca-menu-lock-file" :recipe
        (:package "evil-numbers" :repo "juliapath/evil-numbers"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "f4bbb729eebeef26966fae17bd414a7b49f82275"))
    (evil-string-inflection :source "elpaca-menu-lock-file" :recipe
        (:package "evil-string-inflection" :repo
            "ninrod/evil-string-inflection" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "016938c2e05fbfd4a4738f7231151aadfcee0859"))
    (evil-surround :source "elpaca-menu-lock-file" :recipe
        (:package "evil-surround" :repo "emacs-evil/evil-surround"
            :fetcher github :old-names (surround) :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "da05c60b0621cf33161bb4335153f75ff5c29d91"))
    (evil-textobj-tree-sitter :source "elpaca-menu-lock-file" :recipe
        (:package "evil-textobj-tree-sitter" :fetcher github :repo
            "meain/evil-textobj-tree-sitter" :files
            (:defaults "queries" "treesit-queries") :old-names
            (evil-textobj-treesitter) :source "MELPA" :protocol https
            :inherit t :depth treeless :ref
            "bce236e5d2cc2fa4eae7d284ffd19ad18d46349a"))
    (evil-traces :source "elpaca-menu-lock-file" :recipe
        (:package "evil-traces" :repo "mamapanda/evil-traces" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "82e8a7b4213aed140f6eb5f2cc33a09bb5587166"))
    (evil-visualstar :source "elpaca-menu-lock-file" :recipe
        (:package "evil-visualstar" :repo "bling/evil-visualstar"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "06c053d8f7381f91c53311b1234872ca96ced752"))
    (exec-path-from-shell :source "elpaca-menu-lock-file" :recipe
        (:package "exec-path-from-shell" :fetcher github :repo
            "purcell/exec-path-from-shell" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4896a797252fbfdac32fb77508500ac7d220f717"))
    (expand-region :source "elpaca-menu-lock-file" :recipe
        (:package "expand-region" :repo "magnars/expand-region.el"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "351279272330cae6cecea941b0033a8dd8bcc4e8"))
    (explain-pause-mode :source "elpaca-menu-lock-file" :recipe
        (:source nil :protocol https :inherit t :depth treeless :type
            git :host github :repo "lastquestion/explain-pause-mode"
            :package "explain-pause-mode" :ref
            "ac3eb69f36f345506aad05a6d9bc3ef80d26914b"))
    (eyebrowse :source "elpaca-menu-lock-file" :recipe
        (:package "eyebrowse" :fetcher git :url
            "https://depp.brause.cc/eyebrowse.git" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "473381f4f9e847eb50a40ef2306c027432789754"))
    (f :source "elpaca-menu-lock-file" :recipe
        (:package "f" :fetcher github :repo "rejeep/f.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "931b6d0667fe03e7bf1c6c282d6d8d7006143c52"))
    (file-info :source "elpaca-menu-lock-file" :recipe
        (:package "file-info" :repo "Artawower/file-info.el" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "36fb3469a4d1c9d803e9d13e7e2e9582ced3043f"))
    (flycheck :source "elpaca-menu-lock-file" :recipe
        (:package "flycheck" :repo "flycheck/flycheck" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6f85589a3b3583aab597673c6a0907b2032572f7"))
    (flycheck-eglot :source "elpaca-menu-lock-file" :recipe
        (:package "flycheck-eglot" :fetcher github :repo
            "flycheck/flycheck-eglot" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "18d0c9869585e6a9ea5c40678f266cf7f5bb2d2e"))
    (flycheck-package :source "elpaca-menu-lock-file" :recipe
        (:package "flycheck-package" :fetcher github :repo
            "purcell/flycheck-package" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "a52e4e95f3151898b36739dfdb4a98b368626fc0"))
    (flycheck-rust :source "elpaca-menu-lock-file" :recipe
        (:package "flycheck-rust" :repo "flycheck/flycheck-rust"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6c41144940a2d90c1b54979e8f00fbb4a59add7e"))
    (flyspell-correct :source "elpaca-menu-lock-file" :recipe
        (:package "flyspell-correct" :repo
            "d12frosted/flyspell-correct" :fetcher github :files
            ("flyspell-correct.el" "flyspell-correct-ido.el") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "1e7a5a56362dd875dddf848b9a9e25d1395b9d37"))
    (forge :source "elpaca-menu-lock-file" :recipe
        (:package "forge" :fetcher github :repo "magit/forge" :files
            ("lisp/*.el" "docs/*.texi" ".dir-locals.el") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "4c5416e8654cad4d4bfb0ee5c8526e2d8d336569"))
    (fzf :source "elpaca-menu-lock-file" :recipe
        (:package "fzf" :repo "bling/fzf.el" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "641aef33c88df3733f13d559bcb2acc548a4a0c3"))
    (gc-buffers :source "elpaca-menu-lock-file" :recipe
        (:package "gc-buffers" :repo
            ("https://codeberg.org/akib/emacs-gc-buffers"
                . "gc-buffers")
            :files ("*" (:exclude ".git")) :source "NonGNU ELPA"
            :protocol https :inherit t :depth treeless :ref
            "ce2ea016a67b200862788e81f0ff1f8f7e4e0454"))
    (gcmh :source "elpaca-menu-lock-file" :recipe
        (:package "gcmh" :repo "koral/gcmh" :fetcher gitlab :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "0089f9c3a6d4e9a310d0791cf6fa8f35642ecfd9"))
    (general :source "elpaca-menu-lock-file" :recipe
        (:package "general" :fetcher github :repo "noctuid/general.el"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "826bf2b97a0fb4a34c5eb96ec2b172d682fd548f"))
    (gh-md :source "elpaca-menu-lock-file" :recipe
        (:package "gh-md" :fetcher github :repo "emacsorphanage/gh-md"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e721fd5e41e682f47f2dd4ce26ef2ba28c7fa0b5"))
    (ghub :source "elpaca-menu-lock-file" :recipe
        (:package "ghub" :fetcher github :repo "magit/ghub" :files
            ("lisp/*.el" "docs/*.texi" ".dir-locals.el") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "6bb612e7b7eada22569d84cc529f4ca36e08032d"))
    (git-link :source "elpaca-menu-lock-file" :recipe
        (:package "git-link" :fetcher github :repo "sshaw/git-link"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8d0f98cf36f6b9c31285329b054ae77f9a3d9b33"))
    (git-messenger :source "elpaca-menu-lock-file" :recipe
        (:package "git-messenger" :repo "emacsorphanage/git-messenger"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "eade986ef529aa2dac6944ad61b18de55cee0b76"))
    (git-timemachine :source "elpaca-menu-lock-file" :recipe
        (:package "git-timemachine" :fetcher codeberg :repo
            "pidu/git-timemachine" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "d1346a76122595aeeb7ebb292765841c6cfd417b"))
    (gleam-ts-mode :source "elpaca-menu-lock-file" :recipe
        (:package "gleam-ts-mode" :fetcher github :repo
            "gleam-lang/gleam-mode" :files ("gleam-ts-mode.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8e981614536f0e36fb14721a9fae8bf72c287a40"))
    (gntp :source "elpaca-menu-lock-file" :recipe
        (:package "gntp" :repo "tekai/gntp.el" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "767571135e2c0985944017dc59b0be79af222ef5"))
    (go-errcheck :source "elpaca-menu-lock-file" :recipe
        (:package "go-errcheck" :repo "dominikh/go-errcheck.el"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9db21eccecedc2490793f176246094167164af31"))
    (go-fill-struct :source "elpaca-menu-lock-file" :recipe
        (:package "go-fill-struct" :repo "s-kostyaev/go-fill-struct"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9e2e4be5af716ecadba809e73ddc95d4c772b2d9"))
    (go-gen-test :source "elpaca-menu-lock-file" :recipe
        (:package "go-gen-test" :fetcher github :repo
            "s-kostyaev/go-gen-test" :files ("go-gen-test.el") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "af00a9abbaba2068502327ecdef574fd894a884b"))
    (go-mode :source "elpaca-menu-lock-file" :recipe
        (:package "go-mode" :repo "dominikh/go-mode.el" :fetcher
            github :files ("go-mode.el") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "0ed3c5227e7f622589f1411b4939c3ee34711ebd"))
    (go-tag :source "elpaca-menu-lock-file" :recipe
        (:package "go-tag" :repo "brantou/emacs-go-tag" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "33f2059551d5298ca228d90f525b99d1a8d70364"))
    (goggles :source "elpaca-menu-lock-file" :recipe
        (:package "goggles" :repo "minad/goggles" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5176114e99d4c13f57777abbcbcea0dbee9e4ca3"))
    (google-this :source "elpaca-menu-lock-file" :recipe
        (:package "google-this" :repo "Malabarba/emacs-google-this"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "abdcb565503844e2146de42ab5ba898e90a2bb09"))
    (google-translate :source "elpaca-menu-lock-file" :recipe
        (:package "google-translate" :fetcher github :repo
            "atykhonov/google-translate" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e84599df7c70870b33dd6c902b527d7f78310815"))
    (gotest :source "elpaca-menu-lock-file" :recipe
        (:package "gotest" :fetcher github :repo
            "nlamirault/gotest.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "490189e68d743a851bfb42d0017428a7550e8615"))
    (goto-chg :source "elpaca-menu-lock-file" :recipe
        (:package "goto-chg" :repo "emacs-evil/goto-chg" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "72f556524b88e9d30dc7fc5b0dc32078c166fda7"))
    (goto-last-change :source "elpaca-menu-lock-file" :recipe
        (:package "goto-last-change" :repo
            "camdez/goto-last-change.el" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "58b0928bc255b47aad318cd183a5dce8f62199cc"))
    (gptel :source "elpaca-menu-lock-file" :recipe
        (:package "gptel" :repo "karthink/gptel" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "22f743287c011f8c31b1f123a2e38a502e28f474"))
    (gradle-mode :source "elpaca-menu-lock-file" :recipe
        (:package "gradle-mode" :fetcher github :repo
            "scubacabra/emacs-gradle-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e4d665d5784ecda7ddfba015f07c69be3cfc45f2"))
    (groovy-mode :source "elpaca-menu-lock-file" :recipe
        (:package "groovy-mode" :fetcher github :repo
            "Groovy-Emacs-Modes/groovy-emacs-modes" :files
            ("*groovy*.el") :source "MELPA" :protocol https :inherit t
            :depth treeless :ref
            "7b8520b2e2d3ab1d62b35c426e17ac25ed0120bb"))
    (hcl-mode :source "elpaca-menu-lock-file" :recipe
        (:package "hcl-mode" :repo "hcl-emacs/hcl-mode" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1da895ed75d28d9f87cbf9b74f075d90ba31c0ed"))
    (helpful :source "elpaca-menu-lock-file" :recipe
        (:package "helpful" :repo "Wilfred/helpful" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "03756fa6ad4dcca5e0920622b1ee3f70abfc4e39"))
    (hide-mode-line :source "elpaca-menu-lock-file" :recipe
        (:package "hide-mode-line" :repo
            "hlissner/emacs-hide-mode-line" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "ddd154f1e04d666cd004bf8212ead8684429350d"))
    (highlight-numbers :source "elpaca-menu-lock-file" :recipe
        (:package "highlight-numbers" :fetcher github :repo
            "Fanael/highlight-numbers" :old-names
            (number-font-lock-mode) :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8b4744c7f46c72b1d3d599d4fb75ef8183dee307"))
    (ht :source "elpaca-menu-lock-file" :recipe
        (:package "ht" :fetcher github :repo "Wilfred/ht.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1c49aad1c820c86f7ee35bf9fff8429502f60fef"))
    (hydra :source "elpaca-menu-lock-file" :recipe
        (:package "hydra" :repo "abo-abo/hydra" :fetcher github :files
            (:defaults (:exclude "lv.el")) :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "59a2a45a35027948476d1d7751b0f0215b1e61aa"))
    (iedit :source "elpaca-menu-lock-file" :recipe
        (:package "iedit" :repo "victorhge/iedit" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "27c61866b1b9b8d77629ac702e5f48e67dfe0d3b"))
    (indent-bars :source "elpaca-menu-lock-file" :recipe
        (:package "indent-bars" :repo "jdtsmith/indent-bars" :files
            ("*" (:exclude ".git" "LICENSE")) :source "GNU ELPA"
            :protocol https :inherit t :depth treeless :host github
            :ref "30b47adfaa3fc947ef1f2b93e943641a0a2985d3"))
    (inheritenv :source "elpaca-menu-lock-file" :recipe
        (:package "inheritenv" :fetcher github :repo
            "purcell/inheritenv" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "b9e67cc20c069539698a9ac54d0e6cc11e616c6f"))
    (jinja2-mode :source "elpaca-menu-lock-file" :recipe
        (:package "jinja2-mode" :fetcher github :repo
            "paradoxxxzero/jinja2-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "03e5430a7efe1d163a16beaf3c82c5fd2c2caee1"))
    (jq-mode :source "elpaca-menu-lock-file" :recipe
        (:package "jq-mode" :repo "ljos/jq-mode" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1f4bf0955fc9f7f03d8b26dc1acf6b68067a57cc"))
    (jq-ts-mode :source "elpaca-menu-lock-file" :recipe
        (:package "jq-ts-mode" :repo "nverno/jq-ts-mode" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "3ac689c3c38be9117076de0bcc15510e369016c9"))
    (js2-mode :source "elpaca-menu-lock-file" :recipe
        (:package "js2-mode" :repo "mooz/js2-mode" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e0c302872de4d26a9c1614fac8d6b94112b96307"))
    (json-mode :source "elpaca-menu-lock-file" :recipe
        (:package "json-mode" :fetcher github :repo
            "json-emacs/json-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "466d5b563721bbeffac3f610aefaac15a39d90a9"))
    (json-reformat :source "elpaca-menu-lock-file" :recipe
        (:package "json-reformat" :fetcher github :repo
            "gongo/json-reformat" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9120ab67c5379c44bc7a7a07ca858670cea4f32f"))
    (json-snatcher :source "elpaca-menu-lock-file" :recipe
        (:package "json-snatcher" :fetcher github :repo
            "Sterlingg/json-snatcher" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "b28d1c0670636da6db508d03872d96ffddbc10f2"))
    (jsonian :source "elpaca-menu-lock-file" :recipe
        (:package "jsonian" :fetcher github :repo "iwahbe/jsonian"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :type git :host github :ref
            "513219ebb3ccdefc915715e4bf2dd6e718fabccd"))
    (just-mode :source "elpaca-menu-lock-file" :recipe
        (:package "just-mode" :repo "leon-barrett/just-mode.el"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4c0df4cc4b8798f1a7e99fb78b79c4bf7eec12c1"))
    (justl :source "elpaca-menu-lock-file" :recipe
        (:package "justl" :repo "psibi/justl.el" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e83b26671033ee57c4295e9ac6707b5659f7af05"))
    (k8s-mode :source "elpaca-menu-lock-file" :recipe
        (:package "k8s-mode" :fetcher github :repo
            "TxGVNN/emacs-k8s-mode" :files
            ("*.el" ("snippets/k8s-mode" "snippets/k8s-mode/*"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "39a189d1e030aa108e90a82fd40f0042b1e69b21"))
    (keypression :source "elpaca-menu-lock-file" :recipe
        (:package "keypression" :repo "chuntaro/emacs-keypression"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e85e3fd9ce216a370be221cf9de1503777ef0088"))
    (kind-icon :source "elpaca-menu-lock-file" :recipe
        (:package "kind-icon" :repo
            ("https://github.com/jdtsmith/kind-icon" . "kind-icon")
            :files ("*" (:exclude ".git")) :source "GNU ELPA"
            :protocol https :inherit t :depth treeless :ref
            "556b0fb92aac24979b2c501431c7d48f75a5169f"))
    (kotlin-mode :source "elpaca-menu-lock-file" :recipe
        (:package "kotlin-mode" :repo
            "Emacs-Kotlin-Mode-Maintainers/kotlin-mode" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "fddd747e5b4736e8b27a147960f369b86179ddff"))
    (kubedoc :source "elpaca-menu-lock-file" :recipe
        (:package "kubedoc" :fetcher github :repo "r0bobo/kubedoc.el"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "76fda90b68a7724b02c7c089a8f0deaf36705cf6"))
    (kubel :source "elpaca-menu-lock-file" :recipe
        (:package "kubel" :fetcher github :repo "abrochard/kubel"
            :files (:defaults (:exclude "kubel-evil.el")) :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "82f90a8a6cca662baa9a66db4a708b2e906720cb"))
    (kubel-evil :source "elpaca-menu-lock-file" :recipe
        (:package "kubel-evil" :repo "abrochard/kubel" :fetcher github
            :files ("kubel-evil.el") :source "MELPA" :protocol https
            :inherit t :depth treeless :ref
            "82f90a8a6cca662baa9a66db4a708b2e906720cb"))
    (kubernetes :source "elpaca-menu-lock-file" :recipe
        (:package "kubernetes" :repo "kubernetes-el/kubernetes-el"
            :fetcher github :files
            (:defaults (:exclude "kubernetes-evil.el")) :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "5cb580d0e1d18a97ec4d0ba33b374a0822a96d4f"))
    (kubernetes-evil :source "elpaca-menu-lock-file" :recipe
        (:package "kubernetes-evil" :repo
            "kubernetes-el/kubernetes-el" :fetcher github :files
            ("kubernetes-evil.el") :source "MELPA" :protocol https
            :inherit t :depth treeless :ref
            "5cb580d0e1d18a97ec4d0ba33b374a0822a96d4f"))
    (ligature :source "elpaca-menu-lock-file" :recipe
        (:package "ligature" :fetcher github :repo
            "mickeynp/ligature.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :host github :ref
            "6ac1634612dbd42f7eb81ecaf022bd239aabb954"))
    (llama :source "elpaca-menu-lock-file" :recipe
        (:package "llama" :fetcher github :repo "tarsius/llama" :files
            ("llama.el" ".dir-locals.el") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "7de288e79329bfb3e2b4a2f9b574cf834bd371dd"))
    (log4e :source "elpaca-menu-lock-file" :recipe
        (:package "log4e" :repo "aki2o/log4e" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6d71462df9bf595d3861bfb328377346aceed422"))
    (lsp-mode :source "elpaca-menu-lock-file" :recipe
        (:package "lsp-mode" :repo "emacs-lsp/lsp-mode" :fetcher
            github :files (:defaults "clients/*.*") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "e15a99696edc67781bc2bb655e8d9d056fb04416"))
    (lsp-pyright :source "elpaca-menu-lock-file" :recipe
        (:package "lsp-pyright" :repo "emacs-lsp/lsp-pyright" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "73377169beff8fe22cc6d52d65099db88bf49679"))
    (lsp-tailwindcss :source "elpaca-menu-lock-file" :recipe
        (:package "lsp-tailwindcss" :repo "merrickluo/lsp-tailwindcss"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :type git :host github :ref
            "294121ada4feb4f4ad4d1a8b2dc69de89d518d31"))
    (lsp-ui :source "elpaca-menu-lock-file" :recipe
        (:package "lsp-ui" :repo "emacs-lsp/lsp-ui" :fetcher github
            :files (:defaults "lsp-ui-doc.html" "resources") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "a0dde8b52b4411cbac2eb053ef1515635ea0b7ed"))
    (lua-mode :source "elpaca-menu-lock-file" :recipe
        (:package "lua-mode" :repo "immerrr/lua-mode" :fetcher github
            :files (:defaults (:exclude "init-tryout.el")) :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "2f6b8d7a6317e42c953c5119b0119ddb337e0a5f"))
    (lv :source "elpaca-menu-lock-file" :recipe
        (:package "lv" :repo "abo-abo/hydra" :fetcher github :files
            ("lv.el") :source "MELPA" :protocol https :inherit t
            :depth treeless :ref
            "59a2a45a35027948476d1d7751b0f0215b1e61aa"))
    (magit :source "elpaca-menu-lock-file" :recipe
        (:package "magit" :fetcher github :repo "magit/magit" :files
            ("lisp/magit*.el" "lisp/git-*.el" "docs/magit.texi"
                "docs/AUTHORS.md" "LICENSE" ".dir-locals.el"
                (:exclude "lisp/magit-section.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "0c134614665c70552aff6786844e4792365ff7e5"))
    (magit-popup :source "elpaca-menu-lock-file" :recipe
        (:package "magit-popup" :fetcher github :repo
            "magit/magit-popup" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "d8585fa39f88956963d877b921322530257ba9f5"))
    (magit-section :source "elpaca-menu-lock-file" :recipe
        (:package "magit-section" :fetcher github :repo "magit/magit"
            :files
            ("lisp/magit-section.el" "docs/magit-section.texi"
                "magit-section-pkg.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "0c134614665c70552aff6786844e4792365ff7e5"))
    (marginalia :source "elpaca-menu-lock-file" :recipe
        (:package "marginalia" :repo "minad/marginalia" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "3cfba58cd56bdf5c12609a8bfc89fb97f3df37b0"))
    (markdown-mode :source "elpaca-menu-lock-file" :recipe
        (:package "markdown-mode" :fetcher github :repo
            "jrblevin/markdown-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "90ad4af79a8bb65a3a5cdd6314be44abd9517cfc"))
    (markdown-preview-mode :source "elpaca-menu-lock-file" :recipe
        (:package "markdown-preview-mode" :fetcher github :repo
            "ancane/markdown-preview-mode" :files
            (:defaults "preview.html" "favicon.ico") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "68242b3907dc065aa35412bfd928b43d8052d321"))
    (mcp :source "elpaca-menu-lock-file" :recipe
        (:package "mcp" :fetcher github :repo "lizqwerscott/mcp.el"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5288951946664271ded8faa26aed72ed2f2f0b64"))
    (move-text :source "elpaca-menu-lock-file" :recipe
        (:package "move-text" :fetcher github :repo
            "emacsfodder/move-text" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "2a8ebefeb0b363681e9562847eca3fd66e090d70"))
    (multi-vterm :source "elpaca-menu-lock-file" :recipe
        (:package "multi-vterm" :fetcher github :repo
            "suonlight/multi-vterm" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "36746d85870dac5aaee6b9af4aa1c3c0ef21a905"))
    (neotree :source "elpaca-menu-lock-file" :recipe
        (:package "neotree" :repo "jaypei/emacs-neotree" :fetcher
            github :files (:defaults "icons") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "4a4cd8576157a39c0fdb478a2887c01ccfe1aec9"))
    (nerd-icons :source "elpaca-menu-lock-file" :recipe
        (:package "nerd-icons" :repo "rainstormstudio/nerd-icons.el"
            :fetcher github :files (:defaults "data") :source "MELPA"
            :protocol https :inherit t :depth treeless :type git :host
            github :ref "d972dee349395ffae8fceae790d22fedc8fe08e8"))
    (nix-mode :source "elpaca-menu-lock-file" :recipe
        (:package "nix-mode" :fetcher github :repo "NixOS/nix-mode"
            :files
            (:defaults (:exclude "nix-company.el" "nix-mode-mmm.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "719feb7868fb567ecfe5578f6119892c771ac5e5"))
    (nix-ts-mode :source "elpaca-menu-lock-file" :recipe
        (:package "nix-ts-mode" :fetcher github :repo
            "nix-community/nix-ts-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "62ce3a2dc39529c5db3516427e84b2c96b8efcfd"))
    (no-littering :source "elpaca-menu-lock-file" :recipe
        (:package "no-littering" :fetcher github :repo
            "emacscollective/no-littering" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5596cc6586b3d1ce77d7c9e5385a0809fbad4eb6"))
    (ns-auto-titlebar :source "elpaca-menu-lock-file" :recipe
        (:package "ns-auto-titlebar" :fetcher github :repo
            "purcell/ns-auto-titlebar" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1205ac67b76b58e9eb53d2115b85775533653a80"))
    (orderless :source "elpaca-menu-lock-file" :recipe
        (:package "orderless" :repo "oantolin/orderless" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "254f2412489bbbf62700f9d3d5f18e537841dcc3"))
    (org :source "elpaca-menu-lock-file" :recipe
        (:package "org" :pre-build
            (progn
                (require 'elpaca-menu-org)
                (setq elpaca-menu-org-make-manual t)
                (elpaca-menu-org--build))
            :host github :repo "emacsmirror/org" :autoloads
            "org-loaddefs.el" :depth treeless :build
            (:not elpaca--generate-autoloads-async) :files
            (:defaults ("etc/styles/" "etc/styles/*" "doc/*.texi"))
            :source "Org" :protocol https :inherit t :ref
            "7eafc194d2c3a42b84a319847f66ec6bdfea183c"))
    (org-superstar :source "elpaca-menu-lock-file" :recipe
        (:package "org-superstar" :fetcher github :repo
            "integral-dw/org-superstar-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "54c81c27dde2a6dc461bb064e79a8b2089093a2e"))
    (orgtbl-aggregate :source "elpaca-menu-lock-file" :recipe
        (:package "orgtbl-aggregate" :fetcher github :repo
            "tbanel/orgaggregate" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "988ea09d22a4a04e8ecf572e3ff13da4aa0db66c"))
    (ox-gfm :source "elpaca-menu-lock-file" :recipe
        (:package "ox-gfm" :fetcher github :repo "larstvei/ox-gfm"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "4f774f13d34b3db9ea4ddb0b1edc070b1526ccbb"))
    (package-lint :source "elpaca-menu-lock-file" :recipe
        (:package "package-lint" :fetcher github :repo
            "purcell/package-lint" :files
            (:defaults "data" (:exclude "*flymake.el")) :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "2dc48e5fb9c37390d9290d4f5ab371c39b7a3829"))
    (page-break-lines :source "elpaca-menu-lock-file" :recipe
        (:package "page-break-lines" :fetcher github :repo
            "purcell/page-break-lines" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "982571749c8fe2b5e2997dd043003a1b9fe87b38"))
    (parent-mode :source "elpaca-menu-lock-file" :recipe
        (:package "parent-mode" :fetcher github :repo
            "Fanael/parent-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "fbd49857ab2e4cd0c5611c0cc83f93711657b298"))
    (pet :source "elpaca-menu-lock-file" :recipe
        (:package "pet" :fetcher github :repo "wyuenho/emacs-pet"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1abf16ebe1f4280fc2f875b4e99d8c26756d0f36"))
    (pfuture :source "elpaca-menu-lock-file" :recipe
        (:package "pfuture" :repo "Alexander-Miller/pfuture" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "19b53aebbc0f2da31de6326c495038901bffb73c"))
    (plantuml-mode :source "elpaca-menu-lock-file" :recipe
        (:package "plantuml-mode" :fetcher github :repo
            "skuro/plantuml-mode" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5e6b505c0695f75666a571b9e6fe1d52fa3ec34d"))
    (poly-org :source "elpaca-menu-lock-file" :recipe
        (:package "poly-org" :fetcher github :repo "polymode/poly-org"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "90d9ca9f440d3b6c03b185353edd37a100559ec4"))
    (polymode :source "elpaca-menu-lock-file" :recipe
        (:package "polymode" :fetcher github :repo "polymode/polymode"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "14b3abc1e2467707398b6e7e5852b56f1463994b"))
    (popup :source "elpaca-menu-lock-file" :recipe
        (:package "popup" :fetcher github :repo
            "auto-complete/popup-el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "24dd22186403a6566c26ce4996cdb1eedb1cc5cd"))
    (posframe :source "elpaca-menu-lock-file" :recipe
        (:package "posframe" :fetcher github :repo "tumashu/posframe"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "12f540c9ad5da09673b2bca1132b41f94c134e82"))
    (powershell :source "elpaca-menu-lock-file" :recipe
        (:package "powershell" :repo "jschaf/powershell.el" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9efa1b4d0a3cc5c0caae166c144a0f76b1d0e5f4"))
    (projectile :source "elpaca-menu-lock-file" :recipe
        (:package "projectile" :fetcher github :repo
            "bbatsov/projectile" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "0212d15f0cfb4b5de1879250072a9ee45cf298c2"))
    (projection :source "elpaca-menu-lock-file" :recipe
        (:package "projection" :fetcher github :repo
            "mohkale/projection" :files (:defaults "src/*.el") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "50d4f0ec4edfddd24f7c1c540f299a919aa4c151"))
    (projection-multi :source "elpaca-menu-lock-file" :recipe
        (:package "projection-multi" :fetcher github :repo
            "mohkale/projection" :files ("src/projection-multi/*.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "50d4f0ec4edfddd24f7c1c540f299a919aa4c151"))
    (projection-multi-embark :source "elpaca-menu-lock-file" :recipe
        (:package "projection-multi-embark" :fetcher github :repo
            "mohkale/projection" :files
            ("src/projection-multi-embark/projection-multi-embark*.el")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "50d4f0ec4edfddd24f7c1c540f299a919aa4c151"))
    (protobuf-mode :source "elpaca-menu-lock-file" :recipe
        (:package "protobuf-mode" :fetcher github :repo
            "protocolbuffers/protobuf" :files
            ("editors/protobuf-mode.el") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "5803b241c1df7a897d704103a88f1bb884d2b0c0"))
    (python-mode :source "elpaca-menu-lock-file" :recipe
        (:package "python-mode" :fetcher gitlab :repo
            "python-mode-devs/python-mode" :files
            ("python-mode.el" ("completion" "completion/pycomplete.*"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1d184822bdcdc1d41536597b29948bc5a12a583e"))
    (python-pytest :source "elpaca-menu-lock-file" :recipe
        (:package "python-pytest" :fetcher github :repo
            "wbolster/emacs-python-pytest" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "25d9801562a789ea5debceb1992bd528ebb4f689"))
    (quickrun :source "elpaca-menu-lock-file" :recipe
        (:package "quickrun" :repo "emacsorphanage/quickrun" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "bae8efb8c5bc428e4df731b5c214aae478c707da"))
    (rainbow-delimiters :source "elpaca-menu-lock-file" :recipe
        (:package "rainbow-delimiters" :fetcher github :repo
            "Fanael/rainbow-delimiters" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "f40ece58df8b2f0fb6c8576b527755a552a5e763"))
    (rainbow-mode :source "elpaca-menu-lock-file" :recipe
        (:package "rainbow-mode" :repo
            ("https://github.com/emacsmirror/gnu_elpa"
                . "rainbow-mode")
            :branch "externals/rainbow-mode" :files
            ("*" (:exclude ".git")) :source "GNU ELPA" :protocol https
            :inherit t :depth treeless :ref
            "f7db3b5919f70420a91eb199f8663468de3033f3"))
    (request :source "elpaca-menu-lock-file"
        :recipe
        (:package "request" :repo "tkf/emacs-request" :fetcher github
            :files ("request.el") :source "MELPA" :protocol https
            :inherit t :depth treeless :ref
            "c22e3c23a6dd90f64be536e176ea0ed6113a5ba6"))
    (restart-emacs :source "elpaca-menu-lock-file" :recipe
        (:package "restart-emacs" :fetcher github :repo
            "iqbalansari/restart-emacs" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "1607da2bc657fe05ae01f7fdf26f716eafead02c"))
    (rg :source "elpaca-menu-lock-file" :recipe
        (:package "rg" :fetcher github :repo "dajva/rg.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "94813ba3a7ccf3af68beb23a2c39154a99e8c9ec"))
    (ruby-tools :source "elpaca-menu-lock-file" :recipe
        (:package "ruby-tools" :repo "rejeep/ruby-tools.el" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6b97066b58a4f82eb2ecea6434a0a7e981aa4c18"))
    (run-command :source "elpaca-menu-lock-file" :recipe
        (:package "run-command" :fetcher github :repo
            "bard/emacs-run-command" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "eff52e04ca371ee1682c7ce27908ec6f66680b11"))
    (rust-mode :source "elpaca-menu-lock-file" :recipe
        (:package "rust-mode" :repo "rust-lang/rust-mode" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "25d91cff281909e9b7cb84e31211c4e7b0480f94"))
    (rvm :source "elpaca-menu-lock-file" :recipe
        (:package "rvm" :repo "senny/rvm.el" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e1e83b5466c132c066142ac63729ba833c530c83"))
    (s :source "elpaca-menu-lock-file" :recipe
        (:package "s" :fetcher github :repo "magnars/s.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "dda84d38fffdaf0c9b12837b504b402af910d01d"))
    (scratch-comment :source "elpaca-menu-lock-file" :recipe
        (:package "scratch-comment" :fetcher github :repo
            "conao3/scratch-comment.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "cf3e967b4def1308b6ef1cfeedd2cf15ee6e226c"))
    (shrink-path :source "elpaca-menu-lock-file" :recipe
        (:package "shrink-path" :fetcher gitlab :repo
            "bennya/shrink-path.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "c14882c8599aec79a6e8ef2d06454254bb3e1e41"))
    (smartparens :source "elpaca-menu-lock-file" :recipe
        (:package "smartparens" :fetcher github :repo
            "Fuco1/smartparens" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "603325ab3d1186fb10da5c2a7ec1afb88018d792"))
    (sops :source "elpaca-menu-lock-file" :recipe
        (:package "sops" :fetcher github :repo "djgoku/sops" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "afeb1232b89335d77a3f4b6639ebe8a2b70fae3f"))
    (spinner :source "elpaca-menu-lock-file" :recipe
        (:package "spinner" :repo
            ("https://github.com/Malabarba/spinner.el" . "spinner")
            :files ("*" (:exclude ".git")) :source "GNU ELPA"
            :protocol https :inherit t :depth treeless :ref
            "d4647ae87fb0cd24bc9081a3d287c860ff061c21"))
    (ssh-config-mode :source "elpaca-menu-lock-file" :recipe
        (:package "ssh-config-mode" :fetcher github :repo
            "peterhoeg/ssh-config-mode-el" :files (:defaults "*.txt")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "d0596f5fbeab3d2c3c30eb83527316403bc5b2f7"))
    (string-inflection :source "elpaca-menu-lock-file" :recipe
        (:package "string-inflection" :fetcher github :repo
            "akicho8/string-inflection" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "617df25e91351feffe6aff4d9e4724733449d608"))
    (svg-lib :source "elpaca-menu-lock-file" :recipe
        (:package "svg-lib" :repo
            ("https://github.com/rougier/svg-lib" . "svg-lib") :files
            ("*" (:exclude ".git")) :source "GNU ELPA" :protocol https
            :inherit t :depth treeless :ref
            "39621cd178dbf903414156d893c1eefe217b7c29"))
    (tablist :source "elpaca-menu-lock-file" :recipe
        (:package "tablist" :fetcher github :repo
            "emacsorphanage/tablist" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "fcd37147121fabdf003a70279cf86fbe08cfac6f"))
    (terraform-mode :source "elpaca-menu-lock-file" :recipe
        (:package "terraform-mode" :repo "hcl-emacs/terraform-mode"
            :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "5bdd734a87f67f6574664f63eb4d02a0bc74c0d0"))
    (textsize :source "elpaca-menu-lock-file" :recipe
        (:package "textsize" :repo "WJCFerguson/textsize" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :type git :host github :ref
            "d61fd65d823b17ff71a61fba5590a9e9b60e0e92"))
    (toc-org :source "elpaca-menu-lock-file" :recipe
        (:package "toc-org" :fetcher github :repo "snosov1/toc-org"
            :old-names (org-toc) :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6d3ae0fc47ce79b1ea06cabe21a3c596395409cd"))
    (toml-mode :source "elpaca-menu-lock-file" :recipe
        (:package "toml-mode" :fetcher github :repo
            "dryman/toml-mode.el" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "f6c61817b00f9c4a3cab1bae9c309e0fc45cdd06"))
    (transient :source "elpaca-menu-lock-file" :recipe
        (:package "transient" :fetcher github :repo "magit/transient"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "cb6550d5b111b7815feec97b236ecb051de70dbe"))
    (tree-sitter :source "elpaca-menu-lock-file" :recipe
        (:package "tree-sitter" :fetcher github :repo
            "emacs-tree-sitter/elisp-tree-sitter" :branch "release"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "3cfab8a0e945db9b3df84437f27945746a43cc71"))
    (tree-sitter-langs :source "elpaca-menu-lock-file" :recipe
        (:package "tree-sitter-langs" :repo
            "emacs-tree-sitter/tree-sitter-langs" :fetcher github
            :branch "release" :files (:defaults "queries") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "3aa35be257d8716d3614166fabdef12ef04e816e"))
    (treemacs :source "elpaca-menu-lock-file" :recipe
        (:package "treemacs" :fetcher github :repo
            "Alexander-Miller/treemacs" :files
            (:defaults "Changelog.org" "icons"
                "src/elisp/treemacs*.el" "src/scripts/treemacs*.py"
                (:exclude "src/extra/*"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "820b09db106a48db76d95e3a266d1e67ae1b6bdb"))
    (treemacs-evil :source "elpaca-menu-lock-file" :recipe
        (:package "treemacs-evil" :fetcher github :repo
            "Alexander-Miller/treemacs" :files
            ("src/extra/treemacs-evil.el") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "820b09db106a48db76d95e3a266d1e67ae1b6bdb"))
    (treemacs-projectile :source "elpaca-menu-lock-file" :recipe
        (:package "treemacs-projectile" :fetcher github :repo
            "Alexander-Miller/treemacs" :files
            ("src/extra/treemacs-projectile.el") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "820b09db106a48db76d95e3a266d1e67ae1b6bdb"))
    (treepy :source "elpaca-menu-lock-file" :recipe
        (:package "treepy" :repo "volrath/treepy.el" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "651e2634f01f346da9ec8a64613c51f54b444bc3"))
    (try :source "elpaca-menu-lock-file" :recipe
        (:package "try" :fetcher github :repo "larstvei/Try" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "8831ded1784df43a2bd56c25ad3d0650cdb9df1d"))
    (tsc :source "elpaca-menu-lock-file" :recipe
        (:package "tsc" :fetcher github :repo
            "emacs-tree-sitter/elisp-tree-sitter" :branch "release"
            :files
            ("core/*.el" "core/Cargo.toml" "core/Cargo.lock"
                "core/src")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "3cfab8a0e945db9b3df84437f27945746a43cc71"))
    (undo-fu :source "elpaca-menu-lock-file" :recipe
        (:package "undo-fu" :fetcher codeberg :repo
            "ideasman42/emacs-undo-fu" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "399cc12f907f81a709f9014b6fad0205700d5772"))
    (undohist :source "elpaca-menu-lock-file" :recipe
        (:package "undohist" :fetcher github :repo
            "emacsorphanage/undohist" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "307c0fbaab630595c0fc1f112cf7ac5a0c4c4a26"))
    (valign :source "elpaca-menu-lock-file" :recipe
        (:package "valign" :repo
            ("https://github.com/casouri/valign" . "valign") :files
            ("*" (:exclude ".git")) :source "GNU ELPA" :protocol https
            :inherit t :depth treeless :ref
            "be82f6048118cbc81e6e029be1965f933612d871"))
    (vdiff :source "elpaca-menu-lock-file" :recipe
        (:package "vdiff" :repo "justbur/emacs-vdiff" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "170e968c6a46a572b30c52c1b038232d418734cc"))
    (vertico :source "elpaca-menu-lock-file" :recipe
        (:package "vertico" :repo "minad/vertico" :files
            (:defaults "extensions/*") :fetcher github :source "MELPA"
            :protocol https :inherit t :depth treeless :includes
            (vertico-indexed vertico-mouse vertico-quick
                vertico-directory vertico-repeat vertico-buffer
                vertico-multiform vertico-reverse vertico-flat
                vertico-grid vertico-unobtrusive)
            :ref "bb6abf63cc439601cd65682cfd549e4b6d63d409"))
    (vertico-posframe :source "elpaca-menu-lock-file" :recipe
        (:package "vertico-posframe" :repo
            ("https://github.com/tumashu/vertico-posframe"
                . "vertico-posframe")
            :files ("*" (:exclude ".git")) :source "GNU ELPA"
            :protocol https :inherit t :depth treeless :ref
            "c5a8b5f72a582e88a2a696a3bbc2df7af28bd229"))
    (vterm :source "elpaca-menu-lock-file" :recipe
        (:package "vterm" :fetcher github :repo
            "akermu/emacs-libvterm" :files
            ("CMakeLists.txt" "elisp.c" "elisp.h" "emacs-module.h"
                "etc" "utf8.c" "utf8.h" "vterm.el" "vterm-module.c"
                "vterm-module.h")
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "056ad74653704bc353d8ec8ab52ac75267b7d373"))
    (vterm-toggle :source "elpaca-menu-lock-file" :recipe
        (:package "vterm-toggle" :fetcher github :repo
            "jixiuf/vterm-toggle" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "06cb4f3c565e46470a3c4505c11e26066d869715"))
    (vundo :source "elpaca-menu-lock-file" :recipe
        (:package "vundo" :repo
            ("https://github.com/casouri/vundo" . "vundo") :files
            ("*" (:exclude ".git" "test")) :source "GNU ELPA"
            :protocol https :inherit t :depth treeless :ref
            "d09448aa537a63e35a4bc6b38ceb2c168e891342"))
    (web-mode :source "elpaca-menu-lock-file" :recipe
        (:package "web-mode" :repo "fxbois/web-mode" :fetcher github
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "be2d59c8fa02b1a45ae54ce4079e502e659cefe6"))
    (web-server :source "elpaca-menu-lock-file" :recipe
        (:package "web-server" :fetcher github :repo
            "eschulte/emacs-web-server" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "6357a1c2d1718778503f7ee0909585094117525b"))
    (websocket :source "elpaca-menu-lock-file" :recipe
        (:package "websocket" :repo "ahyatt/emacs-websocket" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "40c208eaab99999d7c1e4bea883648da24c03be3"))
    (wgrep :source "elpaca-menu-lock-file" :recipe
        (:package "wgrep" :fetcher github :repo
            "mhayashi1120/Emacs-wgrep" :files ("wgrep.el") :source
            "MELPA" :protocol https :inherit t :depth treeless :ref
            "49f09ab9b706d2312cab1199e1eeb1bcd3f27f6f"))
    (which-key :source "elpaca-menu-lock-file" :recipe
        (:package "which-key" :repo "justbur/emacs-which-key" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "38d4308d1143b61e4004b6e7a940686784e51500"))
    (with-editor :source "elpaca-menu-lock-file"
        :recipe
        (:package "with-editor" :fetcher github :repo
            "magit/with-editor" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "e39137ed0add2fb2cb7e4db1d9fab10ee1ebd682"))
    (ws-butler :source "elpaca-menu-lock-file" :recipe
        (:package "ws-butler" :fetcher git :url
            "https://git.savannah.gnu.org/git/emacs/nongnu.git"
            :branch "elpa/ws-butler" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9ee5a7657a22e836618813c2e2b64a548d27d2ff"))
    (yaml :source "elpaca-menu-lock-file" :recipe
        (:package "yaml" :repo "zkry/yaml.el" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "f99ef76c80e6fc3fcf650c4fe34e10726594a4c4"))
    (yaml-mode :source "elpaca-menu-lock-file" :recipe
        (:package "yaml-mode" :repo "yoshiki/yaml-mode" :fetcher
            github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "d91f878729312a6beed77e6637c60497c5786efa"))
    (yari :source "elpaca-menu-lock-file" :recipe
        (:package "yari" :repo "hron/yari.el" :fetcher github :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "de61285ceb21f56c29f4be12e2e65b2aa2bccf56"))
    (yasnippet :source "elpaca-menu-lock-file" :recipe
        (:package "yasnippet" :repo "joaotavora/yasnippet" :fetcher
            github :files ("yasnippet.el" "snippets") :source "MELPA"
            :protocol https :inherit t :depth treeless :ref
            "2384fe1655c60e803521ba59a34c0a7e48a25d06"))
    (yasnippet-capf :source "elpaca-menu-lock-file" :recipe
        (:package "yasnippet-capf" :fetcher github :repo
            "elken/yasnippet-capf" :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :host github :ref
            "f53c42a996b86fc95b96bdc2deeb58581f48c666"))
    (yasnippet-snippets :source "elpaca-menu-lock-file" :recipe
        (:package "yasnippet-snippets" :repo
            "AndreaCrotti/yasnippet-snippets" :fetcher github :files
            ("*.el" "snippets" ".nosearch") :source "MELPA" :protocol
            https :inherit t :depth treeless :ref
            "48e968d555afe8bf64829da364d5c8915980cc32"))
    (ztree :source "elpaca-menu-lock-file" :recipe
        (:package "ztree" :fetcher codeberg :repo "fourier/ztree"
            :files
            ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                    "*-test.el" "*-tests.el" "LICENSE" "README*"
                    "*-pkg.el"))
            :source "MELPA" :protocol https :inherit t :depth treeless
            :ref "9905f1be006fe02417fc6598be4990746053bbec")))
