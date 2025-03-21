#include <stdio.h>

extern int MyPrintf(const char *fmt, ...) ; //__attribute__ ((format(printf, 1, 2)));

// %c косяк

int main() {
    //MyPrintf("Test: %d %d %d %c %d\n", 333, 224, -17, '!', 1100);

    MyPrintf("%s %x %d%%%c %b %s %d\n", "love", 3802, 100, 33, 126, "it work!", 111);

    //printf("---------------------------------------------\n");

    //MyPrintf("Number test: %s %d %b %o %x\n", "proverka", 15, 126, 15, 15, 15);

    //MyPrintf("%d %d %d %d %d %d %c\n", 1, 2, 3, 4, 5, 6, '!');

    return 0;
}
