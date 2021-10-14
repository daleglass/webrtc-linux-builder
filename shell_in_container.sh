#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

$SCRIPTPATH/build_container.sh
podman run -it  \
	-v $SCRIPTPATH/patches:/webrtc-build/patches:Z \
	-v $SCRIPTPATH/scripts:/webrtc-build/scripts:Z \
	-v $SCRIPTPATH/out:/webrtc-build/out:Z \
	 webrtc-builder:20.04 
