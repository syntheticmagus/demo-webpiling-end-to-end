#!/bin/bash

# Copied from https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
SUBMODULES="$DIR/submodules"


git submodule update --init --recursive

cd submodules/emsdk
source ./emsdk_env.sh

cd ../..

rm -rf build
mkdir build
cd build

mkdir opencv
cd opencv

cmake -D OPENCV_EXTRA_MODULES_PATH=$SUBMODULES/opencv_contrib/modules/ -D CMAKE_TOOLCHAIN_FILE=$SUBMODULES/emsdk/emscripten/1.38.24/cmake/Modules/Platform/Emscripten.cmake -D BUILD_SHARED_LIBS=OFF -D CMAKE_BUILD_TYPE=Release -D EMSCRIPTEN_GENERATE_BITCODE_STATIC_LIBRARIES=ON -D ENABLE_SSE=OFF -D ENABLE_SSE2=OFF -D ENABLE_SSE3=OFF -D WITH_PTHREADS_PF=OFF -D WITH_IPP=OFF -D WITH_JPEG=OFF -D WITH_JASPER=OFF -D WITH_WEBP=OFF -D WITH_OPENEXR=OFF -D WITH_OPENCL=OFF -D WITH_TIFF=OFF -G "Unix Makefiles" $SUBMODULES/opencv/