#!/bin/sh
#
# Takes the JBoss PID as an argument. 
#
# Captures cpu by light weight thread and thread dumps a specified number of
# times and INTERVAL. Thread dumps are retrieved using jstack and are placed in 
# high-cpu-tdump.out
#
# Usage: sh ./high_cpu_linux_jstack.sh <JBOSS_PID> <LOOP> <INTERNVAL>
#
# Change Log:
# * 2011-05-02 19:00 <loleary>
# - Added date output to high-cpu.out for log correlation
# - Added -p argument to top to limit high-cpu.out to <JBOSS_PID>
# - Enfored usage of parameters
#

if [[ $# -ne 3 ]]; then
  echo "Usage: `basename $0` <pid> <num_of_samples> <interval>"
  exit 1
fi

# Number of times to collect data.
LOOP=$2
# Interval in seconds between data points.
INTERVAL=$3
# PID to be captured
PID=$1

for ((i=1; i <= $LOOP; i++))
do
   _now=$(date)
   echo "${_now}" >>high-cpu.out
   top -b -n 1 -H -p $PID >>high-cpu.out
   echo "${_now}" >>high-cpu-tdump.out
   jstack -l $PID >>high-cpu-tdump.out
   echo "thread dump #" $i
   if [ $i -lt $LOOP ]; then
      echo "Sleeping..."
      sleep $INTERVAL
   fi
done
