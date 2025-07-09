# Core Language Syntax

## Type System Structure

### Basic Types
- `int` - Integer type
- `float` - Float type
- `string` - String type
- `bool` - Boolean type
- `unit` - Unit type (null value)

### Complex Types
- `t1 -> t2` - Function type
- `C(t1, t2, ...)` - Constructor type (ADT)
- `(t1 * t2 * ...)` - Product type (Tuple)
- `t1 | t2` - Union type
- `t1 & t2` - Intersection type
- `not t` - Negation type
- `t` - Type variable (a, b, t, ...)

### Type Annotations
```
x: int                    # Variable annotation
f: (int -> int)           # Function annotation
data: (int * string)      # Tuple annotation
```

## Expression Syntax

### Literals
```
42          # Integer
3.14        # Float
"hello"     # String
true        # Boolean true
false       # Boolean false
null        # Unit value
```

### Variables
```
x, y, z   
```

### Function Application
```
f(x, y)
```

### Let Bindings
```
let x = e1 in e2
let x: int = e1 in e2    # With type annotation
```

### Lambda Abstraction
```
fun x -> e                   # Single parameter
fun x y -> e                 # Multiple parameters
fun x: int -> e              # With parameter type
```

### Binary Operations
```
x + y        # Add
x - y        # Sub
x * y        # Mul
x / y        # Div
x == y       # Eq
x != y       # Ineq
x < y        # Less
x <= y       # Less equal
x > y        # Greater
x >= y       # Greater equal
x && y       # Logical AND
x || y       # Logical OR
```

### Unary Operations
```
-x           # Neg
!x           # Logical NOT
```

### Conditional Expressions
```
if e1 then e2 else e3
```

### Pattern Matching
```
match e with
  | p1 -> e1
  | p2 -> e2
```

### Tuples
```
(x, y, z)
```

### Field Access
```
e.field
```

### Index Access
```
e[i]
```

## Statement Syntax

### Expression Statement
```
e
```

### Let Statement
```
let x = e1 in e2
```

### Return Statement
```
return e
```

### If Statement
```
if e1 then
  s1
else
  s2
```

### While Loop
```
while e1 do
  s1
```

### For Loop
```
for x in e1 do
  s1
```

### Function Definition
```
func f(x1: t1, x2: t2, ..., xn: tn): t =
  s1
```
hoặc
```
function f(x1: t1, x2: t2, ..., xn: tn): t =
  s1
```

### Data Type Definition
```
data T = C1(t1, t2, ...) | C2(t3, t4, ...) | ...
```

### Import Statement
```
import M
from M import x
```

## Block Syntax

A block is a sequence of statements (let, return, if, while, for, etc.), each ending with a semicolon `;`, followed by a final expression (without a semicolon). The value of the block is the value of the final expression. Braces `{ ... }` are optional for grouping, but not required.

**Syntax:**

```
block ::= stmt_list expr
       | expr
       | { stmt_list }
       | { stmt_list expr }
```
- `stmt_list` is one or more statements, each ending with a semicolon `;`.
- `expr` is any expression (no semicolon after the final expression).

**Examples:**

```
let x = 1 in
let y = 2 in
x + y
```

```
while x > 0 do
  x := x - 1;
x
```

```
{
  let x = 1 in
  let y = 2 in
  x + y
}
```

```
{
  while x > 0 do
    x := x - 1;
  x
}
```

**Notes:**
- Do not use `done` to end a block.
- Do not put a semicolon after the final expression in a block.
- Braces `{ ... }` are optional for grouping, not required.

## Error handling

### Parse Errors
- **Lexer Error**: Token không hợp lệ
- **Parser Error**: Cú pháp không đúng
