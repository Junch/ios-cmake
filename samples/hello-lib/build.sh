mkdir _build > /dev/null
pushd _build > /dev/null
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../../toolchain/ios.cmake -DIOS_PLATFORM=SIMULATOR64
make install
popd > /dev/null

mkdir _buildos > /dev/null
pushd _buildos > /dev/null
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../../toolchain/ios.cmake -DIOS_PLATFORM=OS
make install
popd > /dev/null

lipo -create ./_build/libhello-lib.a ./_buildos/libhello-lib.a -output ../hello-app/hello-app/libhello-lib.a
lipo -info ../hello-app/hello-app/libhello-lib.a
