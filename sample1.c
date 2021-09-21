void main() 
{
    float a;
    float b;
    float c;

    a = 3.0;
    b = 4.0;
    
    if (a == b)
        c = a + b;
    if (a >= 4.0)
        c = b - 5.0;
    if (3.0 < 4.0)
        c = 5.0 * 3.0;

    printf("hello world\n\n");
    printf("c = %f\n", c);
}