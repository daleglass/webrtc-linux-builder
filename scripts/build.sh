#!/bin/bash
set -e

build_type="$1"
root=/webrtc-build


help() {
	cat <<HELP
Syntax: $0 <options>

Options:
	--all     Build everything
	--clang   Build for clang
	--gcc     Build for gcc
	--update  Update tree before building

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
			shift
			;;
		--update)
			do_update=1
			shift
			;;
		*)
			help
			;;
	esac
done




action_done=

msg "Resetting tree"
cd "$root/src"      && git reset --hard
cd "$root/src/base" && git reset --hard



cd "$root/src"

msg "Applying patches"
for patch in $root/patches/* ; do
	patch -p1 < $patch
done


if [ -n "$do_update" ] ; then
	msg "Updating tree"
	gclient sync
	action_done=1
fi


if [ -n "$build_clang" ] ; then
	msg "Building for clang"
	gn gen out/Debug-clang
	ninja -C out/Debug-clang
	action_done=1
fi

if [ -n "$build_gcc" ] ; then
	msg "Building for gcc"
	gn gen out/Debug-gcc --args="use_custom_libcxx=false use_custom_libcxx_for_host=false"
	ninja -C out/Debug-gcc obj/libwebrtc.a
	action_done=1
fi

if [ -z "$action_done" ] ; then
	help
fi



