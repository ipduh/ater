#!/bin/bash
#g0, 2018
#ater/wait-for-device.sh

ATER=`realpath ./ater`
SECS=`expr 0`
TRIES=`expr 1`

rm /tmp/ater.lock 2>/dev/null

for i in `cat logs/PIDS_*.ater`
do
  kill -9 $i \
         `expr $i + 1` \
         `expr $i + 2` \
  2>/dev/null
done

rm logs/PIDS_*.ater
adb kill-server 2>/dev/null
adb root
mkdir -p ./logcats

echo -n "${TRIES},${SECS} :"
while ! $ATER $@
do
  adb logcat -v long >> ./logcats/_$(date +%s).logcat &
  SECS=`expr $SECS + 4`
  TRIES=`expr $TRIES + 1`
  echo -n "${TRIES},${SECS} :"
  sleep 4
done
