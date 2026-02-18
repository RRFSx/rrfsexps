#!/bin/bash
source /etc/profile
module use /ncrc/proj/epic/rocoto/modulefiles
source qrocoto/load_qrocoto.sh

recipents="Guoqing.Ge@noaa.gov Guoqing.Ge@noaa.gov"
subject="rt_GAEA alert"

knt=0
while true; do
  rrun
  knt=$(( knt+1 ))
  if (( knt == 5 )); then # check dead jobs or stalled workflow every 5 minutes
    knt=0

    curtime=$(date -u +%Y%m%d%H)
    PDY=${curtime:0:8}
    cyc=${curtime:8:2}

    cyc=$(( (10#${cyc} / 12) * 12 ))
    cyc=$(printf "%02d" ${cyc})
    prevCyc=$(date -u -d "${PDY} ${cyc} UTC -24 hours" +%Y%m%d%H)
    cycles=${prevCyc}00:${PDY}${cyc}00

    ## check whether we have dead jobs in the past 24 hours
    send_email=false
    msg=$(rstat ${cycles})
    echo "${msg}" | grep " DEAD "  > .msg.new

    # need to send out alerts when we get new DEAD jobs
    if [[ -s .msg.save  && -s .msg.new ]]; then
      # only send alerts if the new msg is different from the saved one to avoid duplicate alerts
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
    ## and if stalled for more than 3 hours, send out alerts
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

    if ${send_email}; then
      echo "${msg}" | mail -s "${subject}" ${recipents}
    fi
  fi

  sleep 60s # run rrun every 1 minute
done
