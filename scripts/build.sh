#!/bin/bash
set -e

root=/webrtc-build


help() {
	cat <<HELP
Syntax: $0 <options>

Options:
	--all        Build everything, both Debug and Release
	--clang      Build for clang
	--debug      Make a Debug build
	--gcc        Build for gcc
	--update     Update tree before building
	--no-patch   Don't patch or modify the source tree
	--release    Make a Release build
HELP
	exit 1
}

msg() {
	echo -ne "\033[0;36m"
	echo -ne "*** $1"
	echo -e  "\033[0m"

}


while [[ $# -gt 0 ]] ; do
	arg="$1"

	case $arg in
		--gcc)
			build_gcc=1
			shift
			;;
		--clang)
			build_clang=1
			shift
			;;
		--all)
			build_gcc=1
			build_clang=1
			build_debug=1
			build_release=1
			shift
			;;
		--update)
			do_update=1
			shift
			;;
		--no-patch)
			no_patch=1
			shift
			;;
		--debug)
			build_debug=1
			shift
			;;
		--release)
			build_release=1
			shift
			;;
		*)
			help
			;;
	esac
done


if [ -z "$build_debug" -a -z "$build_release" ] ; then
	build_release=1
fi

action_done=

if [ -z "$no_patch" ] ; then

	msg "Resetting tree"
	cd "$root/src"      && git reset --hard
	cd "$root/src/base" && git reset --hard



	cd "$root/src"

	msg "Applying patches"
	for patch in $root/patches/* ; do
		patch -p1 < $patch
	done
fi

cd "$root/src"


if [ -n "$do_update" ] ; then
	msg "Updating tree"
	gclient sync
	action_done=1
fi


if [ -n "$build_clang" ] ; then

	if [ -n "$build_debug" ] ; then
		msg "Building for clang: Debug"

		[ -d "out/Debug-clang" ] && rm -rf "out/Debug-clang"
		gn gen out/Debug-clang
		ninja -C out/Debug-clang
	fi

	if [ -n "$build_release" ] ; then
		msg "Building for clang: Release"

		[ -d "out/Release-clang" ] && rm -rf "out/Release-clang"
		gn gen out/Release-clang --args="is_debug=false"
		ninja -C out/Release-clang
	fi


	action_done=1
fi

if [ -n "$build_gcc" ] ; then
	msg "Building for gcc"
#	if [ -d "out/Debug-gcc" ]  ; then
#		msg "Cleaning up"
#		rm -rf "out/Debug-gcc"
#	fi
#	openssl_root=/webrtc-build/vcpkg-ms/packages/openssl_x64-linux/include/
	openssl_root=/usr/include/openssl
#i	cp -Rdp "$openssl_root/openssl" "$root/src/third_party/libsrtp/crypto/include/"
#	cp -Rdp "$openssl_root/openssl" "$root/src/third_party/usrsctp/usrsctplib/usrsctplib/"

	args="use_custom_libcxx=false use_custom_libcxx_for_host=false rtc_include_tests=false rtc_build_tools=false rtc_build_examples=false proprietary_codecs=true rtc_use_h264=true enable_libaom=false rtc_enable_protobuf=false rtc_build_ssl=false rtc_ssl_root=\"$openssl_root\""

	if [ -n "$build_debug" ] ; then
		msg "Building for gcc: Debug"

		[ -d "out/Debug-gcc" ] && rm -rf "out/Debug-gcc"

		gn gen out/Debug-gcc --args="$args"
		ninja -C out/Debug-gcc obj/libwebrtc.a
	fi

	if [ -n "$build_release" ] ; then
		msg "Building for gcc: Release"

		[ -d "out/Release-gcc" ] && rm -rf "out/Release-gcc"

		gn gen out/Release-gcc --args="$args is_debug=false"
		ninja -C out/Release-gcc obj/libwebrtc.a
	fi

#	gn gen out/Debug-gcc --args="use_custom_libcxx=false use_custom_libcxx_for_host=false is_nacl=true rtc_include_tests=false rtc_build_tools=false rtc_build_examples=false proprietary_codecs=true rtc_use_h264=true enable_libaom=false rtc_enable_protobuf=false rtc_build_ssl=false rtc_ssl_root=\"$openssl_root\""
#	ninja -C out/Debug-gcc obj/libwebrtc.a
	action_done=1
fi

if [ -z "$action_done" ] ; then
	help
fi



