#include <stdio.h>

extern int MyPrintf(const char *fmt, ...) ; //__attribute__ ((format(printf, 1, 2)));

int main() {
    int a = MyPrintf("Test: %d %d %c %s\n", 224, -17, '!', "aboba");
    MyPrintf("Number test: %d %b %o %x\n", 15, 15, 15, 15, 15);
    MyPrintf("%d\n", a);

    return 0;
}
