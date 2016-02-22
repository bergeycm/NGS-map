#!/bin/sh

TO_CLR=$1

TMPFILE=`mktemp`

# Save the timestamp
touch -r $TO_CLR $TMPFILE

> $TO_CLR

# Restore the timestamp after truncation
touch -r $TMPFILE $TO_CLR

rm $TMPFILE
