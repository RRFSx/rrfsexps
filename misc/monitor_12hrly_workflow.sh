#!/bin/bash
source /etc/profile
module load rocoto
cd /scratch4/BMC/zrtrr/gge/ARPS/PEAR/exp/rrfsdet
source qrocoto/load_qrocoto.sh
recipents="Guoqing.Ge@noaa.gov Guoqing.Ge@noaa.gov"
subject="rt_PEAR alert"

curtime=$(date -u +%Y%m%d%H)
PDY=${curtime:0:8}
cyc=${curtime:8:2}

cyc=$(( (10#${cyc} / 12) * 12 ))
cyc=$(printf "%02d" ${cyc})
prevCyc=$(date -u -d "${PDY} ${cyc} UTC -24 hours" +%Y%m%d%H)
cycles=${prevCyc}00:${PDY}${cyc}00

## check whether we have dead jobs in the past 24 hours
send_email=false
msg=$(rocotostat -w rrfs.xml -d rrfs.db -c ${cycles})
echo "${msg}" > .msg.new
if [[ -s .msg.save  && -s .msg.new ]]; then
  if ! diff .msg.save .msg.new &>/dev/null && [[ ${msg} == *DEAD* ]]; then
    send_email=true
    subject="${subject}: dead job(s)"
  fi
elif [[ ${msg} == *DEAD* ]]; then
  send_email=true
  subject="${subject}: dead job(s)"
fi
mv .msg.new .msg.save

## check whether if the workflow is stalled, i.e. no running jobs
if [[ ${msg} != *RUNNING* ]]; then
  if [[ -s .stall ]]; then
    stall_bgn=$(head -n 1 .stall)
    cur_seconds=$(date +%s)
    diff_secons=$(( cur_seconds - stall_bgn ))
    if (( diff_secons > 10800 )); then # stalled for 3 hours
      send_email=true
      rm -rf .stall
    fi
  else
    date +%s > .stall
  fi
else
  rm -rf .stall
fi

## check whether any running fcst jobs hang without any further outputs
rrun #&>/dev/null # update the rocoto db files first before rtasks
running=$(rtasks fcst 48 | grep "RUNNING" | awk '{print $1","$3}')
mapfile -t lines  <<< "${running}"
for line in ${lines[@]}; do
  cdate=${line:0:12}
  jobid=${line:13}
  cyc=${cdate:8:2}
  dir=$(taskinfo ${cdate} fcst | tail -n 1)
  log="${dir}/fcst_${cyc}/log.atmosphere.0000.out"
  log_secs=$( stat -c %Y ${log} )
  cur_secs=$( date +%s )
  diff_secs=$(( cur_secs - log_secs ))
  if (( diff_secs > 1200 )); then # hang for more than 20 minutes
    # cancel the hung fcst task and reboot it
    send_email=true
    subject="${subject}: ${line:6:4}_hang"
    scancel ${jobid} #&>/dev/null
    sleep 15s
    rrun ${cdate} fcst #&>/dev/null
    rboot ${cdate} fcst #&>/dev/null
  fi
done

if ${send_email}; then
  echo "${msg}" | mail -s "${subject}" ${recipents}
fi
