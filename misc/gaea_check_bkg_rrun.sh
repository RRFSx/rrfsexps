#!/bin/bash
SCREEN_NAME=bkg_rrun

NODE=gaea68  # users modify this based on their situations
WORKDIR=/gpfs/f6/arfs-gsl/world-shared/gge/rrfs2/PEAR/rt202603/exp/rrfsdet
CMD=./gaea_bkg_rrun_and_monitor.sh

ssh -T -o BatchMode=yes ${NODE} << EOF
# Check if the screen session exists
if screen -list | grep -q "\\.${SCREEN_NAME}.*(Detached)"; then
    exit 0
else
    screen -wipe &> /dev/null
    screen -dmS ${SCREEN_NAME} bash -c "
        cd ${WORKDIR} || exit 1
        ${CMD}
        exec bash
    "
fi
EOF


### modify lines between SCRON_BLOCK as needed, then run "scrontab -e" to add them into scrontab
### Notes: (don't not manually run gaea_check_bkg_rrun.sh in screen)
###     ssh gaea68  # log into gaea68
###     screen -list # list running sessions
###     screen -r bkg_rrun   # attached to the running session
###     CTRL+a and then d to detach the 'bkg_rrun' screen session
<<SCRON_BLOCK
#SCRON --partition=cron_c6
#SCRON --account=arfs-gsl
#SCRON --time=00:10:00
#SCRON --mail-user=Guoqing.Ge@noaa.gov
#SCRON --dependency=singleton
#SCRON --job-name=check-rt-ar3.5km
#SCRON --output=/dev/null
*/5 * * * * /gpfs/f6/arfs-gsl/world-shared/gge/rrfs2/PEAR/rt202603/exp/rrfsdet/gaea_check_bkg_rrun.sh
SCRON_BLOCK
