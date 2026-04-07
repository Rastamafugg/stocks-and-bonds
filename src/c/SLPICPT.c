#include <signal.h>

static int lastsig;
static int hitcount;
static int installed;

static sigtrap(sig)
int sig;
{
    lastsig = sig;
    ++hitcount;
    return 0;
}

slpicpt(cnt, cmem, cmemsiz, action, actionsz, sigout, sigoutsz,
        cntout, cntoutsz, okout, okoutsz)
int cnt;
char *cmem;
int cmemsiz;
int *action;
int actionsz;
int *sigout;
int sigoutsz;
int *cntout;
int cntoutsz;
int *okout;
int okoutsz;
{
#asm
    ldy 6,s
#endasm

    *okout = 0;
    *sigout = 0;
    *cntout = 0;

    if (*action == 1) {
        lastsig = 0;
        hitcount = 0;
        if (!installed) {
            intercept(sigtrap);
            installed = 1;
        }
        *okout = 1;
        return 0;
    }

    if (*action == 2) {
        *sigout = lastsig;
        *cntout = hitcount;
        *okout = 1;
        return 0;
    }

    return 0;
}

#asm
_stkcheck:
_stkchec:
        rts

        vsect
_flacc: rmb 8
errno:  rmb 2
        endsect
#endasm
