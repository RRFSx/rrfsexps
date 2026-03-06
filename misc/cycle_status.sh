#!/bin/bash
# shellcheck disable=all
# check the workflow status by examining rrfs.log
# by Guoqing Ge, 2025/03
#
source exp.setup
CDATE=$1
RUN=rrfs

check_status(){
  local check_type=$1
  local mytask=$2
  local my_tot_num=$3
  if [[ "${check_type}" == "succeeded" ]]; then
    output=$(grep "Task ${mytask}.*, jobid=.*, in state" "${rrfslog}")
    if [[ -z "${output}" ]]; then
      nSuccess=0
    else
      nSuccess=$(printf "%s\n" "${output}" | grep 'SUCCEEDED' | wc -l)
    fi
  elif [[ "${check_type}" == "submitted" ]]; then
    output=$(grep "Submission of ${mytask}.*, jobid=" "${rrfslog}")
    if [[ -z "${output}" ]]; then
      nSuccess=0
    else
      nSuccess=$(printf "%s\n" "${output}" | grep 'succeeded' | wc -l)
    fi
  elif [[ "${check_type}" == "submitting" ]]; then
    output=$(grep "Submitting ${mytask}" "${rrfslog}")
    if [[ -z "${output}" ]]; then
      nSuccess=0
    else
      nSuccess=$(printf "%s\n" "${output}" | wc -l)
    fi
  else
    echo "unsupported check_type: ${check_type}"
    exit 1
  fi

  if [[ -z "${output}" ]]; then
    nOutput=0
  else
    nOutput=$(printf "%s\n" "${output}" | wc -l)
  fi
  if (( nOutput == 0 )); then  # may not start yet, continue check other situations
    :
  elif (( nSuccess >= ${my_tot_num} )); then
    echo -e "\n${CDATE}: ${mytask} all ${check_type}!"
    exit 0
  else
    echo -e "\n${CDATE}: ${mytask} ${check_type} ${nSuccess}/${my_tot_num} --- !!ATTENTION!! ---"
    printf "%s\n" "${output}"
  fi
}

if [[ ! -s exp.setup ]]; then
  echo "Run this command under the expdir where exp.setup is located"
  exit
fi
if [[ $# < 1 ]]; then
  echo "$(basename $0) <YYYYMMDDHH|YYYYMMDDHHmm>"
  exit
fi

# find rrfs.log
PDY=${CDATE:0:8}
cyc=${CDATE:8:2}
logroot=${COMROOT}/${NET}/${VERSION}/logs
rrfslog="${logroot}/${RUN}.${PDY}/${cyc}/${WGF}/rrfs.log"
if [[ ! -s "${rrfslog}" ]]; then
  echo "file not found: ${rrfslog}"
  exit 1
else
  echo "${rrfslog}"
fi

#------  UPP  -------------------------------------------------
mytask=upp
my_tot_num=${UPP_GROUP_TOTAL_NUM}
check_status succeeded "${mytask}" "${my_tot_num}"
check_status submitted "${mytask}" "${my_tot_num}"
check_status submitting "${mytask}" "${my_tot_num}"

#------  fcst  ------------------------------------------------
mytask=fcst
my_tot_num=1
check_status succeeded "${mytask}" "${my_tot_num}"
check_status submitted "${mytask}" "${my_tot_num}"
check_status submitting "${mytask}" "${my_tot_num}"

#------  prep_ic  ------------------------------------------------
mytask=prep_ic
my_tot_num=1
check_status succeeded "${mytask}" "${my_tot_num}"
check_status submitted "${mytask}" "${my_tot_num}"
check_status submitting "${mytask}" "${my_tot_num}"

#------  ungrib_ic  ------------------------------------------------
mytask=ungrib_ic
my_tot_num=1
check_status succeeded "${mytask}" "${my_tot_num}"
check_status submitted "${mytask}" "${my_tot_num}"
check_status submitting "${mytask}" "${my_tot_num}"
