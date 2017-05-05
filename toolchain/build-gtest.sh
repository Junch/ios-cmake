#!/bin/bash

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
    tar xvf ${GTEST_RELEASE_DIRNAME}.tar.gz
    mv "${GTEST_RELEASE_DIRNAME}" "${GTEST_SRC_DIR}"
    #rm ${GTEST_RELEASE_DIRNAME}.tar.gz
)

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# i386 for iOS Simulator"
echo "###################################################################"
echo "$(tput sgr0)"

(
    mkdir ${GTEST_SRC_DIR}/_build > /dev/null
    pushd ${GTEST_SRC_DIR}/_build > /dev/null
    cmake .. -DCMAKE_TOOLCHAIN_FILE="${PREFIX}/../ios.cmake" -DIOS_PLATFORM=SIMULATOR
    make
    outDir=${PREFIX}/platform/i386-sim
    mkdir -p ${outDir}
    cp -R googlemock/libgmock*.a ${outDir}
    cp -R googlemock/gtest/libgtest*.a ${outDir}
    popd > /dev/null
)

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# x86_64 for iOS Simulator"
echo "###################################################################"
echo "$(tput sgr0)"

(
    mkdir ${GTEST_SRC_DIR}/_build64 > /dev/null
    pushd ${GTEST_SRC_DIR}/_build64 > /dev/null
    cmake .. -DCMAKE_TOOLCHAIN_FILE="${PREFIX}/../ios.cmake" -DIOS_PLATFORM=SIMULATOR64
    make
    outDir=${PREFIX}/platform/x86_64-sim
    mkdir -p ${outDir}
    cp -R googlemock/libgmock*.a ${outDir}
    cp -R googlemock/gtest/libgtest*.a ${outDir}
    popd > /dev/null
)

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# arm* for iOS"
echo "###################################################################"
echo "$(tput sgr0)"

(
    mkdir ${GTEST_SRC_DIR}/_buildos > /dev/null
    pushd ${GTEST_SRC_DIR}/_buildos > /dev/null
    cmake .. -DCMAKE_TOOLCHAIN_FILE="${PREFIX}/../ios.cmake" -DIOS_PLATFORM=OS
    make
    outDir=${PREFIX}/platform/arm-ios
    mkdir -p ${outDir}
    cp -R googlemock/libgmock*.a ${outDir}
    cp -R googlemock/gtest/libgtest*.a ${outDir}
    popd > /dev/null
)

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Create Universal Libraries and Finalize the packaging"
echo "###################################################################"
echo "$(tput sgr0)"

(
    cd ${PREFIX}/platform
    mkdir universal

    lipo -create i386-sim/libgtest.a x86_64-sim/libgtest.a arm-ios/libgtest.a -output universal/libgtest.a
    lipo -create i386-sim/libgtest_main.a x86_64-sim/libgtest_main.a arm-ios/libgtest_main.a -output universal/libgtest_main.a
    lipo -create i386-sim/libgmock.a x86_64-sim/libgmock.a arm-ios/libgmock.a -output universal/libgmock.a
    lipo -create i386-sim/libgmock_main.a x86_64-sim/libgmock_main.a arm-ios/libgmock_main.a -output universal/libgmock_main.a
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

