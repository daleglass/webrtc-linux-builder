#!/bin/bash


help() {
	cat <<HELP
$0 <options>

Options:
	--builddir dir   Directory where WebRTC was built. Eg, out/Debug.
	--outdir dir     Where to create the resulting .tar.xz
        --name name      Name for the archive (eg, gcc or clang)
	--version ver    Version for the archive

Example:
	$0 --builddir /webrtc-build/src/out/Debug-gcc/ --name gcc --outdir /webrtc-build/out/

HELP
	exit 1
}

while [[ $# -gt 0 ]] ; do
	arg="$1"
	case $arg in
		--builddir)
			out_dir="$2"
			shift
			shift
			;;
		--outdir)
			archive_dir="$2"
			shift
			shift
			;;
		--name)
			archive_name="$2"
			shift
			shift
			;;
		--version)
			version="$2"
			shift
			shift
			;;
		*)
			echo "Unknown argument!"
			exit 1
			;;
	esac

done


if [ -z "$out_dir" -o -z "$archive_dir" -o -z "$archive_name" ] ; then
	help
fi

source_dir="$out_dir/../.."
start_dir=`pwd`

set -e

if [ ! -f "$out_dir/obj/libwebrtc.a" ] ; then
	echo "Couldn't find $out_dir/obj/libwebrtc.a"
	exit 1
fi

if [ ! -f "$source_dir/test/gmock.h" ] ; then
	echo "Couldn't find $source_dir/test/gmock.h"
	exit 1
fi


repo_date() {
	repo="$1"
	echo "Getting repo date for $repo" 1>&2

	date +%Y%m%d -d @`git -C "$repo" log -1 --format=%at`
	
}

copy_headers() {
	src="$1"
	dst="$2"
	mkdir -p "$dst"
	cp -v $src/*.h "$dst"
}


copy_headers_rec2() {
	src="$1"
	dst="$2"

	curdir=`pwd`


	echo "Copying headers, $src => $dst"

	if [ ! -d "$src" ] ; then
		echo "Failed to find $src!"
		exit 1
	fi

	mkdir -p "$dst"


	cd "$src"
	find . -name '*.h' -exec cp --parents '{}' "$dst/" ';'
	cd "$curdir"
}


temp_root=`mktemp -d`
webrtc="$temp_root/webrtc"
include="$webrtc/include/webrtc"

mkdir -p "$webrtc" "$webrtc/lib" "$webrtc/debug/lib" "$webrtc/include/webrtc/test" 
#mkdir -p "$webrtc/include/webrtc/modules/audio_"
mkdir -p "$webrtc/share/webrtc" "$include/modules"


cp -v "$out_dir/obj/libwebrtc.a"                    "$webrtc/lib"
cp -v "$out_dir/obj/libwebrtc.a"                    "$webrtc/debug/lib"
cp -v "$source_dir/test/gmock.h"                    "$webrtc/include/webrtc/test/"
cp -v "$source_dir/LICENSE"                         "$webrtc/share/webrtc/copyright"

# As in cmake/ports/webrtc/copy-VCPKG-file-win.cmd
cp -v "$source_dir/common_types.h"                  "$include/"
copy_headers_rec2 "$source_dir/api"                               "$include/api"
copy_headers_rec2 "$source_dir/audio"                             "$include/audio"
copy_headers_rec2 "$source_dir/base"                              "$include/base"
copy_headers_rec2 "$source_dir/call"                              "$include/call"
copy_headers_rec2 "$source_dir/common_audio"                      "$include/common_audio"
copy_headers_rec2 "$source_dir/common_video"                      "$include/common_video"
copy_headers_rec2 "$source_dir/logging"                           "$include/logging"
copy_headers_rec2 "$source_dir/media"                             "$include/media"
copy_headers_rec2 "$source_dir/modules"                           "$include/modules"
copy_headers_rec2 "$source_dir/p2p"                               "$include/p2p"
copy_headers_rec2 "$source_dir/pc"                                "$include/pc"
copy_headers_rec2 "$source_dir/rtc_base"                          "$include/rtc_base"
copy_headers_rec2 "$source_dir/rtc_tools"                         "$include/rtc_tools"
copy_headers_rec2 "$source_dir/stats"                             "$include/stats"
copy_headers_rec2 "$source_dir/system_wrappers"                   "$include/system_wrappers"
copy_headers_rec2 "$source_dir/third_party/abseil-cpp/absl"       "$include/absl"
copy_headers_rec2 "$source_dir/third_party/libyuv/include/libyuv" "$include/libyuv"
copy_headers_rec2 "$source_dir/video"                             "$include/video"


echo "*** Generated in $temp_root"
cd "$temp_root"

if [ -z "$version" ] ; then
	version=`repo_date "$source_dir"`
fi

destfile="$archive_dir/webrtc-${version}-${archive_name}-linux.tar.xz"

echo "Compressing..."
export XZ_OPT=-T0
tar -c --xz -f "$destfile" "webrtc"
echo "Archive written to: $destfile"

sha512sum "$destfile"
rm -rf "$temp_root"


