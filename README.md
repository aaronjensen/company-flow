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
  '(add-to-list 'company-backends 'company-flow))
```

## Configuration

### `company-flow-executable`

Buffer local variable that should point to the flow executable. Defaults to
`"flow"`. Set to `nil` to disable `company-flow`.

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
