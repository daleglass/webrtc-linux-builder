 # WebRTC build scripts

Dockerfile and script for building WebRTC for Linux for Vircadia


# Docker container

To provide a known good build environment, a Docker container's definition is provided. The container can be built with the `build_container.sh` script.

The resulting container will be fairly large as it will contain the required packages, Google tools, and a checkout of the source to speed up the generation of updated packages.

# Building WebRTC

The included scripts were made to be used inside the Docker container. Some work will be needed to use them outside of it.


## Using the scripts

For just getting an archive with the library, scripts are provided to automate the process.

### Building for Clang

    $ ./build.sh --clang


### Building for GCC

    $ ./build.sh --gcc


### Packaging

    $ ./package.sh --builddir /webrtc-build/src/out/Debug-clang/ --name clang --outdir /out
    $ ./package.sh --builddir /webrtc-build/src/out/Debug-gcc/ --name gcc --outdir /out

This will produce packages with names like `webrtc-20211009-clang-linux.tar.xz` and `webrtc-20211009-gcc-linux.tar.xz` in `out/`



## Building by hand

### Building for Vircadia built with LLVM

    gn gen out/Debug
    ninja -C out/Debug

This should produce a library without any problems, as it's the officially supported configuration. However, Vircadia builds on Linux using GCC by default, and the results of this build won't work with it. 

If you see something like this:

    /usr/bin/ld: ../../libraries/audio-client/libaudio-client.so: undefined reference to `std::__1::chrono::steady_clock::now()'
    /usr/bin/ld: ../../libraries/audio-client/libaudio-client.so: undefined reference to `std::__1::cerr'
    /usr/bin/ld: ../../libraries/audio-client/libaudio-client.so: undefined reference to `std::__1::locale::has_facet(std::__1::locale::id&) const'

Then that's exactly the problem. By default WebRTC is linked against Clang's libc++, while Vircadia links against libstdc++. Both don't like to mix.

### Building for Vircadia built with GCC

GCC and Clang use separate C++ standard libraries. Linking a library against one, and using it in a binary that uses the other doesn't work. By default on Linux Vircadia is built using GCC, so the clang build will fail as described above.

Here's how to build a libwebrtc linked against libstdc++:

    gn gen out/Debug-gcc --args="use_custom_libcxx=false use_custom_libcxx_for_host=false"
    ninja -C out/Debug-gcc obj/libwebrtc.a

We're intentionally only going as far as building the library itself, since some of the tests seem to run into some trouble compiling. Mostly the issues seem to be the code lacking a few #include lines. During my attempt I had to add `#include <memory>` to `./base/command_line.h`. Patches for this can be found in the `patches/` directory.

## Building with GCC

**Do not follow these instructions. They're a record of a previous attempt that was rejected in the end.**

**Building with GCC is possible, but not officially supported by google.**

As an alternative to the above, building with GCC seemed like a possible alternative. Since it's not officially supported, and the build process generates warnings, warnings as errors must be disabled.

So far only Ubuntu 20.10 has worked. Older versions have issues with GCC failing to compile some source files. This may be possible to fix by patching the code.

Since it's an unsupported configuration, a number of difficulties may happen.

    gn gen out/Debug-gcc --args="is_clang=false treat_warnings_as_errors=false"
    ninja -C out/Debug-gcc

