grammar myCompiler;

options {
   language = Java;
}

@header {
    import java.util.HashMap;
    import java.util.ArrayList;
    import java.lang.*;
}

@members {
    boolean TRACEON = false;
    public enum Type {
        Error, Int, Float, Boolean, Const_Int, Const_Float;
    }

    // Temp
    class tVar {
        int varIndex;   // For temporary variable
        int iValue;     // Int
        float fValue;   // Float
        boolean bValue; // Boolean
    };
    class Info {
        Type theType;   // type information
        tVar theVar;    // value

        Info() {    // Constructor
            theType = Type.Error;
            theVar = new tVar();
        }
    };
    HashMap<String,Info> symtab = new HashMap<String, Info>();

    // Label, Variable(Temp), Literal Count
    int labelCnt = 0;
    int varCnt = 0;
    int litCnt = 0;

    // Instructions
    ArrayList<String> TextCode = new ArrayList<String>();

    /* Function */
    void prologue() {   // 程式開始
        TextCode.add("\n; === prologue ===");
        TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
        TextCode.add("define dso_local i32 @main()");
        TextCode.add("{");
    }

    void epilogue() {   // 程式結束
        TextCode.add("\n; === epilogue ===");
        TextCode.add("ret i32 0");
        TextCode.add("}");
    }

    String newLabel() { // 建立新Label、取得Label名
        labelCnt++;
        return (new String("L")) + Integer.toString(labelCnt);
    }

    String newLit() {   // 建立新str
        return (new String("@str")) + Integer.toString(litCnt++);
    }

    public ArrayList<String> getTextCode() {
        return TextCode;
    }
}

program: VOID MAIN '(' ')' 
        {   // Start program
            prologue();
        }
        '{' declarations statements '}'
        {
            if (TRACEON) System.out.println("VOID MAIN () {declarations statements}");
            
            // End program
            TextCode.add(0, "\n");
            epilogue();
        }
        ;

declarations: type Identifier ';' declarations
             {
                if (TRACEON) System.out.println("declarations: type Identifier ; declarations"); 

                if( symtab.containsKey($Identifier.text) ) {    // Redeclare
                    System.out.println("Type Error: " + $Identifier.getLine() + ": Redeclared identifier. ");
                    System.exit(0);
                }
                
                Info entry = new Info();
                entry.theType = $type.attr_type;
                symtab.put($Identifier.text, entry);

                if($type.attr_type == Type.Int)
                    TextCode.add("\%t" + varCnt + " = alloca i32, align 4");
                else
                    TextCode.add("\%t" + varCnt + " = alloca float, align 4");

                entry.theVar.varIndex = varCnt++;
             }
           | { if (TRACEON) System.out.println("declarations: ");}
           ;

type returns [Type attr_type]
    : INT { if (TRACEON) System.out.println("type: INT"); $attr_type = Type.Int; }
    | FLOAT {if (TRACEON) System.out.println("type: FLOAT"); $attr_type = Type.Float; }
    ;

statements: statement statements 
            { if (TRACEON) System.out.println("statements: statement statements"); }
          | { if (TRACEON) System.out.println("statements: "); }
          ;

expression returns [Info theInfo] @init { $theInfo = new Info();}
          : assignmentExpr 
            { 
                if (TRACEON) System.out.println("expression: assignmentExpr"); 
                $theInfo = $assignmentExpr.theInfo;
            }
          | cmp_expression
            { 
                if (TRACEON) System.out.println("expression: cmp_exprission"); 
                $theInfo = $cmp_expression.theInfo;
            }
          | { if (TRACEON) System.out.println("expression: "); }
          ; 

assignmentExpr returns [Info theInfo] @init { $theInfo = new Info();}
               : Identifier '=' arith_expression 
                {
                    if (TRACEON) System.out.println("assignmentExpr: Identifier = arith_expression"); 
                
                    if ( symtab.containsKey($Identifier.text) ) {
                        Info idEntry = symtab.get($Identifier.text);
                        Info arEntry = $arith_expression.theInfo;
                        $theInfo = idEntry;

                        if (idEntry.theType==Type.Int && arEntry.theType==Type.Int) {
                            idEntry.theVar.iValue = arEntry.theVar.iValue;
                            TextCode.add("store i32 \%t" + arEntry.theVar.varIndex + ", i32* \%t" + idEntry.theVar.varIndex);
                        }
                        else if (idEntry.theType==Type.Float && arEntry.theType==Type.Float){
                            idEntry.theVar.fValue = arEntry.theVar.fValue;
                            TextCode.add("store float \%t" + arEntry.theVar.varIndex + ", float* \%t" + idEntry.theVar.varIndex);
                        }
                        else if (idEntry.theType==Type.Int && arEntry.theType==Type.Const_Int) {
                            idEntry.theVar.iValue = arEntry.theVar.iValue;
                            TextCode.add("store i32 " + arEntry.theVar.iValue + ", i32* \%t" + idEntry.theVar.varIndex);
                        }
                        else if (idEntry.theType==Type.Float && arEntry.theType==Type.Const_Float) {
                            idEntry.theVar.fValue = arEntry.theVar.fValue;
                            TextCode.add("store float " + arEntry.theVar.fValue + ", float* \%t" + idEntry.theVar.varIndex);
                        }
                        else {  // Type mismatch
                            System.out.println("Error: " + $arith_expression.start.getLine() + ": Type mismatch for the two side operands in an assignment statement.");
                            $theInfo.theType = Type.Error;
                            System.exit(0);
                        }
                    }
                    else {      // Undeclared
                        $theInfo.theType = Type.Error;
                        System.out.println("Error: " + $Identifier.getLine() + ": Undeclared identifier.");
                        System.exit(0);
                    }
                } 
              ;

cmp_expression returns [Info theInfo] @init { $theInfo = new Info();}
              : a = arith_expression 
                { 
                    if (TRACEON) System.out.println("cmp_expression: arith_expression"); 
                    
                    Info aEntry = $a.theInfo;
                    $theInfo.theType = aEntry.theType;
                    $theInfo.theVar.varIndex = aEntry.theVar.varIndex;
                    if (aEntry.theType==Type.Int || aEntry.theType==Type.Const_Int)
                        $theInfo.theVar.iValue = aEntry.theVar.iValue;
                    else if (aEntry.theType==Type.Float || aEntry.theType==Type.Const_Float)
                        $theInfo.theVar.fValue = aEntry.theVar.fValue;
                }
              ( compare_op b = arith_expression 
                {
                    if (TRACEON) System.out.println("compare_op arith_expression");

                    Info aEntry = $a.theInfo;
                    Info bEntry = $b.theInfo;
                    String aval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)aEntry.theVar.fValue ) );
                    String bval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)bEntry.theVar.fValue ) );
                    String sop = "";        // operator for instruction
                    boolean btmp = true;    // value for temp

                    boolean chkII = (aEntry.theType==Type.Int && bEntry.theType==Type.Int);
                    boolean chkIC = (aEntry.theType==Type.Int && bEntry.theType==Type.Const_Int);
                    boolean chkCI = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Int);
                    boolean chkICC = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Const_Int);
                    boolean chkFF = (aEntry.theType==Type.Float && bEntry.theType==Type.Float);
                    boolean chkFC = (aEntry.theType==Type.Float && bEntry.theType==Type.Const_Float);
                    boolean chkCF = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Float);
                    boolean chkFCC = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Const_Float);

                    if (!chkII && !chkFF && !chkIC && !chkCI && !chkFC && !chkCF && !chkICC && !chkFCC) { // Type mismatch
                        System.out.println("Error: " + $a.start.getLine() + ": Type mismatch for the two side operands in an comparison statement.");
                        $theInfo.theType = Type.Error;
                        System.exit(0);
                    }

                    if (chkII || chkIC || chkCI || chkICC) {
                        switch ($compare_op.text) {
                            case "==":
                                sop = "eq";
                                btmp = (aEntry.theVar.iValue == bEntry.theVar.iValue);
                                break;
                            case "!=":
                                sop = "ne";
                                btmp = (aEntry.theVar.iValue != bEntry.theVar.iValue);
                                break;
                            case ">":
                                sop = "sgt";
                                btmp = (aEntry.theVar.iValue > bEntry.theVar.iValue);
                                break;
                            case "<":
                                sop = "slt";
                                btmp = (aEntry.theVar.iValue < bEntry.theVar.iValue);
                                break;
                            case ">=":
                                sop = "sge";
                                btmp = (aEntry.theVar.iValue >= bEntry.theVar.iValue);
                                break;
                            case "<=":
                                sop = "sle";
                                btmp = (aEntry.theVar.iValue <= bEntry.theVar.iValue);
                                break;
                        }
                    }
                    else {
                        switch ($compare_op.text) {
                            case "==":
                                sop = "oeq";
                                btmp = (aEntry.theVar.fValue == bEntry.theVar.fValue);
                                break;
                            case "!=":
                                sop = "une";
                                btmp = (aEntry.theVar.fValue != bEntry.theVar.fValue);
                                break;
                            case ">":
                                sop = "ogt";
                                btmp = (aEntry.theVar.fValue > bEntry.theVar.fValue);
                                break;
                            case "<":
                                sop = "olt";
                                btmp = (aEntry.theVar.fValue < bEntry.theVar.fValue);
                                break;
                            case ">=":
                                sop = "oge";
                                btmp = (aEntry.theVar.fValue >= bEntry.theVar.fValue);
                                break;
                            case "<=":
                                sop = "ole";
                                btmp = (aEntry.theVar.fValue <= bEntry.theVar.fValue);
                                break;
                        }
                    }

                    if (chkII)
                        TextCode.add("\%t" + varCnt + " = icmp " + sop + " i32 \%t" + aEntry.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                    else if (chkIC)
                        TextCode.add("\%t" + varCnt + " = icmp " + sop + " i32 \%t" + aEntry.theVar.varIndex + ", " + bEntry.theVar.iValue);
                    else if (chkCI)
                        TextCode.add("\%t" + varCnt + " = icmp " + sop + " i32 " + aEntry.theVar.iValue + ", \%t" + bEntry.theVar.varIndex);
                    else if (chkICC)
                        TextCode.add("\%t" + varCnt + " = icmp " + sop + " i32 " + aEntry.theVar.iValue + ", " + bEntry.theVar.iValue);
                    else if (chkFF)
                        TextCode.add("\%t" + varCnt + " = fcmp " + sop + " float \%t" + aEntry.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                    else if (chkFC) {
                        TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + aEntry.theVar.varIndex + " to double");
                        TextCode.add("\%t" + varCnt + " = fcmp " + sop + " double \%t" + (varCnt-1) + ", " + bval);
                    }
                    else if (chkCF) {
                        TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + bEntry.theVar.varIndex + " to double");
                        TextCode.add("\%t" + varCnt + " = fcmp " + sop + " double " + aval + ", \%t" + (varCnt-1));
                    }
                    else if (chkFCC)
                        TextCode.add("\%t" + varCnt + " = fcmp " + sop + " double " + aval + ", " + bval);

                    $theInfo.theType = Type.Boolean;
                    $theInfo.theVar.varIndex = varCnt++;
                    $theInfo.theVar.bValue = btmp;
                } 
              )?
              ;

arith_expression returns [Info theInfo] @init{ $theInfo = new Info();}
                : a = multExpr 
                    { 
                        if (TRACEON) System.out.println("arith_expression: multExpr"); 
                        
                        Info aEntry = $a.theInfo;
                        $theInfo.theType = aEntry.theType;
                        $theInfo.theVar.varIndex = aEntry.theVar.varIndex;
                        if (aEntry.theType==Type.Int || aEntry.theType==Type.Const_Int)
                            $theInfo.theVar.iValue = aEntry.theVar.iValue;
                        else if (aEntry.theType==Type.Float || aEntry.theType==Type.Const_Float)
                            $theInfo.theVar.fValue = aEntry.theVar.fValue;
                    }
                  ( '+' b = multExpr 
                    {
                        if (TRACEON) System.out.println(" + multExpr");

                        Info aEntry = $theInfo;
                        Info bEntry = $b.theInfo;
                        String aval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)aEntry.theVar.fValue ) );
                        String bval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)bEntry.theVar.fValue ) );

                        boolean chkII = (aEntry.theType==Type.Int && bEntry.theType==Type.Int);
                        boolean chkIC = (aEntry.theType==Type.Int && bEntry.theType==Type.Const_Int);
                        boolean chkCI = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Int);
                        boolean chkICC = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Const_Int);
                        boolean chkFF = (aEntry.theType==Type.Float && bEntry.theType==Type.Float);
                        boolean chkFC = (aEntry.theType==Type.Float && bEntry.theType==Type.Const_Float);
                        boolean chkCF = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Float);
                        boolean chkFCC = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Const_Float);

                        if (!chkII && !chkFF && !chkIC && !chkCI && !chkFC && !chkCF && !chkICC && !chkFCC) { // Type mismatch
                            System.out.println("Error: " + $a.start.getLine() + ": Type mismatch for the two side operands in an comparison statement.");
                            $theInfo.theType = Type.Error;
                            System.exit(0);
                        }

                        if (chkII)
                            TextCode.add("\%t" + varCnt + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                        else if (chkIC)
                            TextCode.add("\%t" + varCnt + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + bEntry.theVar.iValue);
                        else if (chkCI)
                            TextCode.add("\%t" + varCnt + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + bEntry.theVar.varIndex);
                        else if (chkICC)
                            TextCode.add("\%t" + varCnt + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + bEntry.theVar.iValue);
                        else if (chkFF)
                            TextCode.add("\%t" + varCnt + " = fadd float \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                        else if (chkFC) {
                            TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
                            TextCode.add("\%t" + varCnt + " = fadd double \%t" + (varCnt-1) + ", " + bval);
                            TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        }
                        else if (chkCF) {
                            TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + bEntry.theVar.varIndex + " to double");
                            TextCode.add("\%t" + varCnt + " = fadd double " + aval + ", \%t" + (varCnt-1));
                            TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        }
                        else if (chkFCC) {
                            TextCode.add("\%t" + varCnt++ + " = fadd double " + aval + ", " + bval);
                            TextCode.add("\%t" + varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        }

                        if (chkII || chkIC || chkCI || chkICC) {
                            $theInfo.theType = Type.Int;
                            $theInfo.theVar.iValue += bEntry.theVar.iValue;
                        }
                        else {
                            $theInfo.theType = Type.Float;
                            $theInfo.theVar.fValue += bEntry.theVar.fValue;
                        }
                        $theInfo.theVar.varIndex = varCnt++;
                    }
                  | '-' c = multExpr 
                    {
                        if (TRACEON) System.out.println(" - multExpr"); 

                        Info aEntry = $theInfo;
                        Info bEntry = $c.theInfo;
                        String aval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)aEntry.theVar.fValue ) );
                        String bval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)bEntry.theVar.fValue ) );

                        boolean chkII = (aEntry.theType==Type.Int && bEntry.theType==Type.Int);
                        boolean chkIC = (aEntry.theType==Type.Int && bEntry.theType==Type.Const_Int);
                        boolean chkCI = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Int);
                        boolean chkICC = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Const_Int);
                        boolean chkFF = (aEntry.theType==Type.Float && bEntry.theType==Type.Float);
                        boolean chkFC = (aEntry.theType==Type.Float && bEntry.theType==Type.Const_Float);
                        boolean chkCF = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Float);
                        boolean chkFCC = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Const_Float);

                        if (!chkII && !chkFF && !chkIC && !chkCI && !chkFC && !chkCF && !chkICC && !chkFCC) { // Type mismatch
                            System.out.println("Error: " + $a.start.getLine() + ": Type mismatch for the two side operands in an comparison statement.");
                            $theInfo.theType = Type.Error;
                            System.exit(0);
                        }

                        if (chkII)
                            TextCode.add("\%t" + varCnt + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                        else if (chkIC)
                            TextCode.add("\%t" + varCnt + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + bEntry.theVar.iValue);
                        else if (chkCI)
                            TextCode.add("\%t" + varCnt + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + bEntry.theVar.varIndex);
                        else if (chkICC)
                            TextCode.add("\%t" + varCnt + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + bEntry.theVar.iValue);
                        else if (chkFF)
                            TextCode.add("\%t" + varCnt + " = fsub float \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                        else if (chkFC) {
                            TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
                            TextCode.add("\%t" + varCnt + " = fsub double \%t" + (varCnt-1) + ", " + bval);
                            TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        }
                        else if (chkCF) {
                            TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + bEntry.theVar.varIndex + " to double");
                            TextCode.add("\%t" + varCnt + " = fsub double " + aval + ", \%t" + (varCnt-1));
                            TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        }
                        else if (chkFCC) {
                            TextCode.add("\%t" + varCnt++ + " = fsub double " + aval + ", " + bval);
                            TextCode.add("\%t" + varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        }

                        if (chkII || chkIC || chkCI || chkICC) {
                            $theInfo.theType = Type.Int;
                            $theInfo.theVar.iValue -= bEntry.theVar.iValue;
                        }
                        else {
                            $theInfo.theType = Type.Float;
                            $theInfo.theVar.fValue -= bEntry.theVar.fValue;
                        }
                        $theInfo.theVar.varIndex = varCnt++;
                    }
				  )*
                  ;

multExpr returns [Info theInfo] @init{ $theInfo = new Info();}
        : a = signExpr 
            { 
                if (TRACEON) System.out.println("multExpr: signExpr"); 
                
                Info aEntry = $a.theInfo;
                $theInfo.theType = aEntry.theType;
                $theInfo.theVar.varIndex = aEntry.theVar.varIndex;
                if (aEntry.theType==Type.Int || aEntry.theType==Type.Const_Int)
                    $theInfo.theVar.iValue = aEntry.theVar.iValue;
                else if (aEntry.theType==Type.Float || aEntry.theType==Type.Const_Float)
                    $theInfo.theVar.fValue = aEntry.theVar.fValue;
            }
          ( '*' b = signExpr 
            {
                if (TRACEON) System.out.println(" * signExpr"); 
            
                Info aEntry = $theInfo;
                Info bEntry = $b.theInfo;
                String aval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)aEntry.theVar.fValue ) );
                String bval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)bEntry.theVar.fValue ) );

                boolean chkII = (aEntry.theType==Type.Int && bEntry.theType==Type.Int);
                boolean chkIC = (aEntry.theType==Type.Int && bEntry.theType==Type.Const_Int);
                boolean chkCI = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Int);
                boolean chkICC = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Const_Int);
                boolean chkFF = (aEntry.theType==Type.Float && bEntry.theType==Type.Float);
                boolean chkFC = (aEntry.theType==Type.Float && bEntry.theType==Type.Const_Float);
                boolean chkCF = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Float);
                boolean chkFCC = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Const_Float);

                if (!chkII && !chkFF && !chkIC && !chkCI && !chkFC && !chkCF && !chkICC && !chkFCC) { // Type mismatch
                    System.out.println("Error: " + $a.start.getLine() + ": Type mismatch for the two side operands in an comparison statement.");
                    $theInfo.theType = Type.Error;
                    System.exit(0);
                }

                if (chkII)
                    TextCode.add("\%t" + varCnt + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                else if (chkIC)
                    TextCode.add("\%t" + varCnt + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + bEntry.theVar.iValue);
                else if (chkCI)
                    TextCode.add("\%t" + varCnt + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + bEntry.theVar.varIndex);
                else if (chkICC)
                    TextCode.add("\%t" + varCnt + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + bEntry.theVar.iValue);
                else if (chkFF)
                    TextCode.add("\%t" + varCnt + " = fmul float \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                else if (chkFC) {
                    TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
                    TextCode.add("\%t" + varCnt + " = fmul double \%t" + (varCnt-1) + ", " + bval);
                    TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                }
                else if (chkCF) {
                    TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + bEntry.theVar.varIndex + " to double");
                    TextCode.add("\%t" + varCnt + " = fmul double " + aval + ", \%t" + (varCnt-1));
                    TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                }
                else if (chkFCC) {
                    TextCode.add("\%t" + varCnt++ + " = fmul double " + aval + ", " + bval);
                    TextCode.add("\%t" + varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                }

                if (chkII || chkIC || chkCI || chkICC) {
                    $theInfo.theType = Type.Int;
                    $theInfo.theVar.iValue *= bEntry.theVar.iValue;
                }
                else {
                    $theInfo.theType = Type.Float;
                    $theInfo.theVar.fValue *= bEntry.theVar.fValue;
                }
                $theInfo.theVar.varIndex = varCnt++;
            }
          | '/' c = signExpr 
            {
                if (TRACEON) System.out.println(" / signExpr"); 

                Info aEntry = $theInfo;
                Info bEntry = $c.theInfo;
                String aval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)aEntry.theVar.fValue ) );
                String bval = "0x" + Long.toHexString( Double.doubleToLongBits( (double)bEntry.theVar.fValue ) );

                boolean chkII = (aEntry.theType==Type.Int && bEntry.theType==Type.Int);
                boolean chkIC = (aEntry.theType==Type.Int && bEntry.theType==Type.Const_Int);
                boolean chkCI = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Int);
                boolean chkICC = (aEntry.theType==Type.Const_Int && bEntry.theType==Type.Const_Int);
                boolean chkFF = (aEntry.theType==Type.Float && bEntry.theType==Type.Float);
                boolean chkFC = (aEntry.theType==Type.Float && bEntry.theType==Type.Const_Float);
                boolean chkCF = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Float);
                boolean chkFCC = (aEntry.theType==Type.Const_Float && bEntry.theType==Type.Const_Float);

                if (!chkII && !chkFF && !chkIC && !chkCI && !chkFC && !chkCF && !chkICC && !chkFCC) { // Type mismatch
                    System.out.println("Error: " + $a.start.getLine() + ": Type mismatch for the two side operands in an comparison statement.");
                    $theInfo.theType = Type.Error;
                    System.exit(0);
                }

                if (chkII)
                    TextCode.add("\%t" + varCnt + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                else if (chkIC)
                    TextCode.add("\%t" + varCnt + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", " + bEntry.theVar.iValue);
                else if (chkCI)
                    TextCode.add("\%t" + varCnt + " = sdiv i32 " + $theInfo.theVar.iValue + ", \%t" + bEntry.theVar.varIndex);
                else if (chkICC)
                    TextCode.add("\%t" + varCnt + " = sdiv i32 " + $theInfo.theVar.iValue + ", " + bEntry.theVar.iValue);
                else if (chkFF)
                    TextCode.add("\%t" + varCnt + " = fdiv float \%t" + $theInfo.theVar.varIndex + ", \%t" + bEntry.theVar.varIndex);
                else if (chkFC) {
                    TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
                    TextCode.add("\%t" + varCnt + " = fdiv double \%t" + (varCnt-1) + ", " + bval);
                    TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                }
                else if (chkCF) {
                    TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + bEntry.theVar.varIndex + " to double");
                    TextCode.add("\%t" + varCnt + " = fdiv double " + aval + ", \%t" + (varCnt-1));
                    TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                }
                else if (chkFCC) {
                    TextCode.add("\%t" + varCnt++ + " = fdiv double " + aval + ", " + bval);
                    TextCode.add("\%t" + varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                }

                if (chkII || chkIC || chkCI || chkICC) {
                    $theInfo.theType = Type.Int;
                    $theInfo.theVar.iValue /= bEntry.theVar.iValue;
                }
                else {
                    $theInfo.theType = Type.Float;
                    $theInfo.theVar.fValue /= bEntry.theVar.fValue;
                }
                $theInfo.theVar.varIndex = varCnt++;
            }
		  )*
		  ;

signExpr returns [Info theInfo] @init { $theInfo = new Info(); }
        : primaryExpr 
            {
                if (TRACEON) System.out.println("signExpr: primaryExpr"); 
                $theInfo = $primaryExpr.theInfo;
            }
        | '-' primaryExpr 
            {
                if (TRACEON) System.out.println("signExpr: - primaryExpr"); 

                Info entry = $primaryExpr.theInfo;
                switch (entry.theType) {
                    case Const_Int:
                        $theInfo = $primaryExpr.theInfo;
                        $theInfo.theVar.iValue *= -1;
                        break;
                    case Const_Float:
                        $theInfo = $primaryExpr.theInfo;
                        $theInfo.theVar.fValue *= -1;
                        break;
                    case Int:
                        $theInfo.theType = entry.theType;
                        $theInfo.theVar.iValue = -1 * entry.theVar.iValue;
                        TextCode.add("\%t" + varCnt + " = sub nsw i32 0, \%t" + entry.theVar.varIndex);
                        $theInfo.theVar.varIndex = varCnt++;
                        break;
                    case Float:
                        $theInfo.theType = entry.theType;
                        $theInfo.theVar.fValue = -1 * entry.theVar.fValue;
                        TextCode.add("\%t" + varCnt++ + " = fpext float \%t" + entry.theVar.varIndex + " to double");
                        TextCode.add("\%t" + varCnt + " = fsub double 0x0, \%t" + (varCnt-1));
                        TextCode.add("\%t" + ++varCnt + " = fptrunc double \%t" + (varCnt-1) + " to float");
                        $theInfo.theVar.varIndex = varCnt++;
                        break;
                }
            }
		;

primaryExpr returns [Info theInfo] @init{ $theInfo = new Info();}
           : Integer_constant 
            {
                if (TRACEON) System.out.println("primaryExpr: Integer_constant"); 
            
                $theInfo.theType = Type.Const_Int;
                $theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
            }
           | Floating_point_constant 
            {
                if (TRACEON) System.out.println("primaryExpr: Floating_point_constant"); 

                $theInfo.theType = Type.Const_Float;
                $theInfo.theVar.fValue = Float.parseFloat($Floating_point_constant.text);
            }
           | Identifier 
            {
                if (TRACEON) System.out.println("primaryExpr: Identifier"); 

                if ( symtab.containsKey($Identifier.text) ) {
                    Info entry = symtab.get($Identifier.text);
                    
                    if (entry.theType == Type.Int) {
                        $theInfo.theVar.iValue = entry.theVar.iValue;
                        TextCode.add("\%t" + varCnt + " = load i32, i32* \%t" + entry.theVar.varIndex + ", align 4");
                    }
                    else if (entry.theType == Type.Float) {
                        $theInfo.theVar.fValue = entry.theVar.fValue;
                        TextCode.add("\%t" + varCnt + " = load float, float* \%t" + entry.theVar.varIndex + ", align 4");
                    }

                    $theInfo.theType = entry.theType;
                    $theInfo.theVar.varIndex = varCnt++;
                }
                else { // Undeclared Error
                    System.out.println("Error: " + $Identifier.getLine() + ": Undeclared identifier.");
                    $theInfo.theType = Type.Error;
                    System.exit(0);
                }
            }
		   | '(' arith_expression ')' 
            {
                if (TRACEON) System.out.println("primary: ( arith_expression )"); 
                $theInfo = $arith_expression.theInfo;
            }
           ;

statement returns [String LStart,String LTrue,String LFalse,String LNext,String LEnd]
@init { $LStart = new String();
        $LTrue = new String();
        $LFalse = new String();
        $LEnd = new String();
        $LNext = new String(); }
         : assignmentExpr ';' 
            { if (TRACEON) System.out.println("statement: assignmentExpr"); }
         | print ';'
            { if (TRACEON) System.out.println("statement: print ;"); }
         | IF '(' expression ')'  
            {
                if (TRACEON) System.out.println("statement: IF if_then_loop_statements"); 

                if ($expression.theInfo.theType != Type.Boolean) {  // Not Boolean
                    System.out.println("Error: " + $expression.start.getLine() + ": Type error, expected type boolean in condition of if statement.");
                    System.exit(0);
                }
                
                $LTrue = newLabel();
                $LFalse = newLabel();
                $LEnd = newLabel();
                Info cond = $expression.theInfo;

                TextCode.add("br i1 \%t" + cond.theVar.varIndex + ", label \%" + $LTrue + ", label \%" + $LFalse + "\n");
                TextCode.add($LTrue + ": ");
            }
           if_then_loop_statements 
            { 
                TextCode.add("br label \%" + $LEnd + "\n"); 
                TextCode.add($LFalse + ": ");
            }
          ( (ELSE) => ELSE { if (TRACEON) System.out.println("ELSE if_then_loop_statements"); } 
            if_then_loop_statements
          )?
            { 
                TextCode.add("br label \%" + $LEnd + "\n");
                TextCode.add($LEnd + ": "); 
            }
         | WHILE 
            {
                if (TRACEON) System.out.println("statement: WHILE ( expression ) if_then_loop_statements"); 

                $LStart = newLabel();
                TextCode.add("br label \%" + $LStart + "\n");
                TextCode.add($LStart + ": ");
            }
           '(' expression ')' 
            {
                if ($expression.theInfo.theType != Type.Boolean) {  // Not Boolean
                    System.out.println("Error: " + $expression.start.getLine() + ": Type error, expected type boolean in condition of while statement.");
                    System.exit(0);
                }

                Info cond = $expression.theInfo;
                $LTrue = newLabel();
                $LEnd = newLabel();
                TextCode.add("br i1 \%t" + cond.theVar.varIndex + ", label \%" + $LTrue + ", label \%" + $LEnd + "\n");
                TextCode.add($LTrue + ": ");
            }
           if_then_loop_statements 
            { 
                TextCode.add("br label \%" + $LStart + "\n");
                TextCode.add($LEnd + ": ");
            }
         | FOR '(' expression ';' 
            {
                if (TRACEON) System.out.println("statement: FOR ( expression ; expression ; expression ) if_then_loop_statements"); 

                $LStart = newLabel();
                TextCode.add("br label \%" + $LStart + "\n");
                TextCode.add($LStart + ": ");
            }
           a = expression ';'
            {
                if ($a.theInfo.theType != Type.Boolean) {   // Not Boolean
                    System.out.println("Error: " + $a.start.getLine() + ": Type error, expected type boolean in condition of for statement.");
                    System.exit(0);
                }

                Info cond = $a.theInfo;
                $LTrue = newLabel();
                $LNext = newLabel();
                $LEnd = newLabel();
                TextCode.add("br i1 \%t" + cond.theVar.varIndex + ", label \%" + $LTrue + ", label \%" + $LEnd + "\n");
                TextCode.add($LNext + ": ");
            }
           expression ')' 
            { 
                TextCode.add("br label \%" + $LStart + "\n");
                TextCode.add($LTrue + ": ");
            }
           if_then_loop_statements
            {
                TextCode.add("br label \%" + $LNext + "\n");
                TextCode.add($LEnd + ": ");
            }
		 ;

print returns [Info ret] @init{ $ret = new Info(); }
        : PRINTF '(' LITERAL printArg ')' 
        {
            if (TRACEON) System.out.println("print: PRINTF ( LITERAL printArg )");
        
            int len = $LITERAL.text.length() - 1;            // 多出""，少了\00
            String content = $LITERAL.text.substring(0, len) + "\\00\"";
            String strLn = content, line = "\\n";
            int cntLn=0;                                     // 計算換行
            for(cntLn=0;strLn.contains(line);cntLn++)
                strLn = strLn.substring(strLn.indexOf(line) + line.length());
            content = content.replaceAll("\\\\n", "\\\\0A"); // 換掉所有換行
            len -= cntLn;

            $ret.theVar.varIndex = varCnt++;
            $ret.theType = Type.Int;
            String str = newLit();
            String argument = "";
            if ($printArg.arg.length() > 0)
                argument = ", " + $printArg.arg;

            // Instruction
            TextCode.add(0+litCnt-1, str + " = private unnamed_addr constant [" + 
                         len + " x i8] c" + content);
            TextCode.add("\%t" + $ret.theVar.varIndex + 
                         " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" + 
                         len + " x i8], [" + len + " x i8]* " + str +
                         ", i32 0, i32 0)" + argument + ")");
        }
        ;

printArg returns [String arg] @init{ $arg = new String(); }
        : ',' Identifier a=printArg
            {
                if (TRACEON) System.out.println("printArg: , Identifier printArg");

                if ( !symtab.containsKey($Identifier.text) ) { // Undeclared error
                    System.out.println("Error: " + $Identifier.getLine() + ": Undeclared identifier.");
                    System.exit(0);
                }

                String type = new String();
                String argument = "";
                Info entry = symtab.get($Identifier.text);
                int idx = entry.theVar.varIndex;

                if (entry.theType==Type.Int) {
                    type = "i32";
                    TextCode.add("\%t" + varCnt + " = load i32, i32* \%t" + idx + ", align 4");
                    idx = varCnt++;
                }
                else if (entry.theType==Type.Float) {
                    type = "double";
                    TextCode.add("\%t" + varCnt++ + " = load float, float* \%t" + idx + ", align 4");
                    TextCode.add("\%t" + varCnt + " = fpext float \%t" + (varCnt-1) + " to double");
                    idx = varCnt++;
                }
                else {
                    System.out.println("Error: " + $Identifier.getLine() + ": Wrong type in printf function arguments");
                    System.exit(0);
                }

                if ($a.arg.length() > 0)
                    argument = ", " + $a.arg;
                $arg = type + " \%t" + idx + argument;
            }
        |   { if (TRACEON) System.out.println("printArg: "); $arg=""; }
        ;

if_then_loop_statements: statement { if (TRACEON) System.out.println("if_then_loop_statements: statement"); }
                       | '{' statements '}' { if (TRACEON) System.out.println("if_then_loop_statement: { statements }"); }
				       ;

compare_op: EQ_OP { if (TRACEON) System.out.println("compare_op: EQ_OP"); }
          | NEQ_OP { if (TRACEON) System.out.println("compare_op: NEQ_OP"); }
          | LEQ_OP { if (TRACEON) System.out.println("compare_op: LEQ_OP"); }
          | BEQ_OP { if (TRACEON) System.out.println("compare_op: BEQ_OP"); }
          | BGT_OP { if (TRACEON) System.out.println("compare_op: BGT_OP"); }
          | LET_OP { if (TRACEON) System.out.println("compare_op: LET_OP"); }
          ;

/* description of the tokens */
FLOAT:'float';
INT:'int';
MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';
WHILE: 'while';
FOR: 'for';
PRINTF: 'printf';
ASG_OP: '=';
ADD_OP: '+';
SUB_OP: '-';
STAR_OP: '*';
DIV_OP: '/';
BGT_OP: '>';
LET_OP: '<';
BEQ_OP: '>=';
LEQ_OP: '<=';
EQ_OP: '==';
NEQ_OP: '!=';
LPAR_OP: '(';
RPAR_OP: ')';
LBRA_OP: '{';
RBRA_OP: '}';
COMMA_OP: ',';
SEMCOL_OP: ';';

LITERAL: '"' (.)* '"';

Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT:'/*' .* '*/' {$channel=HIDDEN;};
COMMENT2: '//' (.)* '\n' {$channel=HIDDEN;};