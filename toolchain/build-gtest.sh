#!/bin/bash

if ! type cmake > /dev/null; then
  echo "cmake is not installed. Please install it first."
  exit
fi

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Preparing to build Google Test for iOS"
echo "###################################################################"
echo "$(tput sgr0)"

# The results will be stored relative to the location
# where you stored this script, **not** relative to
# the location of the protobuf git repo.
PREFIX=`pwd`/googletest
if [ -d ${PREFIX} ]
then
    rm -rf "${PREFIX}"
fi
mkdir -p "${PREFIX}/platform"

GTEST_VERSION=1.8.0
GTEST_RELEASE_URL=https://github.com/google/googletest/archive/release-${GTEST_VERSION}.tar.gz
GTEST_RELEASE_DIRNAME=googletest-release-${GTEST_VERSION}
GTEST_SRC_DIR=/tmp/googletest

echo "PREFIX ..................... ${PREFIX}"
echo "GTEST_VERSION .............. ${GTEST_VERSION}"
echo "GTEST_RELEASE_URL .......... ${GTEST_RELEASE_URL}"
echo "GTEST_RELEASE_DIRNAME ...... ${GTEST_RELEASE_DIRNAME}"
echo "GTEST_SRC_DIR .............. ${GTEST_SRC_DIR}"

while true; do
    read -p "Proceed with build? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Fetch Google Test"
echo "###################################################################"
echo "$(tput sgr0)"

(
    if [ -d ${GTEST_SRC_DIR} ]
    then
        rm -rf ${GTEST_SRC_DIR}
    fi

    cd `dirname $GTEST_SRC_DIR}`

    if [ -d ${GTEST_RELEASE_DIRNAME} ]
    then
        rm -rf "${GTEST_RELEASE_DIRNAME}"
    fi
    curl --location ${GTEST_RELEASE_URL} --output ${GTEST_RELEASE_DIRNAME}.tar.gz
    tar xf ${GTEST_RELEASE_DIRNAME}.tar.gz
    mv "${GTEST_RELEASE_DIRNAME}" "${GTEST_SRC_DIR}"
    #rm ${GTEST_RELEASE_DIRNAME}.tar.gz
)

function build_lib()
{
    PLATFORM=$1
    FOLDER=$2
    DESC=$3

    echo "$(tput setaf 2)"
    echo "###################################################################"
    echo "# ${DESC}"
    echo "###################################################################"
    echo "$(tput sgr0)"

    (
        mkdir ${GTEST_SRC_DIR}/${FOLDER}> /dev/null
        pushd ${GTEST_SRC_DIR}/${FOLDER}> /dev/null
        cmake .. -DCMAKE_TOOLCHAIN_FILE="${PREFIX}/../ios.cmake" -DIOS_PLATFORM="${PLATFORM}"
        make
        outDir=${PREFIX}/platform/"${FOLDER}"
        mkdir -p ${outDir}
        cp -R googlemock/libgmock*.a ${outDir}
        cp -R googlemock/gtest/libgtest*.a ${outDir}
        popd > /dev/null
    )    
}

build_lib SIMULATOR   i386-sim    "i386 for iOS Simulator"
build_lib SIMULATOR64 x86_64-sim  "x86_64 for iOS Simulator"
build_lib OS          arm-ios     "armv7 armv7s x86_64 arm64 for iOS"

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Create Universal Libraries and Finalize the packaging"
echo "###################################################################"
echo "$(tput sgr0)"


function create_universal()
{
    MODULE=$1
    lipo -create i386-sim/"${MODULE}" x86_64-sim/"${MODULE}" arm-ios/"${MODULE}" -output universal/"${MODULE}"
}

(
    cd ${PREFIX}/platform
    mkdir universal

    arr=(libgtest.a libgtest_main.a libgmock.a libgmock_main.a)
    for i in "${arr[@]}"
    do
        create_universal $i
    done
)

(
    cd ${PREFIX}
    mkdir lib
    mkdir include
    cp -R platform/universal/* lib
    cp -R ${GTEST_SRC_DIR}/googlemock/include/* include
    cp -R ${GTEST_SRC_DIR}/googletest/include/* include
    rm -rf platform
    lipo -info lib/libgtest.a
    lipo -info lib/libgtest_main.a
    lipo -info lib/libgmock.a
    lipo -info lib/libgmock_main.a
)

echo Done!

