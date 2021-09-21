

@str0 = private unnamed_addr constant [14 x i8] c"hello world\0A\0A\00"
@str1 = private unnamed_addr constant [8 x i8] c"c = %f\0A\00"

; === prologue ===
declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @main()
{
%t0 = alloca float, align 4
%t1 = alloca float, align 4
%t2 = alloca float, align 4
store float 3.0, float* %t2
store float 4.0, float* %t1
%t3 = load float, float* %t2, align 4
%t4 = load float, float* %t1, align 4
%t5 = fcmp oeq float %t3, %t4
br i1 %t5, label %L1, label %L2

L1: 
%t6 = load float, float* %t2, align 4
%t7 = load float, float* %t1, align 4
%t8 = fadd float %t6, %t7
store float %t8, float* %t0
br label %L3

L2: 
br label %L3

L3: 
%t9 = load float, float* %t2, align 4
%t10 = fpext float %t9 to double
%t11 = fcmp oge double %t10, 0x4010000000000000
br i1 %t11, label %L4, label %L5

L4: 
%t12 = load float, float* %t1, align 4
%t13 = fpext float %t12 to double
%t14 = fsub double %t13, 0x4014000000000000
%t15 = fptrunc double %t14 to float
store float %t15, float* %t0
br label %L6

L5: 
br label %L6

L6: 
%t16 = fcmp olt double 0x4008000000000000, 0x4010000000000000
br i1 %t16, label %L7, label %L8

L7: 
%t17 = fmul double 0x4014000000000000, 0x4008000000000000
%t18 = fptrunc double %t17 to float
store float %t18, float* %t0
br label %L9

L8: 
br label %L9

L9: 
%t19 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([14 x i8], [14 x i8]* @str0, i32 0, i32 0))
%t20 = load float, float* %t0, align 4
%t21 = fpext float %t20 to double
%t22 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @str1, i32 0, i32 0), double %t21)

; === epilogue ===
ret i32 0
}
