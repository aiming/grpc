#! /bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: build_grpc_c_core_library.sh BUILD_TYPE(debug or release)" 1>&2
    exit 1
fi

if [ $1 != 'debug' ] && [ $1 != 'release' ]; then
    echo "Usage: build_grpc_c_core_library.sh BUILD_TYPE(debug or release)" 1>&2
    exit 1
fi

BUILD_TYPE=$1

current_dir=$(cd $(dirname $0) && pwd)
work_dir="build"

#build library for iOS
cd "$current_dir/xcprojects/grpc_csharp_ext"

xcodebuild -workspace grpc_csharp_ext.xcworkspace \
           -scheme grpc_csharp_ext \
           -configuration $BUILD_TYPE \
           -derivedDataPath "$work_dir" \
           OTHER_CFLAGS="-fembed-bitcode" \
           clean build
