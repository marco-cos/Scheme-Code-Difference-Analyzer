# Scheme Code Difference Analyzer

## Overview
This project implements a Scheme code difference analyzer to compare two Scheme expressions and produce a summary highlighting similarities and differences. The analyzer accounts for identifier renaming, differences in lambda notations (`lambda` vs `λ`), and other minor changes. Project for UCLA CS 131 class.

## Features
- **Expression Comparison**: The `expr-compare` function compares two Scheme expressions, producing a Scheme expression that shows where they are the same or differ.
- **Bound Variables**: Where bound variables differ between the expressions, a combined identifier (e.g., `X!Y`) is used.
- **Lambda Handling**: Converts between `lambda` and `λ` where necessary while maintaining consistency.
- **Conditional Differences**: If expressions differ, the result uses an `if` expression to represent which part came from which input.

## Functions
### `expr-compare`
Compares two Scheme expressions `x` and `y`. The output is a new Scheme expression that represents the differences between `x` and `y`. The result will behave like `x` when `%` is true and like `y` when `%` is false.

#### Example Usages:
```scheme
(expr-compare 12 12)  ; => 12
(expr-compare 12 20)  ; => (if % 12 20)
(expr-compare #t #f)  ; => %
(expr-compare '(cons a b) '(list a b))  ; => ((if % cons list) a b)
```

### `test-expr-compare`
Tests the `expr-compare` function by evaluating `x` and `y` in the same environment and comparing them to the output of `expr-compare`. It binds `%` to `#t` for the `x` comparison and `%` to `#f` for the `y` comparison.

#### Example Usage:
```scheme
(test-expr-compare 12 12)  ; => #t
(test-expr-compare '(cons a b) '(list a b))  ; => #f
```

### `test-expr-x` and `test-expr-y`
These variables hold sample Scheme expressions designed to test the `expr-compare` function comprehensively.

```scheme
(define test-expr-x '(apply + 3 ((lambda (a b) (list a b)) 1 2)))
(define test-expr-y '(apply + 2 ((lambda (a c) (list a c)) 1 2)))
```

## Installation
1. Ensure you have [Racket](https://racket-lang.org/) installed.
2. Copy the code into a file named `expr-compare.ss`.

## Running the Code
To run the code and see the output of `expr-compare` or `test-expr-compare`, use Racket's REPL or run the script:
```bash
racket expr-compare.ss
```

You can call the functions directly in the REPL, for example:
```scheme
(expr-compare '(cons a b) '(list a b))
(test-expr-compare test-expr-x test-expr-y)
```

## Submitting the Project
Submit the file `expr-compare.ss` containing the definitions of:
- `expr-compare`
- `test-expr-compare`
- `test-expr-x` and `test-expr-y`

## Notes
- The function is limited to a specific subset of Scheme expressions (literals, identifiers, function calls, `quote`, `lambda`, and `if`).
- It assumes well-formed inputs and may produce undefined behavior for invalid Scheme expressions.
