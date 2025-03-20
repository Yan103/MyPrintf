#include <stdio.h>

extern int MyPrintf(const char *fmt, ...) ; //__attribute__ ((format(printf, 1, 2)));

int main() {
    MyPrintf("Test: %d %d %d %c %s\n", 333, 224, -17, '!', "aboba");

    printf("---------------------------------------------\n");
    
    MyPrintf("Number test: %d %b %o %x\n", 15, 15, 15, 15, 15);

    return 0;
}
