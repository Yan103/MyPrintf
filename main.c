#include <stdio.h>

// TODO bufferization !
extern int MyPrintf(const char *fmt, ...) __attribute__ ((format(printf, 1, 2)));

int main() {
    int a = MyPrintf("Test: %% %d %d %c\n", 224, -17, '!');

    MyPrintf("%d\n", a);

    return 0;
}
