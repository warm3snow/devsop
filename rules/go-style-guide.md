---
# Do not modify the header of this file; the AI coding agent relies on it to apply this style guide as an always-on rule
type: always
---
You are a professional Go development assistant. All code must strictly follow the coding conventions below.

**Note: unless explicitly stated otherwise, follow the Google Golang code style guide.**

## Conventions Overview

The requirement level of each convention is defined as:
- **Mandatory**: code must follow this; violating it is considered an error
- **Preferable**: code should follow this, but exceptions are allowed in special cases and are not considered errors
- **Optional**: can be referenced; decide whether to adopt it based on the specific situation


## Code Style Conventions

### 【Mandatory】Formatting
- All Go code must be formatted with `gofmt`
- Use `goimports` to automatically format and manage import statements
- Follow `gofmt`'s parenthesis and spacing logic

### 【Preferable】Line wrapping
- A single line of code should not exceed 120 columns
- Exceptions: function signatures, long string literals, import statements, tool-generated code, struct tags
- For long strings with line breaks, consider using raw string literals
- Documentation links in comments may exceed the column limit

### 【Mandatory】Parentheses and spacing
- Follow gofmt's logic
- Leave a space between operators and operands
- When used as input arguments or array indices, no space is needed between the operator and operand; keep them compact

### 【Preferable】Code line count limits
- A file must not exceed 800 lines
- A function must not exceed 80 lines
- Unit test files are limited to 1600 lines; unit test functions are limited to 160 lines

### 【Mandatory】Import conventions
- Use goimports to automatically format imported package names; the import conventions follow goimports rules
- Import packages by full path; relative paths are forbidden
- Standard packages go in the first group at the top
- Sort alphabetically and group them (standard library, internal packages, third-party packages)
- Internal packages are packages that cannot be imported externally (GoPath mode or current-project package names that do not start with a domain)
- Package names with a domain are all third-party packages, regardless of whether they are internal to the current project
- Use an alias when the package name is inconsistent with the git path or conflicts; alias naming follows the package naming conventions
- 【Optional】Use an alias to fix a third-party package name that does not follow the conventions
- 【Optional】Anonymous package imports are recommended to be placed in a new group with a comment explaining why
- Exception: the embed package embedding external data does not need a comment

## Error Handling Conventions

### 【Mandatory】Error handling
- An error returned as a function return value must be handled, or explicitly ignored
- error must be the last return parameter of a function
- Error descriptions do not need to end with punctuation
- Use an independent error flow, avoiding combining it with other variables in conditional logic
- Prefer `errors.New("xxxx")` for simple errors
- Go 1.13+ recommends `fmt.Errorf("module xxx: %w", err)`

### 【Mandatory】Panic handling
- Do not use panic for general error handling; use error and multiple return values
- panic may be used to assert invariants
- In func init() and functions it calls, a failed initialization that affects program runtime may panic
- In functions called during global variable initialization, a failed initialization that affects program runtime may panic (e.g. regexp.MustCompile, template.Must)
- Exported methods generally must not panic; methods that must panic should be named with a MustXXX prefix and documented
- Using log.Fatal for assertions is not recommended

### 【Mandatory】Recover handling
- Must be used in a defer
- recover is generally not needed in business logic
- recover is used to catch panics of a specific type; abusing recover to catch all types of exceptions is forbidden
- recover returns interface{}; do not assume it is an error, and do not name the return value err

## Comment Conventions

### 【Mandatory】General comment rules
- Write variable, function, and package comments in sync with coding; comments can be exported via godoc to generate documentation
- Every exported (capitalized) name in the program should have a doc comment
- Methods on unexported types may lack doc comments, but the necessity of exporting the method should be questioned
- All commented-out code should be deleted before code review, unless a comment explains why it is kept and states the follow-up plan

### 【Mandatory】Package comments
- Every package should have a package comment (except the main package)
- If a package has multiple go files, the comment only needs to appear in one go file (usually the file with the same name as the package)
- Format: "// Package <name> <description>"

### 【Mandatory】Struct comments
- Every exported struct or interface must have a comment
- Format: "// <name> <description>"
- Exported member variables in a struct need a comment if their meaning is unclear

### 【Mandatory】Method comments
- Every exported function or method must have a comment
- Format: "// <name> <description>"
- Exceptions: Write, Read, ServeHTTP, String, Unwrap, Error, Len, Less, Swap

### 【Mandatory】Variable and constant comments
- Every exported constant and variable must have a comment
- The comment briefly introduces the constant or variable and is placed on the line before its definition
- For large blocks of constant or variable definitions, a general comment can precede the block, then each line's trailing comment details that constant's definition
- Format: "// <name> <description>", with one space after the slashes

### 【Mandatory】Type comments
- Every exported type definition and type alias must have a comment
- Format: "// <name> <description>"

## Naming Conventions

### 【Preferable】Package naming
- Keep the package name consistent with its directory
- Prefer meaningful, short package names; try to avoid conflicts with the standard library
- Package names should be lowercase words, no underscores or mixed case; use multi-level directories to divide hierarchy
- Abbreviations may be used cautiously in package names, when they are widely known to programmers (e.g. strconv, syscall, fmt)
- Project names may join multiple words with hyphens
- Simple and clear package names, e.g. time, list, http
- Do not use meaningless package names, e.g. util, common, misc, global (names like xx/util/encryption are acceptable)

### 【Mandatory】File naming
- Use meaningful, short file names
- Use lowercase, separated by underscores

### 【Mandatory】Struct naming
- Use camelCase; the first letter is uppercase or lowercase based on access control
- Struct names should be nouns or noun phrases, such as Customer, WikiPage, Account, AddressParser; they should not be verbs
- Avoid overly broad struct names like Data, Info
- Use multi-line format for struct declaration and initialization

### 【Preferable】Interface naming
- Single-function interfaces use an er suffix (e.g. Reader, Writer)
- Two-function interfaces combine the two function names
- Interfaces with three or more functions follow struct naming

### 【Mandatory】Variable naming
- Variable names must follow camelCase; the first letter is uppercase or lowercase based on access control
- For proper nouns, follow these rules:
    - If the variable is private and the proper noun is the first word, use lowercase, e.g. apiClient
    - In other cases use the original spelling of the noun, e.g. APIClient, repoID, UserID
    - Bad example: UrlArray should be written as urlArray or URLArray
- Private global variables and local variables follow the same rule: start with a lowercase letter
- Code generated by code-generation tools is exempt from this rule (e.g. Id in xxx.pb.go)
- Prefer short variable names, especially for local variables; the farther a variable is from where it is used and declared, the more descriptive its name must be

### 【Mandatory】Constant naming
- Constants must follow camelCase
- For enum-type constants, first create the corresponding type
- Private global constants and local variables follow the same rule: start with a lowercase letter

### 【Mandatory】Function naming
- Function names must follow camelCase; the first letter is uppercase or lowercase based on access control
- Code generated by code-generation tools is exempt from this rule (e.g. underscores in protocol-generated files xxx.pb.go, or files auto-generated by gotests like xxx_test.go)

## Control Structure Conventions

### 【Preferable】if statements
- Accept initialization statements to create local variables
- Comparison order: variable on the left, constant on the right
- Boolean variables are evaluated directly

### 【Preferable】for statements
- Use short declarations to create local variables

### 【Mandatory】range statements
- When only the key is needed, discard the second value
- When only the value is needed, set the first item to underscore

### 【Mandatory】switch statements
- Must have a default

### 【Preferable】return statements
- Return early; as soon as an error occurs, return immediately

### 【Mandatory】goto statements
- goto is forbidden in business code; try not to use it in frameworks or low-level source code either

## Function Conventions

### 【Preferable】Function parameters
- If a function returns two or three parameters of the same type, or if the meaning of the result is unclear from context, use named returns; otherwise named returns are not recommended
- Passed-in and returned variables start with a lowercase letter
- The number of parameters must not exceed 5
- Prefer value passing over pointer passing
- Do not pass pointers for map, slice, chan, or interface parameters

### 【Mandatory】defer conventions
- When resource management exists, use a defer function immediately to release the resource
- Check for errors first, then defer the resource release
- Using defer in a loop is forbidden

### 【Preferable】Method receivers
- Recommend naming the receiver with the lowercase first letter of the class name
- Do not use a single character when the function exceeds 20 lines
- 【Mandatory】Do not use confusing names like me, this, self

### 【Mandatory】Nesting depth
- Nesting depth must not exceed 4 levels

### 【Preferable】Variable declaration
- Declare variables as close as possible to their first use, following the locality principle

### 【Mandatory】Magic numbers
- Magic numbers should be replaced with constants or variables
- Magic number characteristics: unique values with the same meaning that lack explanation or naming, hurting readability; they appear multiple times in the program, so changing the value may require changing more than one place
- Correctly identifying magic numbers: as long as the meaning is obvious at a glance in context and there is basically no chance of change, it is not considered a magic number
- Common non-magic-number examples: the 4 in the discriminant formula of a quadratic equation, the 2 in modulo operations, 0 and 1 in loops, the 1 for error-exit in programs, etc.

## Unit Test Conventions

### 【Mandatory】Test file conventions
- Unit test file names follow the naming convention example_test.go
- Test case function names must start with Test, e.g. TestExample
- If func Foo exists, the unit test function may use an underscore as func Test_Foo
- If func (b *Bar) Foo exists, the unit test function may be func TestBar_Foo; the underscore must not appear anywhere other than the cases described above
- The line limit for unit test files is 2x that of ordinary files, i.e. 1600 lines; the line limit for unit test functions is also 2x, i.e. 160 lines
- Other convention details such as cyclomatic complexity, column limits, and import grouping stay consistent with ordinary files
- Since functions in unit test files are not exported, exported functions may lack comments, but try not to export structs when defining them

## Dependency Management Conventions

### 【Mandatory】Go Modules
- Go 1.11+ must use go modules mode
- 【Preferable】Use the git.woa.com/group/repo format for the module name
- 【Preferable】Do not commit the vendor directory
- 【Preferable】The go.sum file must be committed

## Application Service Conventions

### 【Preferable】Documentation requirements
- Application services are recommended to have a README.md
- Including service description, usage, deployment requirements, environment dependencies, etc.

### 【Mandatory】Testing requirements
- Application services must have interface tests
- Every important exported function should have test cases

## Recommended Tools
- gofmt: most formatting issues can be solved with gofmt; it auto-formats code, keeping all Go code consistent with the official recommended format
- goimports: on top of gofmt, it adds automatic removal and import of packages
- go vet: a static analysis tool that helps analyze various source issues, such as redundant code, early-return logic, whether struct tags conform to standards, etc.
- golint: a tool similar to jslint in JavaScript; its main function is detecting non-conforming spots in code
