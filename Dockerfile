FROM debian:latest
MAINTAINER Paul Wiggett <mrporcles@gmail.com>
#AWS CLI Version 1.11.178

ENV DEBIAN_FRONTEND="noninteractive" HOME="/root" LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron python3 python3-magic python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install awscli && \
  rm -rf /tmp/pip_build_root/

RUN mkdir -p /data
RUN mkdir -p /root/.aws

ADD run.sh /

ENTRYPOINT ["/run.sh"]
CMD ["start"]
