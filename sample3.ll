

@str0 = private unnamed_addr constant [19 x i8] c"This is FOR part.\0A\00"
@str1 = private unnamed_addr constant [12 x i8] c"Now c = %f\0A\00"
@str2 = private unnamed_addr constant [21 x i8] c"This is WHILE part.\0A\00"
@str3 = private unnamed_addr constant [12 x i8] c"Hi, b = %f\0A\00"
@str4 = private unnamed_addr constant [14 x i8] c"Hello World.\0A\00"
@str5 = private unnamed_addr constant [34 x i8] c"Print a, b, c, a=%f, b=%f, c=%f\0A\0A\00"

; === prologue ===
declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @main()
{
%t0 = alloca float, align 4
%t1 = alloca float, align 4
%t2 = alloca float, align 4
%t3 = fmul double 0x4008000000000000, 0x4034000000000000
%t4 = fptrunc double %t3 to float
store float %t4, float* %t2
%t5 = fdiv double 0x4014000000000000, 0x4004000000000000
%t6 = fptrunc double %t5 to float
%t7 = fpext float %t6 to double
%t8 = fadd double 0x4008000000000000, %t7
%t9 = fptrunc double %t8 to float
%t10 = fpext float %t9 to double
%t11 = fsub double %t10, 0x40053b6460000000
%t12 = fptrunc double %t11 to float
store float %t12, float* %t1
%t13 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([19 x i8], [19 x i8]* @str0, i32 0, i32 0))
br label %L1

L1: 
%t14 = load float, float* %t2, align 4
%t15 = fpext float %t14 to double
%t16 = fcmp ogt double %t15, 0x0
br i1 %t16, label %L2, label %L4

L3: 
br label %L1

L2: 
%t17 = load float, float* %t2, align 4
%t18 = load float, float* %t1, align 4
%t19 = fdiv float %t17, %t18
%t20 = fpext float %t19 to double
%t21 = fadd double %t20, 0x4008000000000000
%t22 = fptrunc double %t21 to float
%t23 = fpext float %t22 to double
%t24 = fsub double %t23, 0x3ff0000000000000
%t25 = fptrunc double %t24 to float
%t26 = fmul double 0x4000000000000000, 0x3ff0000000000000
%t27 = fptrunc double %t26 to float
%t28 = fsub float %t25, %t27
store float %t28, float* %t0
%t29 = load float, float* %t0, align 4
%t30 = fpext float %t29 to double
%t31 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str1, i32 0, i32 0), double %t30)
%t32 = load float, float* %t2, align 4
%t33 = fpext float %t32 to double
%t34 = fsub double 0x0, %t33
%t35 = fptrunc double %t34 to float
store float %t35, float* %t2
br label %L3

L4: 
%t36 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([21 x i8], [21 x i8]* @str2, i32 0, i32 0))
br label %L5

L5: 
%t37 = load float, float* %t1, align 4
%t38 = fpext float %t37 to double
%t39 = fcmp oge double %t38, 0x0
br i1 %t39, label %L6, label %L7

L6: 
%t40 = load float, float* %t1, align 4
%t41 = fpext float %t40 to double
%t42 = fcmp oge double %t41, 0x0
br i1 %t42, label %L8, label %L9

L8: 
%t43 = load float, float* %t1, align 4
%t44 = fpext float %t43 to double
%t45 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str3, i32 0, i32 0), double %t44)
br label %L10

L9: 
%t46 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([14 x i8], [14 x i8]* @str4, i32 0, i32 0))
br label %L10

L10: 
%t47 = load float, float* %t1, align 4
%t48 = fpext float %t47 to double
%t49 = fsub double 0x0, %t48
%t50 = fptrunc double %t49 to float
store float %t50, float* %t1
br label %L5

L7: 
%t51 = load float, float* %t0, align 4
%t52 = fpext float %t51 to double
%t53 = load float, float* %t1, align 4
%t54 = fpext float %t53 to double
%t55 = load float, float* %t2, align 4
%t56 = fpext float %t55 to double
%t57 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([34 x i8], [34 x i8]* @str5, i32 0, i32 0), double %t56, double %t54, double %t52)

; === epilogue ===
ret i32 0
}
