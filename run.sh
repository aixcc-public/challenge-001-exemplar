#!/bin/bash

print_usage() {
    echo "run.sh - A helper script for all docker interactions."
    echo ""
    echo "Usage: run.sh [arguments] pull_source                         pull the source code fresh to the src/ directory; will overwrite existing source"
    echo "   or: run.sh [arguments] build [patch_file]                  build with optional patch file"
    echo "   or: run.sh [arguments] run_pov <blob_file> <harness_id>    run data binary blob against harness"
    echo "   or: run.sh [arguments] run_tests                           run functionality tests"
    echo ""
    echo "Arguments:"
    echo "  -v                Verbose"
}

CP_SOURCE_REMOTE="https://github.com/aixcc-public/challenge-001-exemplar-source.git"
CP_IMG_ADDRESS="n/a"
CP_NAME="exemplar-cp-linux"
CP_BASE_TAG="base"
CP_MOD_TAG="latest"
VERBOSE=NO
POS_ARGS=()

WORKDIR=${PWD}/work/
SRC=${PWD}/src/
OUT=${PWD}/out/

CC=${CC:=gcc}
CXX=${CXX:=g++}
CCC=${CCC:=g++}
CFLAGS=${CFLAGS:=}
CXXFLAGS=${CXXFLAGS:=}
LIB_FUZZING_ENGINE=${LIB_FUZZING_ENGINE:=}
KERNEL_MAKE_CMD=${KERNEL_MAKE_CMD:=make -j\$(nproc)}

## create workdir if needed
mkdir -p $WORKDIR

## sift through arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v)
            VERBOSE=YES
            shift
            ;;
        -*|--*)
            echo "Unknown option $1"
            print_usage
            exit 1
            ;;
        *)
            POS_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ $VERBOSE = "YES" ]; then
    echo "Environment Vars:"
    echo " \$CC  = $CC"
    echo " \$CXX = $CXX"
    echo " \$CCC = $CCC"
    echo " \$CFLAGS = $CFLAGS"
    echo " \$CXXFLAGS = $CXXFLAGS"
    echo " \$LIB_FUZZING_ENGINE = $LIB_FUZZING_ENGINE"
    echo " \$KERNEL_MAKE_CMD = $KERNEL_MAKE_CMD"
fi

set -- "${POS_ARGS[@]}" # restore pos args

## execute commands
CMD_NAME=$1
shift
case ${CMD_NAME,,} in
    "pull_source")

        # Remove source contents if they already exist
        rm -rf $SRC
        git clone $CP_SOURCE_REMOTE $SRC

        ;;
    "build")

        # Check for base docker image
        docker inspect $CP_NAME:$CP_BASE_TAG &> /dev/null \
            || { echo "Must build base docker image before building source, please read README" ; exit 1; }

        # Build docker image that may or may not include modifications
        docker build . -t $CP_NAME:$CP_MOD_TAG \
            || { echo "Failed to build docker image $CP_MOD_TAG, check Dockerfile modifications" ; exit 1; }

        SH_CMD=""

        if [ ! -z "$1" ]; then
            PATCH_FILE=$1
            cp $PATCH_FILE $WORKDIR/tmp_patchfile
            SH_CMD+="git apply /work/tmp_patchfile && "
        fi

        SH_CMD+="build.sh"
        docker run --rm --device=/dev/kvm --tmpfs /dev/shm:exec \
            -u $(id -u $USER):$(id -g $USER) \
            -w /src/ \
            -v $WORKDIR:/work/ \
            -v $SRC:/src/ \
            -v $OUT:/out/ \
            -e CC=$CC \
            -e CXX=$CXX \
            -e CCC=$CCC \
            -e CFLAGS=$CFLAGS \
            -e CXXFLAGS=$CXXFLAGS \
            -e LIB_FUZZING_ENGINE=$LIB_FUZZING_ENGINE \
            -e "KERNEL_MAKE_CMD=$KERNEL_MAKE_CMD" \
            $CP_NAME:$CP_MOD_TAG sh -c "$SH_CMD"

        if [ ! -z "$1" ]; then
            rm $WORKDIR/tmp_patchfile
        fi

        ;;
    "run_pov")

        # Check if dev tag has been built, build or fail if not
        docker inspect $CP_NAME:$CP_MOD_TAG &> /dev/null \
            || { echo "No image found; must run 'build' command before 'run_pov'" ; exit 1; }

        BLOB_FILE=$1
        HARNESS_ID=$2
        cp $BLOB_FILE $WORKDIR/tmp_blob \
            || { echo "No blob file found!" ; exit 1; }

        docker run --rm --device=/dev/kvm --tmpfs /dev/shm:exec \
            -w /usr/local/sbin/ \
            -v $WORKDIR:/work/ \
            -v $SRC:/src/ \
            -v $OUT:/out/ \
            -e CC=$CC \
            -e CXX=$CXX \
            -e CCC=$CCC \
            -e CFLAGS=$CFLAGS \
            -e CXXFLAGS=$CXXFLAGS \
            -e LIB_FUZZING_ENGINE=$LIB_FUZZING_ENGINE \
            $CP_NAME:$CP_MOD_TAG ./run_internal.sh pov /work/tmp_blob /out/$HARNESS_ID

        rm $WORKDIR/tmp_blob
        ;;
    "run_tests")

        docker inspect $CP_NAME:$CP_MOD_TAG &> /dev/null \
            || { echo "No image found; must run 'build' command before 'run_tests'" ; exit 1; }

        docker run --rm --device=/dev/kvm --tmpfs /dev/shm:exec \
            -w /usr/local/sbin/ \
            -v $WORKDIR:/work/ \
            -v $SRC:/src/ \
            -v $OUT:/out/ \
            -e CC=$CC \
            -e CXX=$CXX \
            -e CCC=$CCC \
            -e CFLAGS=$CFLAGS \
            -e CXXFLAGS=$CXXFLAGS \
            -e LIB_FUZZING_ENGINE=$LIB_FUZZING_ENGINE \
            $CP_NAME:$CP_MOD_TAG ./run_internal.sh run_tests
        ;;
    *)
        echo "Invalid command $CMD_NAME"
        print_usage
        exit 1
        ;;
esac


