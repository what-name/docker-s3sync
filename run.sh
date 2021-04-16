#!/bin/bash

# Set sane bash defaults
set -o errexit
set -o pipefail

OPTION="$1"

ACCESS_KEY=${ACCESS_KEY}
SECRET_KEY=${SECRET_KEY}
REGION=${REGION}
S3PATH=${S3PATH}
CRON_SCHEDULE=${CRON_SCHEDULE:-0 * * * *}
S3SYNCPARAMS=${S3SYNCPARAMS}

LOCKFILE="/tmp/aws-s3.lock"
LOG="/var/log/cron.log"


if [ ! -e $LOG ]; then
  touch $LOG
fi

if [[ $OPTION = "start" ]]; then
  CRONFILE="/etc/cron.d/s3sync"
  CRONENV=""

  echo "Found the following files and directores mounted under /data:"
  echo
  ls -F /data
  echo

  echo "Adding CRON schedule: $CRON_SCHEDULE"
  CRONENV="$CRONENV AWS_ACCESS_KEY_ID=$ACCESS_KEY"
  CRONENV="$CRONENV AWS_SECRET_ACCESS_KEY=$SECRET_KEY"
  CRONENV="$CRONENV AWS_DEFAULT_REGION=$REGION"
  CRONENV="$CRONENV S3PATH=$S3PATH"
  CRONENV="$CRONENV S3SYNCPARAMS=\"$S3SYNCPARAMS\""
  echo "$CRON_SCHEDULE root $CRONENV bash /run.sh backup" >> $CRONFILE

  echo "Starting CRON scheduler: $(date)"
  cron
  exec tail -f $LOG 2> /dev/null

elif [[ $OPTION = "backup" ]]; then
  echo "Starting copy: $(date)" | tee $LOG

  if [ -f $LOCKFILE ]; then
    echo "$LOCKFILE detected, exiting! Already running?" | tee -a $LOG
    exit 1
  else
    touch $LOCKFILE
  fi

  echo "Executing aws s3 sync /data/ $S3PATH $S3SYNCPARAMS..." | tee -a $LOG
  /usr/local/bin/aws s3 sync /data/ $S3PATH $S3SYNCPARAMS 2>&1 | tee -a $LOG
  rm -f $LOCKFILE
  echo "Finished copy: $(date)" | tee -a $LOG

else
  echo "Unsupported option: $OPTION" | tee -a $LOG
  exit 1
fi
