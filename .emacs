;;; OS/161 Emacs GDB Configuration

;; Set default GDB command to the OS/161 MIPS cross-debugger with Machine Interface
(setq gud-gdb-command-name "os161-gdb -i=mi")

;; Shortcut command to start os161-gdb directly on kernel without prompting
(defun os161-gdb ()
  "Launch os161-gdb on the kernel directly."
  (interactive)
  (gdb "os161-gdb -i=mi kernel"))

;; Bind F5 to launch os161-gdb
(global-set-key (kbd "<f5>") 'os161-gdb)

