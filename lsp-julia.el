;;; lsp-julia.el --- Julia support for lsp-mode -*- lexical-binding: t; -*-

;; Origin Author: Adam Beckmeyer

;; (require 'cl-generic)
(require 'lsp-mode)
;; (require 'project)

(defconst lsp-julia-base (file-name-directory load-true-file-name))

(defgroup lsp-julia nil
  "Interaction with LanguageServer.jl LSP server via lsp-mode"
  :prefix "lsp-julia-"
  :group 'applications)

(defcustom lsp-julia-command "julia"
  "Command to run the Julia executable."
  :type 'string)

(defcustom lsp-julia-flags nil
  "Extra flags to pass to the Julia executable."
  :type '(repeat string))

(defcustom lsp-julia-depot ""
  "Path or paths (space-separated) to Julia depots.
An empty string uses the default depot for ‘lsp-julia-command’
when the JULIA_DEPOT_PATH environment variable is not set."
  :type 'string)

(defcustom lsp-julia-language-server-project lsp-julia-base
  "Julia project to run language server from.
The project should have LanguageServer and SymbolServer packages
available."
  :type 'string)

;;; Workspace options
(defcustom lsp-julia-format-indent 4
  "Indent size for formatting."
  :type 'integer
  :group 'lsp-julia)

(defcustom lsp-julia-format-indents t
  "Format file indents."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-ops t
  "Format whitespace around operators."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-tuples t
  "Format tuples."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-curly t
  "Format braces."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-calls t
  "Format function calls."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-iterops t
  "Format loop iterators."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-comments t
  "Format comments."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-docs t
  "Format inline documentation."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-kw t
  "Remove spaces around = in function keywords."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-run t
  "Run the linter on active files."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-missingrefs "all"
  "Highlight unknown symbols. The `symbols` option will not mark
unknown fields."
  :type 'string
  :options '("none" "symbols" "all")
  :group 'lsp-julia)

(defcustom lsp-julia-lint-call t
  "This compares call signatures against all known methods for
the called function. Calls with too many or too few arguments, or
unknown keyword parameters are highlighted."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-iter t
  "Check iterator syntax of loops. Will identify, for example,
attempts to iterate over single values."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-constif t
  "Check for constant conditionals in if statements that result
in branches never being reached.."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-lazy t
  "Check for deterministic lazy boolean operators."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-datadecl t
  "Check variables used in type declarations are datatypes."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-typeparam t
  "Check parameters declared in `where` statements or datatype
declarations are used."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-modname t
  "Check submodule names do not shadow their parent's name."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-pirates t
  "Check for type piracy - the overloading of external functions
with methods specified for external datatypes. 'External' here
refers to imported code."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-useoffuncargs t
  "Check that all declared arguments are used within the function
body."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-nothingcomp t
  "Check for use of `==` rather than `===` when comparing against
`nothing`."
  :type 'boolean
  :group 'lsp-julia)

(lsp-register-custom-settings
 '(("julia.format.indent"      lsp-julia-format-indent)
   ("julia.format.indents"     lsp-julia-format-indents     t)
   ("julia.format.ops"         lsp-julia-format-ops         t)
   ("julia.format.tuples"      lsp-julia-format-tuples      t)
   ("julia.format.curly"       lsp-julia-format-curly       t)
   ("julia.format.calls"       lsp-julia-format-calls       t)
   ("julia.format.iterOps"     lsp-julia-format-iterops     t)
   ("julia.format.comments"    lsp-julia-format-comments    t)
   ("julia.format.docs"        lsp-julia-format-docs        t)
   ("julia.format.kw"          lsp-julia-format-kw          t)
   ("julia.lint.run"           lsp-julia-lint-run           t)
   ("julia.lint.missingrefs"   lsp-julia-lint-missingrefs)
   ("julia.lint.call"          lsp-julia-lint-call          t)
   ("julia.lint.iter"          lsp-julia-lint-iter          t)
   ("julia.lint.constif"       lsp-julia-lint-constif       t)
   ("julia.lint.lazyif"        lsp-julia-lint-lazy          t)
   ("julia.lint.datadecl"      lsp-julia-lint-datadecl      t)
   ("julia.lint.typeparam"     lsp-julia-lint-typeparam     t)
   ("julia.lint.modname"       lsp-julia-lint-modname       t)
   ("julia.lint.pirates"       lsp-julia-lint-pirates       t)
   ("julia.lint.useoffuncargs" lsp-julia-lint-useoffuncargs t)
   ("julia.lint.nothingcomp"   lsp-julia-lint-nothingcomp   t)))


;; Make project.el aware of Julia projects
;; (defun lsp-julia--project-try (dir)
;;   "Return project instance if DIR is part of a julia project.
;; Otherwise returns nil"
;;   (let ((root (or (locate-dominating-file dir "JuliaProject.toml")
;;                   (locate-dominating-file dir "Project.toml"))))
;;     (and root (cons 'julia root))))

;; (cl-defmethod project-roots ((project (head julia)))
;;   (list (cdr project)))

(defun lsp-julia--ls-invocation ()
  "Return list of strings to be called to start the Julia language server."
  `(,lsp-julia-command
    "--startup-file=no"
    ,(concat "--project=" lsp-julia-language-server-project)
    ,@lsp-julia-flags
    ,(expand-file-name "lsp-julia.jl" lsp-julia-base)
    ,(file-name-directory (buffer-file-name))
    ,lsp-julia-depot))

(lsp-register-client
 (make-lsp--client :new-connection (lsp-stdio-connection 'lsp-julia--ls-invocation)
                   :major-modes '(julia-mode ess-julia-mode)
                   :multi-root t
                   :server-id 'julia-ls))


(provide 'lsp-julia)
