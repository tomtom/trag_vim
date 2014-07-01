#!/bin/bash
# grep.sh -- created 2014-06-30, Tom Link
# @Last Change: 2014-06-30.
# @Revision:    6

RX=$1
FILELIST=$2

if [ -z `which cygpath` ]; then
    FILES=$(cygpath -u $(cat $(cygpath -u "$FILELIST")))
else
    FILES=$(cat "$FILELIST")
fi

exec grep -Hn -G "$RX" "$FILES"

