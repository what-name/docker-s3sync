#!/bin/bash

# Set sane bash defaults
set -o errexit
set -o pipefail

OPTION="$1"

ACCESS_KEY=${ACCESS_KEY}
SECRET_KEY=${SECRET_KEY}
S3PATH=${S3PATH}
CRON_SCHEDULE=${CRON_SCHEDULE:-0 * * * *}
S3SYNCPARAMS=${S3SYNCPARAMS}

LOCKFILE="/tmp/aws-s3.lock"
LOG="/var/log/cron.log"

# Check if ROLE_ARN is supplied
if [[ -v ROLE_ARN ]]; then
  ROLE_ARN=${ROLE_ARN}

  echo "[source]" > /root/.aws/credentials
  echo "aws_access_key_id=$ACCESS_KEY" >> /root/.aws/credentials
  echo "aws_secret_access_key=$SECRET_KEY" >> /root/.aws/credentials
  echo "region=eu-central-1" >> /root/.aws/credentials
  echo "[source]" > /root/.aws/config
  echo "" >> /root/.aws/config
  echo "[s3sync]" >> /root/.aws/config
  echo "role_arn=$ROLE_ARN" >> /root/.aws/config
  echo "source_profile=source" >> /root/.aws/config
else
  echo "[s3sync]" > /root/.aws/credentials
  echo "aws_access_key_id=$ACCESS_KEY" >> /root/.aws/credentials
  echo "aws_secret_access_key=$SECRET_KEY" >> /root/.aws/credentials
  echo "[s3sync]" > /root/.aws/config
fi

# delete me
cat /root/.aws/credentials
cat /root/.aws/config


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
  CRONENV="$CRONENV AWS_CONFIG_FILE=/root/.aws/config"
  CRONENV="$CRONENV AWS_SHARED_CREDENTIALS_FILE=/root/.aws/credentials" 
  CRONENV="$CRONENV HOME=/root"
  CRONENV="$CRONENV S3PATH=$S3PATH"
  CRONENV="$CRONENV S3SYNCPARAMS=\"$S3SYNCPARAMS\""
  echo "$CRON_SCHEDULE root $CRONENV bash /run.sh backup" >> $CRONFILE

  #delete me
  cat $CRONFILE

  echo "Starting CRON scheduler: $(date)"
  cron
  exec tail -f $LOG 2> /dev/null

elif [[ $OPTION = "backup" ]]; then
  #echo "aws sts get-caller-identity" | tee $LOG
  #/usr/local/bin/aws sts get-caller-identity 2>&1 | tee -a $LOG
  echo "aws configure gets" | tee $LOG
  /usr/local/bin/aws configure get profile.s3sync.aws_access_key_id 2>&1 | tee -a $LOG
  /usr/local/bin/aws configure get profile.s3sync.aws_secret_access_key 2>&1 | tee -a $LOG
  /usr/local/bin/aws configure get profile.s3sync.role_arn 2>&1 | tee -a $LOG

  echo "Starting copy: $(date)" | tee $LOG

  if [ -f $LOCKFILE ]; then
    echo "$LOCKFILE detected, exiting! Already running?" | tee -a $LOG
    exit 1
  else
    touch $LOCKFILE
  fi

  echo "Executing aws s3 sync /data/ $S3PATH $S3SYNCPARAMS..." | tee -a $LOG
  /usr/local/bin/aws s3 sync /data/ $S3PATH $S3SYNCPARAMS --profile s3sync 2>&1 | tee -a $LOG
  rm -f $LOCKFILE
  echo "Finished copy: $(date)" | tee -a $LOG

else
  echo "Unsupported option: $OPTION" | tee -a $LOG
  exit 1
fi
