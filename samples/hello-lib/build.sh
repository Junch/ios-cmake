mkdir _build > /dev/null
pushd _build > /dev/null
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../../toolchain/ios.cmake -DIOS_PLATFORM=OS
make
make install
popd > /dev/null
