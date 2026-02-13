#!/bin/bash
source /etc/profile
module load rocoto
cd /scratch5/purged/gge/arps/PEAR/exp/rrfsdet
recipents="Guoqing.Ge@noaa.gov Guoqing.Ge@noaa.gov"
subject="rt_PEAR alert"

curtime=$(date -u +%Y%m%d%H)
PDY=${curtime:0:8}
cyc=${curtime:8:2}

cyc=$(( (10#${cyc} / 12) * 12 ))
prevCyc=$(date -u -d "${PDY} ${cyc} UTC -24 hours" +%Y%m%d%H)
cycles=${prevCyc}00:${PDY}${cyc}00

send_email=false
msg=$(rocotostat -w rrfs.xml -d rrfs.db -c ${cycles})
echo "${msg}" > .msg.new

if [[ -s .msg.save  && -s .msg.new ]]; then
  if ! diff .msg.save .msg.new &>/dev/null && [[ ${msg} == *DEAD* ]]; then
    send_email=true
  fi
elif [[ ${msg} == *DEAD* ]]; then
  send_email=true
fi
mv .msg.new .msg.save

## check whether if the workflow is stalled, i.e. no running jobs
if [[ ${msg} != *RUNNING* ]]; then
  if [[ -s .stall ]]; then
    stall_bgn=$(head -n 1 .stall)
    cur_seconds=$(date +%s)
    diff_secons=$(( cur_seconds - stall_bgn ))
    if (( diff_secons > 3600 )); then # stalled for an hour
      send_email=true
      rm -rf .stall
    fi
  else
    date +%s > .stall
  fi
fi

if ${send_email}; then
  echo "${msg}" | mail -s "${subject}" ${recipents}
fi
