;;; The store is simulated by an association list.  The key is the offset that
;;; has been allocated to an identifier in the AST.

(defun store (offset value alist)
  "Insert the value for this offset, replacing the previous value (if any)."
  (cond
   ((null alist)             (list (cons offset value)))    ; ((offset . value))
   ((eq offset (caar alist)) (cons (cons offset value) (cdr alist)))
   (t                        (cons (car alist)
                                   (store offset value (cdr alist))))
   )
  )

(defun lookup (offset alist)
  "Return the value associated with this offset, or raise an error."
  (cond
   ((null alist)             (user-error "UNINITIALISED %s" offset) (exit))
   ((eq (caar alist) offset) (cdar alist))
   (t                        (lookup offset (cdr alist)))
   )
  )

;;; Accessors for the various fields in an AST node

(defun kind (ast)
  "The kind of an AST node"
  (car ast)
  )

(defun position (ast)
  "The position stored in an AST node"
  (cadr ast)
  )

(defun operand (n ast)
  "The n'th operand of an AST node."
  (cond
   ((eq n 0) (caddr ast))
   (t (operand (- n 1) (cdr ast)))
   )
  )

;;; The interpreter itself.

;; exp must handle BOOL_LITERAL, INT_LITERAL, VARIABLE,
;;                 OP_PLUS, OP_MINUS, OP_MULT, OP_DIV,
;;                 OP_EQ, OP_NEQ, OP_LT, OP_LTE, OP_GT, OP_GTE,
;;                 OP_AND, OP_OR, OP_NOT

(defun exp (ast alist)
  "Evaluate an expression (given this alist to represent the variable store)."
  (cond
   ((eq (kind ast) 'BOOL_LITERAL) (operand 0 ast))
   ((eq (kind ast) 'INT_LITERAL)  (operand 0 ast))
   ((eq (kind ast) 'VARIABLE) (lookup (operand 1 ast) alist))
   ((eq (kind ast) 'OP_MULT)
    (* (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)))
   ((eq (kind ast) 'OP_DIV)
    (/ (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)))
   ((eq (kind ast) 'OP_PLUS)
    (+ (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)))
   ((eq (kind ast) 'OP_MINUS)
    (- (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)))
   ((eq (kind ast) 'OP_EQ)
    (if (eq (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)) 'True 'False))
   ((eq (kind ast) 'OP_NEQ)
    (if (eq (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)) 'False 'True))
   ((eq (kind ast) 'OP_LT)
    (if (< (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)) 'True 'False))
   ((eq (kind ast) 'OP_LTE)
    (if (<= (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)) 'True 'False))
   ((eq (kind ast) 'OP_GT)
    (if (> (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)) 'True 'False))
   ((eq (kind ast) 'OP_GTE)
    (if (>= (exp (operand 0 ast) alist) (exp (operand 1 ast) alist)) 'True 'False))
   ((eq (kind ast) 'OP_AND)
    (cond
     ((eq 'False (exp (operand 0 ast) alist)) 'False)
     ((eq 'False (exp (operand 1 ast) alist)) 'False)
     (t 'True)
     ))
   ((eq (kind ast) 'OP_OR)
    (cond
     ((eq 'True (exp (operand 0 ast) alist)) 'True)
     ((eq 'True (exp (operand 1 ast) alist)) 'True)
     (t 'False)
     ))
   ((eq (kind ast) 'OP_NOT)
    (if (eq 'True (exp (operand 0 ast) alist)) 'False 'True)
    )
   )
  )

(defun stmts (ast alist)
  "Interpret a statement or a sequence of statenents, return the store."
  ;; SEQ evaluates the right operand with the store returned by the left one.
  ;; DECL is simply skipped.
  ;; ASSIGNMENT evaluates the right operand and stores the result under the
  ;;            name of the second operand.
  ;; IF and WHILE are handled separately.
  ;; PRINT just evaluates and outputs its operand.
  (cond
   ((eq (kind ast) 'SEQ)          (stmts (operand 1 ast)
                                         (stmts (operand 0 ast) alist)
                                         ))
   ((eq (kind ast) 'DECL)         alist)
   ((eq (kind ast) 'ASSIGNMENT)   (store (operand 1 (operand 0 ast))
                                         (exp (operand 1 ast) alist)
                                         alist
                                         ))
   ((eq (kind ast) 'IF)           (if_stmt    ast alist))
   ((eq (kind ast) 'WHILE)        (while_stmt ast alist))
   ((eq (kind ast) 'PRINT_BOOL)   (progn
                                    (print (exp (operand 0 ast) alist))
                                    alist
                                    ))
   ((eq (kind ast) 'PRINT_INT)    (progn
                                    (print (exp (operand 0 ast) alist))
                                    alist
                                    ))
   )
  )

(defun if_stmt (ast alist)
  "Evaluate the AST for an IF node, returning the updated store."
  (if (eq 'True (exp (operand 0 ast) alist))      ; is condition true?
      (stmts (operand 1 ast) alist)               ; the "then" branch
    (stmts (operand 2 ast) alist)                 ; the "else" branch
    )
  )

(defun while_stmt (ast alist)
  "Evaluate the AST for a WHILE node, returning the updated store."
  (if (eq 'True (exp (operand 0 ast) alist))      ; is condition true?
      ;; yes: evaluate this ast again, in the store updated by the body
      (while_stmt ast (stmts (operand 1 ast) alist))
    ;; no: just return the store
    alist
    )
  )

(defun interpret (ast)
  "Interpret this AST."
  (stmts ast ())
  )


;; (interpret '(PRINT_INT pos (INT_LITERAL pos 17)))
;; (stmts '(PRINT_BOOL pos (BOOL_LITERAL pos True)) ())

(defun load_data (buffer-name)
  "Load the data from this buffer into variable `data`."
  (setq data (read (get-buffer buffer-name)))
  )

(defun run ()
  "Run the interpreter on data in `data`."
  (interpret data)
  )

;; Evaluate the following two expressions, after changing the buffer name to
;; the one you want.
;; NOTE: The buffer with data must be loaded first, and the cursor must be at
;;       the beginning.
;;
;; (load_data "euclid.ast")
;; (run)
