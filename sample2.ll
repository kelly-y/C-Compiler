

@str0 = private unnamed_addr constant [12 x i8] c"Now a = %d\0A\00"
@str1 = private unnamed_addr constant [18 x i8] c"This is IF part.\0A\00"
@str2 = private unnamed_addr constant [12 x i8] c"Now a = %d\0A\00"
@str3 = private unnamed_addr constant [21 x i8] c"Print a = %d again.\0A\00"
@str4 = private unnamed_addr constant [14 x i8] c"Hello world.\0A\00"
@str5 = private unnamed_addr constant [8 x i8] c"Hello.\0A\00"
@str6 = private unnamed_addr constant [8 x i8] c"World.\0A\00"
@str7 = private unnamed_addr constant [20 x i8] c"This is ELSE part.\0A\00"

; === prologue ===
declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @main()
{
%t0 = alloca i32, align 4
%t1 = mul nsw i32 5, 1
%t2 = add nsw i32 4, %t1
%t3 = add nsw i32 %t2, -3
%t4 = mul nsw i32 3, %t3
%t5 = sdiv i32 %t4, 2
%t6 = add nsw i32 %t5, 5
store i32 %t6, i32* %t0
%t7 = load i32, i32* %t0, align 4
%t8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str0, i32 0, i32 0), i32 %t7)
%t9 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([18 x i8], [18 x i8]* @str1, i32 0, i32 0))
%t10 = load i32, i32* %t0, align 4
%t11 = icmp sgt i32 %t10, 10
br i1 %t11, label %L1, label %L2

L1: 
%t12 = load i32, i32* %t0, align 4
%t13 = sub nsw i32 %t12, 1
store i32 %t13, i32* %t0
%t14 = load i32, i32* %t0, align 4
%t15 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str2, i32 0, i32 0), i32 %t14)
%t16 = load i32, i32* %t0, align 4
%t17 = icmp sgt i32 %t16, 10
br i1 %t17, label %L4, label %L5

L4: 
%t18 = load i32, i32* %t0, align 4
%t19 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([21 x i8], [21 x i8]* @str3, i32 0, i32 0), i32 %t18)
br label %L6

L5: 
%t20 = load i32, i32* %t0, align 4
%t21 = icmp ne i32 %t20, 10
br i1 %t21, label %L7, label %L8

L7: 
%t22 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([14 x i8], [14 x i8]* @str4, i32 0, i32 0))
br label %L9

L8: 
%t23 = load i32, i32* %t0, align 4
%t24 = icmp sle i32 %t23, 3
br i1 %t24, label %L10, label %L11

L10: 
%t25 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @str5, i32 0, i32 0))
br label %L12

L11: 
%t26 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @str6, i32 0, i32 0))
br label %L12

L12: 
br label %L9

L9: 
br label %L6

L6: 
br label %L3

L2: 
%t27 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([20 x i8], [20 x i8]* @str7, i32 0, i32 0))
br label %L3

L3: 

; === epilogue ===
ret i32 0
}
