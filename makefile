SHELL = /bin/bash
JC = javac
JJ = java
JFLAGS = -cp
ANTLR = antlr-3.5.2-complete.jar
CHECKER = myCompiler_test

all: $(CHECKER).class

$(CHECKER).class: $(ANTLR) $(CHECKER).java myCompilerLexer.java myCompilerParser.java
	@ $(JC) $(JFLAGS) ./$(ANTLR):. $(CHECKER).java myCompilerLexer.java myCompilerParser.java
myCompilerLexer.java myCompilerParser.java: $(ANTLR) myCompiler.g
	@ $(JJ) $(JFLAGS) $(ANTLR) org.antlr.Tool myCompiler.g

exe1: $(ANTLR) $(CHECKER).class sample1.c
	@ $(JJ) $(JFLAGS) $(ANTLR):. $(CHECKER) sample1.c
exe2: $(ANTLR) $(CHECKER).class sample2.c
	@ $(JJ) $(JFLAGS) $(ANTLR):. $(CHECKER) sample2.c
exe3: $(ANTLR) $(CHECKER).class sample3.c
	@ $(JJ) $(JFLAGS) $(ANTLR):. $(CHECKER) sample3.c

clean:
	$(RM) *.tokens *.class myCompilerLexer.java myCompilerParser.java


