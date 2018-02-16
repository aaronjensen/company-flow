# Company flow [![MELPA](https://melpa.org/packages/company-flow-badge.svg)](https://melpa.org/#/company-flow)

[Flow][] backend for [company-mode][]. Flow-based autocomplete for Emacs.

## Installation

You can install this package from [Melpa][]

```
M-x package-install RET company-flow RET
```

## Usage

Ensure that `flow` is in your path.

Add to your company-backends for your preferred javascript modes,
for example:

```elisp
(eval-after-load 'company
  (add-to-list 'company-backends 'company-flow))
```

## Configuration

### `company-flow-executable`

Buffer local variable that should point to the flow executable. Defaults to
`"flow"`. Set to `nil` to disable `company-flow`.

For best performance, you can set this to the actual flow binary in your
project. Here's one way to do that:

```elisp
(defun flow/set-flow-executable ()
  (interactive)
  (let* ((os (pcase system-type
               ('darwin "osx")
               ('gnu/linux "linux64")
               (_ nil)))
         (root (locate-dominating-file  buffer-file-name  "node_modules/flow-bin"))
         (executable (car (file-expand-wildcards
                           (concat root "node_modules/flow-bin/*" os "*/flow")))))
    (setq-local company-flow-executable executable)
    ;; These are not necessary for this package, but a good idea if you use
    ;; these other packages
    (setq-local flow-minor-default-binary executable)
    (setq-local flycheck-javascript-flow-executable executable)))

;; Set this to the mode you use, I use rjsx-mode
(add-hook 'rjsx-mode-hook #'flow/set-flow-executable t)
```

### `company-flow-modes`

List of major modes where `company-flow` should provide completions if it is
part of `company-backends`. Set to `nil` to enable `company-flow` for all major modes.

## Thanks

* [@proofit404][] for a nice example backend with [company-tern][].
* [@dgutov][] for [company-mode][] and lots of feedback.
* [@lunaryorn][] for the process communication code from [flycheck][].

[Flow]: https://flowtype.org/
[company-mode]: https://company-mode.github.com
[@proofit404]: https://github.com/proofit404
[@dgutov]: https://github.com/dgutov
[@lunaryorn]: https://github.com/lunaryorn
[company-tern]: https://github.com/proofit404/company-tern
[flycheck]: https://github.com/flycheck/flycheck
[Melpa]: http://melpa.milkbox.net/
