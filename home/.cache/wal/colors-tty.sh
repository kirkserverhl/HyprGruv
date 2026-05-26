#!/bin/sh
[ "${TERM:-none}" = "linux" ] && \
    printf '%b' '\e]P00c0505
                 \e]P1535353
                 \e]P25B5B5B
                 \e]P3676767
                 \e]P4777777
                 \e]P5878787
                 \e]P6969696
                 \e]P7c2c0c0
                 \e]P8675555
                 \e]P9535353
                 \e]PA5B5B5B
                 \e]PB676767
                 \e]PC777777
                 \e]PD878787
                 \e]PE969696
                 \e]PFc2c0c0
                 \ec'
