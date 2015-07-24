#!/bin/bash

TMP_DIR=~/tmp
DUMP1=${TMP_DIR}/db_1.sql
DUMP2=${TMP_DIR}/db_2.sql

if [ $# -lt 2 ];
then
  echo "usage: diff_db.sh file1.db file2.db [cmd]"
  echo "  where cmd is one of:"
  echo "  diff    (default) do diff at the end"
  echo "  vim     do vimdiff at the end"
  echo "  clean   don't dump but clean tmp files"
  exit 1
fi

if [ "$3" != "clean" ]
then
  echo .dump | sqlite3 $1 > $DUMP1
  echo .dump | sqlite3 $2 > $DUMP2
fi

if [ $# -eq 2 ] || [ "$3" = "diff" ]
then
  diff $DUMP1 $DUMP2
elif [ "$3" = "vim" ]
then
  vimdiff $DUMP1 $DUMP2
elif [ "$3" = "clean" ]
then
  rm $DUMP1
  rm $DUMP2
else
  echo "Unknown command " $3
fi
