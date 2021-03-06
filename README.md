## C-Compiler

### Introduction
This is a simple C compiler using ANTLR tools and JAVA language. <br>
During execution, the content of `.c` files would be parsed and converted to LLVM code. <br>
`sample1.ll`, `sample2.ll` and `sample3.ll` (generated by LLVM tools) are provided for checking the results. <br>
`C_supset_description.pdf` provides the syntax supported by this Compiler.

### Environment required
1. ANTLR v3
2. JAVA SE 13

### Files required
1. `antlr-3.5.2-complete.jar`
2. `myCompiler.g`
3. `myCompiler_test.java`
4. `sample1.c`, `sample2.c`, `sample3.c`
5. `makefile`

### Directions
* `$make`: Compile program <br>
* `$make exe1`: Execute program and generate LLVM code of `sample1.c` <br>
* `$make exe2`: Execute program and generate LLVM code of `sample2.c` <br>
* `$make exe3`: Execute program and generate LLVM code of `sample3.c` <br>
* `$make clean`: Clean files <br>
