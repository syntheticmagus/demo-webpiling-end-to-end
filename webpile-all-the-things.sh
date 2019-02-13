#!/bin/bash

# Acquire variables for commonly-used paths.
# Copied from https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SUBMODULES="$DIR/submodules"

cd $DIR
git submodule update --init --recursive

# Fetch the latest Emscripten and set environment variables.
cd $SUBMODULES/emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh

# Configure and build OpenCV static libraries.
cd $DIR
rm -rf build
mkdir build
cd build
mkdir opencv
cd opencv
cmake -D OPENCV_EXTRA_MODULES_PATH=$SUBMODULES/opencv_contrib/modules/ -D CMAKE_TOOLCHAIN_FILE=$EMSCRIPTEN/cmake/Modules/Platform/Emscripten.cmake -D BUILD_SHARED_LIBS=OFF -D CMAKE_BUILD_TYPE=Release -D EMSCRIPTEN_GENERATE_BITCODE_STATIC_LIBRARIES=ON -D ENABLE_SSE=OFF -D ENABLE_SSE2=OFF -D ENABLE_SSE3=OFF -D WITH_PTHREADS_PF=OFF -D WITH_IPP=OFF -D WITH_JPEG=OFF -D WITH_JASPER=OFF -D WITH_WEBP=OFF -D WITH_OPENEXR=OFF -D WITH_OPENCL=OFF -D WITH_TIFF=OFF -G "Unix Makefiles" $SUBMODULES/opencv/
emmake make open
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

rm -f $SUBMODULES/webpiled-aruco-ar/extern/lib/*.bc
rsync -a $DIR/build/opencv/lib/ $SUBMODULES/webpiled-aruco-ar/extern/lib/
rsync -a $DIR/build/opencv/3rdparty/lib/ $SUBMODULES/webpiled-aruco-ar/extern/lib/

cd $SUBMODULES/webpiled-aruco-ar
rm -rf build
./build.sh

./run.sh