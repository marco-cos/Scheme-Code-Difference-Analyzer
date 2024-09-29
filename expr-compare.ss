#lang racket

(define (islambda? x y)
  (if (and (and (or (eq? (car x) 'lambda) (eq? (car x) 'λ)) (or (eq? (car y) 'lambda) (eq? (car y) 'λ))) (and (> (length x) 2) (> (length y) 2))) #t #f))

(define (isquote? x)
  (and (list? x) (eq? (car x) 'quote)))

(define (contains? x list)
  (not (not (member x list))))

(define (find-and-replace toreplace replacewith tosearch)
 (if (list? tosearch)
      ;If its a list, then recurse as we only want to analyze single element
     (if (or (and (islambda? tosearch tosearch) (contains? toreplace (car (cdr tosearch)))) (isquote? tosearch)) tosearch ;Don't overwite inner lambda's bound vars
      (map (lambda (x) (find-and-replace toreplace replacewith x)) tosearch))
      ;Base cases
      (cond [(eq? tosearch toreplace) replacewith]
            [else tosearch])))

(define (bettercons e1 e2) ;like cons but works with lists and atomic elements but doesn't put the . (also retains paranthesis)
  (cond
    [(and (not (list? e1)) (list? e2)) (append (list e1) e2)]
    [(and (not (list? e2)) (list? e1)) (append e1 (list e2))]
    [(and (not (list? e2)) (not (list? e1))) (list e1 e2)]
    [else (append e1 e2)]))

(define (nthingtonlist x)
(define (nthingtonlisth x num) ;Sees how many singleton paranthesis are on an element, fix paranthesis not being retained for retargs
  (if (or (not (list? x)) (and (list? x) (not (null? (cdr x))))) num (nthingtonlisth (car x) (+ num 1))))
  (nthingtonlisth x 0))

(define (makenthington x n)
  (if (> n 0) (makenthington (list x) (- n 1)) x))


(define (givenifisinident x)
  (define xs (symbol->string x))
  (or (regexp-match? #rx"^if!" xs) (regexp-match? #rx"!if$" xs)))



;need to remember body arg should be from x
(define (lambda-arg-adjuster x y body checkx) ;Takes args list of x and y
  (cond [(and (list? x) (list? y))
      ;Recursive case
      (cond
           [(or (null? (cdr x)) (null? (cdr y))) (lambda-arg-adjuster (car x) (car y) body checkx)]
           [else
            (define ret1 (lambda-arg-adjuster (car x) (car y) body checkx))
            (define ret2 (lambda-arg-adjuster (cdr x) (cdr y) (cdr ret1) checkx))
            (cons (bettercons (car ret1) (car ret2)) (cdr ret2))])]
      ;Base cases
      [else
       (cond
            [(not (eq? x y))
             (define newsymb (string->symbol (string-append (string-append (symbol->string x) "!") (symbol->string y))))
             (if checkx
                 (cons newsymb (find-and-replace x newsymb body))
                 (cons newsymb (find-and-replace y newsymb body)))
                 ]
            [else (cons x body)])]))

(define (expr-compare x y)

(cond
  [(and (list? x) (list? y))
   (cond
     ;List cases
     [(not (= (length x) (length y))) `(if % ,x ,y)]
     [(or (eq? (car x) 'quote) (eq? (car y) 'quote)) `(if % ,x ,y)] ;Handle quote case
     ;Both x and y have a lambda of conflicting name, there are 3 elements (args and body), so its realy lambda expression and should be changed to symbol (come back to this maybe or is not right)
     ;Found valid lambda expression
     [(islambda? x y)
      (define xargs (car (cdr x)))
      (define yargs (car (cdr y)))
      (define xbody (car (cdr (cdr x))))
      (define ybody (car (cdr (cdr y))))
      (define retx (lambda-arg-adjuster xargs yargs xbody #t))
      (define rety (lambda-arg-adjuster xargs yargs ybody #f))
      (define retargs (car retx))
      (define argsnlist (nthingtonlist xargs))
      (define retxbody (cdr retx))
      (define retybody (cdr rety))
      (define textorsymbol (if (or (and (eq? (car x) 'lambda) (eq? (car y) 'λ)) (and (eq? (car y) 'lambda) (eq? (car x) 'λ))) 'λ (car x)))
      (define newx (list (makenthington retargs argsnlist) retxbody))
      (define newy (list (makenthington retargs argsnlist) retybody))
      ;Want to build list that is like x except args and body are substitued
      
      (cons textorsymbol (expr-compare newx newy))]

     ;For let, want to put if outside args?

     [(and (and (eq? (car x) 'if) (not (eq? (car y) 'if))) (not (givenifisinident (car y)))) `(if % ,x ,y)] ;If its an if statement and other isn't an if, then put whole thing in if as it is fudnamentally different
     [(and (and (eq? (car y) 'if) (not (eq? (car x) 'if))) (not (givenifisinident (car x)))) `(if % ,x ,y)] ;If its an if statement and other isn't an if, then put whole thing in if as it is fudnamentally different
  
     [(or (null? (cdr x)) (null? (cdr y))) (list (expr-compare (car x) (car y)))] ; If current element is end of list, don't want to recurse further so just do this one
     [else (cons (expr-compare (car x) (car y)) (expr-compare (cdr x) (cdr y)))])] ;Get value for first element and concat to modified rest of list

  ;Regular base cases
  [(equal? x y)  x]
  ;[(or (and (eq? x 'lambda)  (eq? y 'λ)) (and (eq? y 'lambda)  (eq? x 'λ))) 'λ]
  [(and x (not y)) '%]
  [(and y (not x)) '(not %)]
  [else `(if % ,x ,y)]
))



(define (test-expr-compare x y)
  (define returned (expr-compare x y))
  (define afterexprcomparex 
    (eval `(let ([% #t]) ,returned)))

  (define afterexprcomparey 
    (eval `(let ([% #f]), returned)))

  (if (and (equal? afterexprcomparex (eval x)) (equal? afterexprcomparey (eval y))) #t #f))


;Ensures that find-and-replace for identifier logic correctly avoids replacing quoted expressions, and that it doesn't do variable replacement for something outside of scope, and that if stataements are correctly constructed, properly doesn't run on quoted expressions, and also checks logic for uneven lists is correct
(define test-expr-x '(cons (if ((lambda (x) ((lambda (x) 'x) 1)) 1) 'sup '(if #t 'test 'test2)) (list 1 2 3)))
(define test-expr-y '(cons (if ((lambda (y) ((lambda (y) 'y) 2)) 2) 'hi '(if #t 'test 'test2)) (list 7 8 9 10)))