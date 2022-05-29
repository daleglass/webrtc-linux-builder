#!/bin/bash
EXTRA_ARGS="$@"

[ -z "$WEBRTC_CONTAINER" ] && WEBRTC_CONTAINER=ubuntu-20.04



# All this stuff is here because by default /var/tmp gets used, and it may not big
# enough on some systems to hold the temporary data. So we look for places with room.
#
# We avoid tmpfs because it might cause memory exhaustion.

most_space=0
most_space_dir=

for temp_dir in /tmp /var/tmp $HOME/tmp ; do
	filesystem=`awk "\\$2 == \"$temp_dir\" {print \\$3}" /proc/mounts`
#	echo "Filesystem for $temp_dir: $filesystem"

	if [ "$filesystem" != "tmpfs" ] ; then
		space=`df -k --output=avail "$temp_dir" | tail -n 1`
#		echo "Space in $temp_dir: $space"

		if [ "$space" -gt "$most_space" ] ; then
			most_space=$space
			most_space_dir=$temp_dir
		fi
	fi
done

echo "Setting temp dir to location with most free space: $most_space_dir"

export TEMPDIR=$most_space_dir
export TMPDIR=$TEMPDIR

echo "Building $WEBRTC_CONTAINER"
echo ""
podman build -f Dockerfile.$WEBRTC_CONTAINER $EXTRA_ARGS . -t webrtc-builder:$WEBRTC_CONTAINER
