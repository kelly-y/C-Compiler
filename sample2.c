void main()
{
    int a;
    a = 3 * (4 + 5*1 + -3) / 2 + 5; // a = 14

    printf("Now a = %d\n", a);

    printf("This is IF part.\n");
    if(a > 10) 
    {
        a = a - 1;
        printf("Now a = %d\n", a);

        if(a > 10)
            printf("Print a = %d again.\n", a);
        else if(a != 10)
            printf("Hello world.\n");
        else if(a <= 3)
            printf("Hello.\n");
        else
            printf("World.\n");
    }
    else
        printf("This is ELSE part.\n");
}