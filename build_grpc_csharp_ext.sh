#! /bin/bash

# see also grani/grpc
current_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

if [ -z $2 ]; then
  echo "usage: build_grpc_cshap_ext.sh output_dir build_type(debug or release)"
  exit 1
fi

arg1=$1
arg2=$2

target_all=1
arch_all=1

for OPT in "$@"
do
  case "$OPT" in
    '-h'|'-help'|'--help' )
      echo "usage: build_grpc_cshap_ext.sh output_dir build_type(debug or release)"
      exit 1
      ;;
    '-o'|'-out'|'--out' )
      if [ -z "$2" ] || [[ "$2" =~ ^-+ ]]; then
        echo "invalid arg: $1 output_dir" 1>&2
        exit 1
      fi
      arg_out="$2"
      shift 1
      ;;
    '-c'|'-config'|'--config' )
      arg_val=$(echo "$2" | tr '[:upper:]' '[:lower:]')
      if [ "$arg_val" = "release" ]; then
        :
      elif [ "$arg_val" = "debug" ]; then
        :
      else
          echo "invalid arg: $1 release/debug" 1>&2
          exit 1
      fi
      arg_config="$arg_val"
      shift 1
      ;;
    '-t'|'-target'|'--target' )
      arg_val=$(echo "$2" | tr '[:upper:]' '[:lower:]')
      if [ "$arg_val" = "android" ]; then
        target_android=1
        target_all=0
      elif [ "$arg_val" = "ios" ]; then
        target_ios=1
        target_all=0
      else
        echo "invalid arg: $1 android/ios" 1>&2
        exit 1
      fi
      shift 1
      ;;
    '-a'|'-arch'|'--arch' )
      arg_val=$(echo "$2" | tr '[:upper:]' '[:lower:]')
      if [ "$arg_val" = "arm" ]; then
        arch_arm=1
        arch_all=0
      elif [ "$arg_val" = "x86" ]; then
        arch_x86=1
        arch_all=0
      else
        echo "invalid arg: $1 arm/x86" 1>&2
        exit 1
      fi
      shift 1
      ;;
    '-pod_update'|'--pod_update' )
      use_pod_update=1
      shift 1
      ;;
    * )
      shift 1
      ;;
  esac
done

if [ -z $arg_out ] || [ -z $arg_config ]; then
  if [ -z $arg_out ] && [ -z $arg_config ]; then
    arg_out="$arg1"
    arg_config="$arg2"
  else
    echo "usage: build_grpc_cshap_ext.sh output_dir build_type(debug or release)"
    exit 1
  fi
fi

echo "building ios_grpc_ext..."
echo "  output: $arg_out"
echo "  config: $arg_config"

if [ "$target_all" = "1" ]; then
  echo "  target: all"
elif [ "$target_android" = "1" ] && [ "$target_ios" = "1" ]; then
  echo "  target: android/ios"
elif [ "$target_android" = "1" ]; then
  echo "  target: android"
elif [ "$target_ios" = "1" ]; then
  echo "  target: ios"
fi

if [ "$arch_all" = "1" ]; then
  echo "  arch: all"
elif [ "$arch_arm" = "1" ] && [ "$arch_x86" = "1" ]; then
  echo "  arch: arm/x86"
elif [ "$arch_arm" = "1" ]; then
  echo "  arch: arm"
elif [ "$arch_x86" = "1" ]; then
  echo "  arch: x86"
fi

if [ "$use_pod_update" = "1" ]; then
  echo "  use: pod update"
fi

mkdir -p "$arg_out"
OUTPUT_DIR=$(cd $arg_out && pwd)
BUILD_TYPE=$arg_config

# iOS
if [ "$target_all" = "1" ] || [ "$target_ios" = "1" ]; then

  cd "$current_dir/xcodeproj/ios_grpc_ext"

  if [ "$use_pod_update" = "1" ]; then
    pod update
  else
    pod install
  fi

  # iOS arm
  if [ "$arch_all" = "1" ] || [ "$arch_arm" = "1" ]; then
    target=arm
    work_dir="build_$target"
    rm -dfr "$work_dir"
    mkdir -p "$work_dir"

    xcodebuild -workspace ios_grpc_ext.xcworkspace -scheme ios_grpc_ext -configuration $BUILD_TYPE -derivedDataPath "$work_dir" clean build

    output="$OUTPUT_DIR/iOS/$target"
    rm -dfr "$output"
    mkdir -p "$output"
    cp "./$work_dir/Build/Products/Release-iphoneos/libgrpc_csharp_ext.a" "$output/"
    cp "./$work_dir/Build/Products/Release-iphoneos/gRPC-Core/libgRPC-Core.a" "$output/"
    cp "./$work_dir/Build/Products/Release-iphoneos/BoringSSL/libBoringSSL.a" "$output/"
  fi  # arm

  # iOS simulator
  if [ "$arch_all" = "1" ] || [ "$arch_x86" = "1" ]; then
    target=simulator
    work_dir="build_$target"

    cd "$current_dir/xcodeproj/ios_grpc_ext"
    rm -dfr "$work_dir"
    mkdir -p "$work_dir"

    xcodebuild -workspace ios_grpc_ext.xcworkspace -sdk iphonesimulator -scheme ios_grpc_ext -configuration $BUILD_TYPE -arch i386 -arch x86_64 VALID_ARCHS="i386 x86_64" ONLY_ACTIVE_ARCH=NO -derivedDataPath "$work_dir" clean build

    output="$OUTPUT_DIR/iOS/$target"
    rm -dfr "$output"
    mkdir -p "$output"
    cp "./$work_dir/Build/Products/Release-iphonesimulator/libgrpc_csharp_ext.a" "$output/" 2>/dev/null || :
    cp "./$work_dir/Build/Products/Release-iphonesimulator/gRPC-Core/libgRPC-Core.a" "$output/" 2>/dev/null || :
    cp "./$work_dir/Build/Products/Release-iphonesimulator/BoringSSL/libBoringSSL.a" "$output/" 2>/dev/null || :
    cp "./$work_dir/Build/Products/Release-iphoneos/libgrpc_csharp_ext.a" "$output/" 2>/dev/null || :
    cp "./$work_dir/Build/Products/Release-iphoneos/gRPC-Core/libgRPC-Core.a" "$output/" 2>/dev/null || :
    cp "./$work_dir/Build/Products/Release-iphoneos/BoringSSL/libBoringSSL.a" "$output/" 2>/dev/null || :
  fi  # x86

fi  # ios
