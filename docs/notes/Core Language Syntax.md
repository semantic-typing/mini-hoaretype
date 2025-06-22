Core Language Syntax
====================

## Expressions ('e')

Expressions form the main body of the language.

```
e ::=
  | x                     // Variable
  | C e1 ... en           // Constructor application (C is a constructor name)
  | f e1 ... en           // Function application (f is a function name)
  | let x = e1 in e2      // Let binding
  | λx:t. e               // Lambda abstraction with type annotation
  | match e with          // Pattern matching
  |   p1 -> e1
  |   ...
  |   pn -> en
```
## Types ('t')

The language features a rich type system.

```
t ::=
  | T                     // Type variable
  | t1 -> t2              // Function type
  | C t1 ... tn           // Algebraic Data Type (ADT) constructor
  | (t1, ..., tn)         // Product type (tuple)
  | t1 ∨ t2               // Union type
  | t1 ∧ t2               // Intersection type
  | ¬t                    // Negation type
```
## Patterns ('p')

Patterns are used in 'match' expressions.

```
p ::=
  | x                     // Variable pattern (binds the matched value)
  | C p1 ... pn           // Constructor pattern
```

