FROM ubuntu:20.04
MAINTAINER Dale Glass <daleglass@gmail.com>

ENV DEBIAN_FRONTEND="noninteractive"
ENV PATH="/webrtc-build/depot_tools:$PATH"
ENV TZ="Europe/Madrid"

RUN apt-get update
RUN apt-get -y -u dist-upgrade
RUN apt-get -y install build-essential git zlib1g-dev python curl wget clang libcurl4-openssl-dev libssl-dev python3 lsb-release sudo git tzdata

# WebRTC downloads an environment during build and fails when run as root, because tar
# tries to restore the non-existent user ID. So we need to run things as an user.
RUN adduser webrtc

# This is here for convenience, allows us to install stuff in the container easily.
# It can probably be removed later.
RUN adduser webrtc sudo
RUN sed -i 's/%sudo\s*ALL=(ALL:ALL) ALL/%sudo  ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

RUN mkdir /webrtc-build && chown webrtc:webrtc /webrtc-build

USER webrtc
WORKDIR /webrtc-build

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
RUN fetch --nohooks webrtc
RUN gclient sync
#RUN fetch webrtc

USER root
# This disables the installation of the snapcraft package. It tries to contact the snap
# store and for some reason can't do so within a docker container. This grinds things to a
# halt until it times out, and the package asks for user input.
#
# We shouldn't actually need it for anything.
RUN sed -i 's/snapcraft/snapcraft_disabled/g' /webrtc-build/src/build/install-build-deps.sh
RUN /webrtc-build/src/build/install-build-deps.sh --no-prompt

# Undo our changes, so that 'gclient sync' doesn't complain later.
RUN cd /webrtc-build/src/build && git checkout install-build-deps.sh

#COPY scripts/build.sh    /webrtc-build/
#COPY scripts/package.sh  /webrtc-build/


USER webrtc
ENTRYPOINT /bin/bash
