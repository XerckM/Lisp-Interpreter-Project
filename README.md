# Lisp-Interpreter-Project
Emacs Lisp Interpreter Project

The format of ASTs
------------------------

An AST is presented as a Lisp S-expression.

A tree node is represented by a list that contains the following items:
  - an atom that signifies the node's kind;
  - an atom that contains information about the corresponding position in
    the input file;
  - 0 to three children.

The children are tree nodes, except when the kind is DECL, BOOL_LITERAL,
INT_LITERAL or VARIABLE.

The various kinds of nodes are described below:

  - SEQ
       Corresponds to the semicolon, i.e., the sequencing operator.
       Two children:<br><br>
         &emsp;&emsp;(0) the AST for the left-hand side of the semicolon;<br>
         &emsp;&emsp;(1) the AST for the right-had side of the semicolon.<br>

  - DECL
       Corresponds to a variable declaration.
       Two children:<br><br>
         &emsp;&emsp;(0) the name of the declared identifier (an atom);<br>
         &emsp;&emsp;(1) the name of the type (i.e., the atom `int` or the atom `bool`).<br>

  - ASSIGNMENT
       Corresponds to the assignment statement.
       Two children:<br><br>
         &emsp;&emsp;(0) the AST for the left-hand side of the assignment;<br>
         &emsp;&emsp;(1) the AST for the right-had side of the assignment.<br>

  - IF
       Corresponds to the conditional statement.
       Three children:<br><br>
         &emsp;&emsp;(0) the AST for the boolean condition;<br>
         &emsp;&emsp;(1) the AST for the "then" branch;<br>
         &emsp;&emsp;(2) the AST for the "else" branch, or the empty list if there is no
             "else".<br>

  - WHILE
       Corresponds to the iterative statement.
       Two children:<br><br>
         &emsp;&emsp;(0) the AST for the boolean condition;<br>
         &emsp;&emsp;(1) the AST for the body.<br>

  - PRINT_INT, PRINT_BOOL
       Corresponds to a `print` statement (and encodes the type of the
       expression to be printed).
       One child:<br><br>
         &emsp;&emsp;(0) the AST of the expression to be printed.<br>

  - OP_NOT
       Corresponds to the boolean negation operator.
       One child:<br><br>
         &emsp;&emsp;(0) the AST for the expression to be negated.<br>

  - OP_AND, OP_OR, OP_EQ, OP_NEQ, OP_LT, OP_LTE, OP_GT, OP_GTE, OP_PLUS, OP_MINUS, OP_MULT, OP_DIV
       Correspond to the binary boolean and arithmetic operators.
       Each of these has two children:<br><br>
         &emsp;&emsp;(0) the AST for the expression that is the left operand;<br>
         &emsp;&emsp;(1) the AST for the expression that is the right operand.<br>

  - BOOL_LITERAL
       Corresponds to a boolean literal.
       One "child":<br><br>
         &emsp;&emsp;(0) an atom representing a boolean constant (`False` or `True`).<br>

  - INT_LITERAL
       Corresponds to an integer constant.
       One "child":<br><br>
         &emsp;&emsp;(0) a Lisp integer constant.<br>

  - VARIABLE
       Corresponds to an occurrence of a variable (outside declarations).
       Two "children":<br><br>
         &emsp;&emsp;(0) the identifier itself (i.e., an atom);<br>
         &emsp;&emsp;(1) its offset in the variable store (an integer constant).<br><br>
       The offset uniquely identifies the variable in the current context (the
       identifier does not, since several variables with the same name may exist
       in different scopes). Different variables in disjoint contexts may have
       the same offset.


Example
-------

The file ab.txt contains the following little program:<br><br>
........................................................................<br>
// This program should print the number 20.<br>
begin<br>
  &emsp;int a;<br>
  &emsp;int b;<br>
  &emsp;a := 2;<br>
  &emsp;b := 1;<br>
  &emsp;if not a <  0 then<br>
    &emsp;&emsp;int b;<br>
    &emsp;&emsp;b := 0 - 2;     // b = -2    (the inner b, the outer one is still 1)<br>
    &emsp;&emsp;a := a * b      // a = -4<br>
  &emsp;else<br>
    &emsp;&emsp;int c;<br>
    &emsp;&emsp;c := a - b;<br>
    &emsp;&emsp;a := a * (c - b)<br>
  &emsp;fi;<br>
  &emsp;print a * (a - b)    // -4 * (-4 - 1)  =  -4 * (-5)  =  20<br>
end<br>
........................................................................<br><br>

The AST is the S-expression shown below.  (Notice that the
two variables whose name is `b` have different offsets: 1 and 2. 
Variable `c` has offset 2, i.e., shares the same location as the
variable `b` declared in the "then" branch, because the scopes are
disjoint.)<br><br>
........................................................................<br>
(SEQ ab.txt:5:3:<br>
  &emsp;(SEQ ab.txt:4:3:<br>
    &emsp;&emsp;(DECL ab.txt:3:7:<br>
      &emsp;&emsp;&emsp;a  int<br>
    &emsp;&emsp;)<br>
    &emsp;&emsp;(DECL ab.txt:4:7:<br>
      &emsp;&emsp;&emsp;b  int<br>
    &emsp;&emsp;)<br>
  &emsp;)<br>
  &emsp;(SEQ ab.txt:5:9:<br>
    &emsp;&emsp;(ASSIGNMENT ab.txt:5:5:<br>
      &emsp;&emsp;&emsp;(VARIABLE ab.txt:5:3:<br>
        &emsp;&emsp;&emsp;&emsp;a  0<br>
      &emsp;&emsp;&emsp;)<br>
      &emsp;&emsp;&emsp;(INT_LITERAL ab.txt:5:8:<br>
        &emsp;&emsp;&emsp;&emsp;2<br>
      &emsp;&emsp;&emsp;)<br>
    &emsp;&emsp;)<br>
    &emsp;&emsp;(SEQ ab.txt:6:9:<br>
      &emsp;&emsp;&emsp;(ASSIGNMENT ab.txt:6:5:<br>
        &emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:6:3:<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;b  1<br>
        &emsp;&emsp;&emsp;&emsp;)<br>
        &emsp;&emsp;&emsp;&emsp;(INT_LITERAL ab.txt:6:8:<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;1<br>
        &emsp;&emsp;&emsp;&emsp;)<br>
      &emsp;&emsp;&emsp;)<br>
      &emsp;&emsp;&emsp;(SEQ ab.txt:15:5:<br>
        &emsp;&emsp;&emsp;&emsp;(IF ab.txt:7:3:<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;(OP_NOT ab.txt:7:6:<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_LT ab.txt:7:12:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:7:10:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(INT_LITERAL ab.txt:7:15:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;0<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;)<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;(SEQ ab.txt:9:5:<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(DECL ab.txt:8:9:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;b  int<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(SEQ ab.txt:9:15:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(ASSIGNMENT ab.txt:9:7:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:9:5:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;b  2<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_MINUS ab.txt:9:12:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(INT_LITERAL ab.txt:9:10:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;0<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(INT_LITERAL ab.txt:9:14:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;2<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(ASSIGNMENT ab.txt:10:7:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:10:5:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_MULT ab.txt:10:12:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:10:10:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:10:14:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;b  2<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;)<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;(SEQ ab.txt:13:5:<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(DECL ab.txt:12:9:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;c  int<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(SEQ ab.txt:13:15:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(ASSIGNMENT ab.txt:13:7:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:13:5:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;c  2<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_MINUS ab.txt:13:12:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:13:10:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:13:14:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;b  1<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(ASSIGNMENT ab.txt:14:7:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:14:5:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_MULT ab.txt:14:12:<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:14:10:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_MINUS ab.txt:14:17:<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:14:15:<br>
                      &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;c  2<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:14:19:<br>
                      &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;b  1<br>
                    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                  &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;)<br>
        &emsp;&emsp;&emsp;&emsp;)<br>
        &emsp;&emsp;&emsp;&emsp;(PRINT_INT ab.txt:16:3:<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;(OP_MULT ab.txt:16:11:<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:16:9:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(OP_MINUS ab.txt:16:16:<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:16:14:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;a  0<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(VARIABLE ab.txt:16:18:<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;b  1<br>
              &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;)<br>
          &emsp;&emsp;&emsp;&emsp;&emsp;)<br>
        &emsp;&emsp;&emsp;&emsp;)<br>
      &emsp;&emsp;&emsp;)<br>
    &emsp;&emsp;)<br>
  &emsp;)<br>
)<br>
........................................................................
