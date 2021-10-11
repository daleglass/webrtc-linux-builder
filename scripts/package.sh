#!/bin/bash



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
		*)
			echo "Unknown argument!"
			exit 1
			;;
	esac

done




#out_dir="$1"
#archive_name="$2"

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


copy_headers_rec() {
	base="$1"
	src="$2"
	dst="$3"

	curdir=`pwd`


	echo "Copying headers, base $base, subdir $src"

	if [ ! -d "$base/$src" ] ; then
		echo "Failed to find $base/$src!"
		exit 1
	fi

	cd "$base"
	mkdir -p "$dst"
	find "$src" -name '*.h' -exec cp -v --parents '{}' "$dst" ';'
	cd "$curdir"
}

temp_root=`mktemp -d`
webrtc="$temp_root/webrtc"
include="$webrtc/include/webrtc"

mkdir -p "$webrtc" "$webrtc/lib" "$webrtc/debug/lib" "$webrtc/include/webrtc/test" 
#mkdir -p "$webrtc/include/webrtc/modules/audio_"
mkdir -p "$webrtc/share/webrtc"


cp -v "$out_dir/obj/libwebrtc.a"                    "$webrtc/lib"
cp -v "$out_dir/obj/libwebrtc.a"                    "$webrtc/debug/lib"
cp -v "$source_dir/test/gmock.h"                    "$webrtc/include/webrtc/test/"
cp -v "$source_dir/LICENSE"                         "$webrtc/share/webrtc/copyright"

copy_headers_rec "$source_dir/third_party/abseil-cpp"                        "absl"              "$include/"
copy_headers_rec "$source_dir"                                               "api"               "$include/"
copy_headers_rec "$source_dir"                                               "common_audio"      "$include/"
copy_headers_rec "$source_dir/third_party/googletest/src/googlemock/include" "gmock"             "$include/"
copy_headers_rec "$source_dir/third_party/googletest/src/googletest/include" "gtest"             "$include/"
copy_headers_rec "$source_dir/modules"                                       "audio_processing"  "$include/modules/"
copy_headers_rec "$source_dir"                                               "rtc_base"          "$include/"
copy_headers_rec "$source_dir"                                               "system_wrappers"   "$include/"


echo "*** Generated in $temp_root"
cd "$temp_root"
timestamp=`repo_date "$source_dir"`
destfile="$archive_dir/webrtc-${timestamp}-${archive_name}-linux.tar.xz"

echo "Compressing..."
export XZ_OPT=-T0
tar -c --xz -f "$destfile" "webrtc"
echo "Archive written to: $destfile"

sha512sum "$destfile"
rm -rf "$temp_root"


#copy_headers_rec 
#cp -v  $source_dir/modules/audio_processing/*.h     "$webrtc/include/webrtc/modules/"
#cp -v  $source_dir/rtc_base/*.h                     "$webrtc/include/webrtc/rtc_base/"
#cp -v  $source_dir/rtc_base/numerics/*.h            "$webrtc/include/webrtc/rtc_base/numerics"






