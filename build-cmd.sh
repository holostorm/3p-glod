#!/bin/sh

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# run build from root of checkout
cd "$(dirname "$0")"

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

top="$(pwd)"
STAGING_DIR="$(pwd)/stage"

GLOD_VERSION=1.0pre4
build=${AUTOBUILD_BUILD_ID:=0}
echo "${GLOD_VERSION}.${build}" > "${STAGING_DIR}/VERSION.txt"

case "$AUTOBUILD_PLATFORM" in
    "windows")
        if [ "${ND_AUTOBUILD_ARCH}" == "x64" ]
        then
          build_sln "glodlib.sln" "Debug|x64"
          build_sln "glodlib.sln" "Release|x64"
        else
          build_sln "glodlib.sln" "Debug|Win32"
          build_sln "glodlib.sln" "Release|Win32"
        fi

		mkdir -p stage/lib/{debug,release}
        cp "lib/debug/glod.lib" \
            "stage/lib/debug/glod.lib"
        cp "lib/debug/glod.dll" \
            "stage/lib/debug/glod.dll"
        cp "src/api/debug/glod.pdb" \
            "stage/lib/debug/glod.pdb"
        cp "lib/release/glod.lib" \
            "stage/lib/release/glod.lib"
        cp "lib/release/glod.dll" \
            "stage/lib/release/glod.dll"
    ;;
        "darwin")
			libdir="$top/stage/lib"
			export CFLAGS="-arch i386 -arch x86_64"
			export LFLAGS="-arch i386 -arch x86_64"
            mkdir -p "$libdir"/{debug,release}
			make -C src clean
			# "make clean" doesn't, apparently.
			find . -name \*.a -print0 | xargs -0 rm
			make -C src debug
			install_name_tool -id "@executable_path/../Resources/libGLOD.dylib" "lib/libGLOD.dylib" 
			cp "lib/libGLOD.dylib" \
				"$libdir/debug/libGLOD.dylib"
			make -C src clean
			# "make clean" doesn't, apparently.
			find . -name \*.a -print0 | xargs -0 rm
			make -C src release
			install_name_tool -id "@executable_path/../Resources/libGLOD.dylib" "lib/libGLOD.dylib" 
			cp "lib/libGLOD.dylib" \
				"$libdir/release/libGLOD.dylib"
		;;
        "linux")
			libdir="$top/stage/lib"
            mkdir -p "$libdir"/{debug,release}
			export CFLAGS=${ND_AUTOBUILD_GCC_ARCH_FLAG}
			export CXXFLAGS=${ND_AUTOBUILD_GCC_ARCH_FLAG}
			export LDFLAGS=${ND_AUTOBUILD_GCC_ARCH_FLAG}
			make -C src clean
			make -C src debug
			cp "lib/libGLOD.so" \
				"$libdir/debug/libGLOD.so"
			make -C src clean
			make -C src release
			cp "lib/libGLOD.so" \
				"$libdir/release/libGLOD.so"
        ;;
esac
mkdir -p "stage/include/glod"
cp "include/glod.h" "stage/include/glod/glod.h"
mkdir -p stage/LICENSES
cp LICENSE stage/LICENSES/GLOD.txt

pass

