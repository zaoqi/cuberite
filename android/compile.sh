#!/bin/bash

set -e

# This script cross-compiles cuberite for the android platform. It uses
# the following enviroment variables
#   CMAKE: Should be the path to a cmake executable of version 3.7+
#   NDK: Should be the path to the android ndk root
#   (optional) TYPE: either Release or Debug, sets the build type
#   (optional) THREADS: The number of threads to use, default 4

function usage() {
	echo "Usage: NDK=<path-to-ndk> CMAKE=<cmake-binary> $0 (clean|<ABI>)";
	exit 1
}

BASEDIR="$(realpath $(dirname $0))"
SELF="./$(basename $0)"

# Clean doesn't need CMAKE and NDK, so it's handled here
if [ "$1" == "clean" ]; then
	cd $BASEDIR
	rm -rf ../android-build/
	exit 0
fi

if [ -z "$CMAKE" -o -z "$NDK" ];then
	usage;
fi

# CMake wants absolute path
CMAKE="$(realpath $CMAKE)"
NDK="$(realpath $NDK)"

if [ -z "$TYPE" ]; then
	TYPE="Release"
fi

if [ -z "$THREADS" ]; then
	THREADS="4"
fi

cd $BASEDIR

case "$1" in

	armeabi-v7a)
		APILEVEL=29
	;;

	arm64-v8a)
		APILEVEL=29
	;;

	x86)
		APILEVEL=29
	;;

	x86_64)
		APILEVEL=29
	;;

	all)
		echo "Packing server.zip ..."
		mkdir -p Server
		cd $BASEDIR/../Server
		zip -r $BASEDIR/Server/server.zip *

		for arch in armeabi-v7a arm64-v8a x86 x86_64; do
			echo "Doing ... $arch ..." && \
			cd $BASEDIR && \
			"$SELF" clean && \
			"$SELF" "$arch" && \
			cd Server && \
			zip "$arch".zip Cuberite && \
			rm Cuberite
		done

		cd $BASEDIR/Server
		for file in server.zip armeabi-v7a.zip arm64-v8a.zip x86.zip x86_64.zip; do
			echo "Generating sha1 sum for ... $file ..." && \
			sha1sum "$file" > "$file".sha1
		done

		echo "Done! The built zip files await you in the Server/ directory"
		exit;
	;;

	*)
		usage;
	;;
esac

mkdir -p $BASEDIR/../android-build
cd $BASEDIR/../android-build
"$CMAKE" $BASEDIR/../android -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$1" \
    -DANDROID_NATIVE_API_LEVEL="$APILEVEL" \
    -DCMAKE_BUILD_TYPE="$TYPE"

make -j "$THREADS"
