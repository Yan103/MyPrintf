#include <stdio.h>

// TODO MyPrintf + jmptbl + buffer + default case in jmptable + CDECL
extern int myprintf(const char *fmt, ...) __attribute__ ((format(printf, 1, 2)));

int main() {
    int a = myprintf("Test: %% %d %d %c\n", 224, -17, '!');

    myprintf("%d\n", a);

    return 0;
}
