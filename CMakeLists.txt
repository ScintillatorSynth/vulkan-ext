# Standalone cmake project to build and install Vulkan build time dependencies.
include(ExternalProject)
cmake_policy(SET CMP0048 NEW)
cmake_minimum_required(VERSION 3.9)
set(CMAKE_BUILD_TYPE "Release")

project(vulkan-dev VERSION 0.0.1)

set(INSTALL_EXT_DIR "${PROJECT_BINARY_DIR}/install-ext" CACHE PATH "")
file(MAKE_DIRECTORY "${INSTALL_EXT_DIR}")
file(MAKE_DIRECTORY "${INSTALL_EXT_DIR}/lib")

set(SCIN_VULKAN_TAG "v1.2.132")
message(STATUS "Building Vulkan SDK at version ${SCIN_VULKAN_TAG}")

ExternalProject_Add(vulkan-headers
    PREFIX ext
    STEP_TARGETS install
    GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
    GIT_TAG ${SCIN_VULKAN_TAG}
    GIT_PROGRESS ON
    UPDATE_COMMAND ""
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${INSTALL_EXT_DIR} -DCMAKE_BUILD_TYPE=Release
)

ExternalProject_Add(vulkan-loader
    PREFIX ext
    STEP_TARGETS install
    DEPENDS vulkan-headers-install
    GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Loader.git
    GIT_TAG ${SCIN_VULKAN_TAG}
    GIT_PROGRESS ON
    UPDATE_COMMAND ""
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${INSTALL_EXT_DIR} -DVULKAN_HEADERS_INSTALL_DIR=${INSTALL_EXT_DIR} -DBUILD_LOADER=ON -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
)

if (APPLE)
    set(SCIN_SHADERC_SHARED_CRT "")
    set(SCIN_SHADERC_GENERATOR "Ninja")
elseif(UNIX)
    set(SCIN_SHADERC_SHARED_CRT "")
    set(SCIN_SHADERC_GENERATOR "Ninja")
elseif(WIN32)
    set(SCIN_SHADERC_SHARED_CRT "-DSHADERC_ENABLE_SHARED_CRT=ON")
    set(SCIN_SHADERC_GENERATOR "")
endif()

# Requires Ninja to build correctly.
ExternalProject_Add(shaderc
    PREFIX ext
    STEP_TARGETS install
    GIT_REPOSITORY https://github.com/google/shaderc.git
    GIT_TAG v2019.1
    GIT_PROGRESS ON
    PATCH_COMMAND cd <SOURCE_DIR> && ${PYTHON_EXECUTABLE} utils/git-sync-deps
    UPDATE_COMMAND ""
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${INSTALL_EXT_DIR} -DSHADERC_SKIP_TESTS=ON -DCMAKE_BUILD_TYPE=Release ${SCIN_SHADERC_SHARED_CRT}
    CMAKE_GENERATOR ${SCIN_SHADERC_GENERATOR}
)

if (APPLE)
    set(SCIN_VVL_INSTALL cp <BINARY_DIR>/layers/libVkLayer_khronos_validation.dylib ${INSTALL_EXT_DIR}/lib/.)
    set(SCIN_VVL_GENERATOR "Unix Makefiles")
elseif(UNIX)
    set(SVIN_VVL_INSTALL cp <BINARY_DIR>/layers/libVkLayer_khronos_validation.so ${INSTALL_EXT_DIR}/lib/.)
    set(SCIN_VVL_GENERATOR "Unix Makefiles")
elseif(WIN32)
    set(SVIN_VVL_INSTALL cp <BINARY_DIR>/layers/libVkLayer_khronos_validation.dll ${INSTALL_EXT_DIR}/lib/.)
    # Leave generator as default (Visual Studio) for Windows
    set(SCIN_VVL_GENERATOR "")
endif()

# Doesn't seem to be a good way to hard-code build type for the validation layers, so it must be specified on the cmake
# command line as "Release", or build will fail to find the matching libs provided by shaderc.
ExternalProject_Add(vulkan-validationlayers
    PREFIX ext
    STEP_TARGETS install
    DEPENDS vulkan-headers-install shaderc-install
    GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-ValidationLayers.git
    GIT_TAG ${SCIN_VULKAN_TAG}
    GIT_PROGRESS ON
    UPDATE_COMMAND ""
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${INSTALL_EXT_DIR} -DVULKAN_HEADERS_INSTALL_DIR=${INSTALL_EXT_DIR} -DGLSLANG_INSTALL_DIR=${INSTALL_EXT_DIR} -DBUILD_TESTS=OFF
    INSTALL_COMMAND ${SCIN_VVL_INSTALL}
    CMAKE_GENERATOR ${SCIN_VVL_GENERATOR}
)

# Apple-only gets the Vulkan emulation library MoltenVK.
if (APPLE)
ExternalProject_Add(moltenvk
    PREFIX ext
    STEP_TARGETS install
    # We build this separately because it has a dependency build step that emits no output, so consistently times out
    # Travis CI.
    EXCLUDE_FROM_ALL ON
    GIT_REPOSITORY https://github.com/KhronosGroup/MoltenVK.git
    GIT_TAG v1.0.41
    GIT_PROGRESS ON
    PATCH_COMMAND cd <SOURCE_DIR> && ./fetchDependencies
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE ON
    BUILD_COMMAND xcodebuild -project MoltenVKPackaging.xcodeproj -scheme "MoltenVK Package (macOS only)" build
    INSTALL_COMMAND cp <SOURCE_DIR>/Package/Release/MoltenVK/macOS/dynamic/libMoltenVK.dylib ${INSTALL_EXT_DIR}/lib/.
)
endif()
