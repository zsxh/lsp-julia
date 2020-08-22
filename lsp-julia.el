;;; lsp-julia.el --- Julia support for lsp-mode -*- lexical-binding: t; -*-

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
                   :server-id 'julia-ls))


(provide 'lsp-julia)
