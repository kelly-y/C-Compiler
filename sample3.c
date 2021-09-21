void main()
{
    float a;
    float b;
    float c;

    a = 3.0 * 20.0;     // a = 60
    b = 3.0 + 5.0/2.5 - 2.654;   // b = 2.346

    printf("This is FOR part.\n");
    for(;a>0.0;)
    {
        c = a / b + 3.0 - 1.0 - 2.0*1.0;  // c = 25.57544757
        printf("Now c = %f\n", c);
        a = -a;
    }

    printf("This is WHILE part.\n");
    while(b >= 0.0)
    {
        if(b>=0.0)
            printf("Hi, b = %f\n", b);
        else
            printf("Hello World.\n");

        b = -b;
    }

    printf("Print a, b, c, a=%f, b=%f, c=%f\n\n", a, b, c);
}