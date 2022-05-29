#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
[ -z "$WEBRTC_CONTAINER" ] && WEBRTC_CONTAINER=ubuntu-20.04

$SCRIPTPATH/build_container.sh


echo "Running shell in $WEBRTC_CONTAINER"
echo ""
podman run -it  \
	-v $SCRIPTPATH/patches:/webrtc-build/patches:Z \
	-v $SCRIPTPATH/scripts:/webrtc-build/scripts:Z \
	-v $SCRIPTPATH/out:/webrtc-build/out:Z \
	 webrtc-builder:$WEBRTC_CONTAINER
