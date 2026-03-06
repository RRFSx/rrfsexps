#!/bin/bash
recipents="Guoqing.Ge@noaa.gov Guoqing.Ge@noaa.gov"
subject="rt_GAEA"

CDATE=$(date -u +%Y%m%d%H)
hour=${CDATE:8:2}
if (( hour < 12 )); then
  cyc=00
else
  cyc=12
fi
CDATE=${CDATE:0:8}${cyc}00

msg=$(./cycle_status.sh "${CDATE}")
if [[ "$1" == "show" ]]; then
  echo "$msg"
fi

if [[ ! -e ".status.${CDATE}_done" ]]; then
  if [[ ! -e ".status.${CDATE}.ungrib_ic_succeeded" ]] && [[ "${msg}" == *"ungrib_ic all succeeded!"* ]]; then 
    echo "-" | mail -s "${subject}: ungrib_ic succeeded" ${recipents}
    touch ".status.${CDATE}.ungrib_ic_succeeded"
  elif [[ ! -e ".status.${CDATE}.fcst_submitting" ]] && [[ "${msg}" == *"fcst all submitting!"* ]]; then 
    echo "${msg}" | mail -s "${subject}: fcst submitting" ${recipents}
    touch ".status.${CDATE}.fcst_submitting"
  elif [[ ! -e ".status.${CDATE}.fcst_succeeded" ]] && [[ "${msg}" == *"fcst all succeeded!"* ]]; then 
    echo "-" | mail -s "${subject}: fcst succeeded" ${recipents}
    touch ".status.${CDATE}.fcst_succeeded"
  elif [[ "${msg}" == *"upp all succeeded!"* ]]; then 
    echo "-" | mail -s "${subject}: upp succeeded" ${recipents}
    rm -rf .status.${CDATE}_*
    touch ".status.${CDATE}_done"
  fi
fi
