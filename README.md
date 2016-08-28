# Company flow

[Flow][] backend for [company-mode][].

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
(setq company-backends-js2-mode '((company-flow :with company-dabbrev)
                                    company-files
                                    company-dabbrev))
```

## Thanks

* [@proofit404][] for a nice example backend with [company-tern][].
* [@dgutov][] for [company-mode][].
* [@lunaryorn][] for the process communication code from [flycheck][].

[Flow]: https://flowtype.org/
[company-mode]: https://company-mode.github.com
[@proofit404]: https://github.com/proofit404
[@dgutov]: https://github.com/dgutov
[@lunaryorn]: https://github.com/lunaryorn
[company-tern]: https://github.com/proofit404/company-tern
[flycheck]: https://github.com/flycheck/flycheck
[Melpa]: http://melpa.milkbox.net/
