#/bin/sh

# MoltenVK has a long build dependencies step with no output. So we finish the build script here, which is inside a
# travis_wait invocation. Because travis_wait is not imported into subscripts we have to invoke it from the main script.
cmake --build . --target moltenvk-install --config Release
cmake --install . --config Release

