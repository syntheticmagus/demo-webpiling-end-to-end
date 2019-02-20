#!/bin/bash

# PREREQUISITES:
# This script is intended to be run in a Linux environment, and it depends on the availability of Git 
# and CMake (minimum version 2.8.7).  Linux/Unix-based developers should make sure that their environments 
# have these features available; Windows-based developers can just install the Windows Subsystem for Linux, 
# (https://docs.microsoft.com/en-us/windows/wsl/install-win10) as that environment should provide everything 
# necessary by default.

# Acquire variables for commonly-used paths.
# Copied from https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SUBMODULES="$DIR/submodules"

# These next two lines just sync down our Git submodules (https://git-scm.com/book/en/v2/Git-Tools-Submodules).  
# This project uses three submodules: Emscripten, OpenCV, and my own webpiling encapsulation code
# (https://github.com/syntheticmagus/webpiled-aruco-ar).
cd $DIR
git submodule update --init --recursive

# This next code block sets up the Emscripten repository created by the Git submodule.  Emscripten is a set 
# of open-source tools for compiling native code (C and C++) to asm.js and WebAssembly.  This is a phenomenal 
# utility, and its high quality is a huge part of the reason why webpiling is easy and feasible.  This part 
# of the script just ensures that all the Emscripten tools are properly set up and up-to-date.
cd $SUBMODULES/emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh

# This code block configures and builds OpenCV to static libraries.  More accurately, line 42 configures the 
# OpenCV build, and line 43 actually builds it; lines 36 through 41 are just setting up the folder structure.  
# Line 42 contains a very specific set of build instructions for OpenCV’s CMake-based build system.  Line 43 
# is much simpler.  The output of the CMake configuration command is a Makefile containing a number of possible 
# build targets, so this command simply tells Emscripten (via emmake) which subset of projects we’re actually 
# interested in: opencv_aruco.
cd $DIR
rm -rf build
mkdir build
cd build
mkdir opencv
cd opencv
cmake -D OPENCV_EXTRA_MODULES_PATH=$SUBMODULES/opencv_contrib/modules/ -D CMAKE_TOOLCHAIN_FILE=$EMSCRIPTEN/cmake/Modules/Platform/Emscripten.cmake -D BUILD_SHARED_LIBS=OFF -D CMAKE_BUILD_TYPE=Release -D EMSCRIPTEN_GENERATE_BITCODE_STATIC_LIBRARIES=ON -D ENABLE_SSE=OFF -D ENABLE_SSE2=OFF -D ENABLE_SSE3=OFF -D WITH_PTHREADS_PF=OFF -D WITH_IPP=OFF -D WITH_JPEG=OFF -D WITH_JASPER=OFF -D WITH_WEBP=OFF -D WITH_OPENEXR=OFF -D WITH_OPENCL=OFF -D WITH_TIFF=OFF -G "Unix Makefiles" $SUBMODULES/opencv/
emmake make opencv_aruco

# These next lines are just copying header files from the OpenCV source to the locations where the webpiling 
# encapsulation code expects them to be.  This is just to allow the encapsulating code to actually us the 
# headers you just built from instead of the ones it already has, even though they should already be the same.  
# Really, this step is just for completeness’s sake.
# Note that there are a variety of things I could have done instead of this to get a build working, but 
# I want the encapsulation repository to be as self-contained as possible.  Creating this sort of self-contained
# "include" folder mimics what you'd get from a distributable, like an install or NuGet package.
rm -rf $SUBMODULES/webpiled-aruco-ar/extern/include/opencv
rm -rf $SUBMODULES/webpiled-aruco-ar/extern/include/opencv2
rsync -a $SUBMODULES/opencv/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rm -f $SUBMODULES/webpiled-aruco-ar/extern/include/CMakeLists.txt
rsync -a $SUBMODULES/opencv_contrib/modules/aruco/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/calib3d/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/core/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/features2d/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/flann/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/highgui/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/imgcodecs/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/imgproc/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/ml/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
rsync -a $SUBMODULES/opencv/modules/videoio/include/ $SUBMODULES/webpiled-aruco-ar/extern/include/
# Hand-crafted opencv_modules.hpp file.  This was the only OpenCV-related file I edited by hand in order to 
# webpile marker tracking for Babylon.  This step should not be necessary, and I suspect that if I spend a bit 
# more time understanding OpenCV’s build system, I’d be able to get it to do this for me.  Unfortunately I 
# haven’t had time to revisit this yet, so this suboptimal workaround remains.   The file isn’t very complicated 
# (it just tells the other OpenCV header files which modules are available) so even though this isn’t ideal, 
# it’s workable.
cd $SUBMODULES/webpiled-aruco-ar/extern/include/opencv2
cat << EOF >> opencv_modules.hpp
#define HAVE_OPENCV_ARUCO
#define HAVE_OPENCV_CALIB3D
#define HAVE_OPENCV_CORE
#define HAVE_OPENCV_FEATURES2D
#define HAVE_OPENCV_FLANN
#define HAVE_OPENCV_HIGHGUI
#define HAVE_OPENCV_IMGCODECS
#define HAVE_OPENCV_IMGPROC
#define HAVE_OPENCV_ML
#define HAVE_OPENCV_VIDEOIO
EOF

# These lines copy more files around, but this time we're moving the static libraries built with Emscripten
# above.  Emscripten is built on LLVM technologies (http://llvm.org/), so its static libraries (the .bc files)
# are built into the LLVM’s “intermediate representation.”  This is a fascinating piece of technology, but 
# unfortunately it’s well outside the scope of this overview.  If you’d like to learn more about this (the 
# choice to use static libraries, Emscripten and LLVM, etc.) the projects have great information on their 
# official sites; or if you prefer, come join the conversation on the Babylon.js forums!
rm -f $SUBMODULES/webpiled-aruco-ar/extern/lib/*.bc
rsync -a $DIR/build/opencv/lib/ $SUBMODULES/webpiled-aruco-ar/extern/lib/
rsync -a $DIR/build/opencv/3rdparty/lib/ $SUBMODULES/webpiled-aruco-ar/extern/lib/

# Now we finally run the scripts that build the encapsulating code and produce the final WebAssembly.  The 
# encapsulating code is a simple native wrapper that reduces the ArUco API to a small subset that’s designed to
# be easy to use from JavaScript, even without any knowledge of OpenCV or computer vision.  The actual command
# to build the final WebAssembly can be found in the submodule’s build.sh script; run.sh correspondingly
# contains a command to host the resulting module in a test server helpfully provided by Emscripten, allowing
# you to try out your newly-webpiled utility by visiting localhost:8080 in a browser.  These commands derive
# from things I learned from the Emscripten compiler documentation (https://emscripten.org/docs/compiling/index.html).
cd $SUBMODULES/webpiled-aruco-ar
./build.sh

# Host your WASM; visit http://localhost:8080 in your browser to see your webpiled code in action!
./run.sh