cmake_minimum_required(VERSION 3.28)

project(merlion-node-exporter-cpp
    VERSION 0.1.0
    DESCRIPTION "Modern C++23 reimplementation of Prometheus node_exporter."
    HOMEPAGE_URL "https://github.com/MerlionOS/merlion-node-exporter-cpp"
    LANGUAGES CXX
)

# ---------------------------------------------------------------------------
# Project options
# ---------------------------------------------------------------------------
option(MNE_BUILD_TESTS  "Build Catch2 unit tests"   ON)
option(MNE_ENABLE_LTO   "Enable link-time optimisation in release builds" ON)
option(MNE_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ON)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

# ---------------------------------------------------------------------------
# Compiler sanity check
# ---------------------------------------------------------------------------
# Apple Clang's libc++ still lags on std::expected / std::format. Fail fast
# instead of silently producing a broken build.
if(APPLE AND CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    message(FATAL_ERROR
        "Apple Clang is not supported. Install Homebrew LLVM and re-configure:\n"
        "  brew install llvm\n"
        "  export CC=\"$(brew --prefix llvm)/bin/clang\"\n"
        "  export CXX=\"$(brew --prefix llvm)/bin/clang++\"\n"
        "Or pass -DCMAKE_TOOLCHAIN_FILE=cmake/ToolchainLLVM.cmake."
    )
endif()

# ---------------------------------------------------------------------------
# Warnings
# ---------------------------------------------------------------------------
add_library(mne_compile_flags INTERFACE)
target_compile_features(mne_compile_flags INTERFACE cxx_std_23)
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options(mne_compile_flags INTERFACE
        -Wall -Wextra -Wpedantic
        -Wshadow -Wconversion -Wsign-conversion
        -Wno-unused-parameter
    )
    if(MNE_WARNINGS_AS_ERRORS)
        target_compile_options(mne_compile_flags INTERFACE -Werror)
    endif()
endif()

# Release-only flags.
add_library(mne_release_flags INTERFACE)
target_compile_options(mne_release_flags INTERFACE
    $<$<CONFIG:Release,RelWithDebInfo>:-O3>
    $<$<CONFIG:Release,RelWithDebInfo>:-ffunction-sections>
    $<$<CONFIG:Release,RelWithDebInfo>:-fdata-sections>
)
if(UNIX AND NOT APPLE)
    target_link_options(mne_release_flags INTERFACE
        $<$<CONFIG:Release,RelWithDebInfo>:LINKER:--gc-sections>
    )
elseif(APPLE)
    target_link_options(mne_release_flags INTERFACE
        $<$<CONFIG:Release,RelWithDebInfo>:LINKER:-dead_strip>
    )
endif()

# LTO when supported.
if(MNE_ENABLE_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT _ipo_ok OUTPUT _ipo_msg)
    if(_ipo_ok)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO TRUE)
    else()
        message(STATUS "IPO/LTO not supported: ${_ipo_msg}")
    endif()
endif()

# ---------------------------------------------------------------------------
# Dependencies (FetchContent)
# ---------------------------------------------------------------------------
include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)

FetchContent_Declare(
    cpp-httplib
    GIT_REPOSITORY https://github.com/yhirose/cpp-httplib.git
    GIT_TAG        v0.18.5
    GIT_SHALLOW    TRUE
)
FetchContent_Declare(
    CLI11
    GIT_REPOSITORY https://github.com/CLIUtils/CLI11.git
    GIT_TAG        v2.4.2
    GIT_SHALLOW    TRUE
)
FetchContent_Declare(
    spdlog
    GIT_REPOSITORY https://github.com/gabime/spdlog.git
    GIT_TAG        v1.14.1
    GIT_SHALLOW    TRUE
)

set(HTTPLIB_COMPILE OFF CACHE BOOL "" FORCE)  # header-only
set(CLI11_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(CLI11_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_EXAMPLE OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_TESTS OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(cpp-httplib CLI11 spdlog)

# ---------------------------------------------------------------------------
# Generated version header
# ---------------------------------------------------------------------------
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/include/merlion_node_exporter/version.hpp.in
    ${CMAKE_CURRENT_BINARY_DIR}/generated/include/merlion_node_exporter/version.hpp
    @ONLY
)

# ---------------------------------------------------------------------------
# Library target — everything except main.cpp
# ---------------------------------------------------------------------------
# Populated as files land. For now, define the target so dependencies wire up.
add_library(merlion_node_exporter_lib STATIC)
target_include_directories(merlion_node_exporter_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/generated/include
)
target_link_libraries(merlion_node_exporter_lib
    PUBLIC  mne_compile_flags
    PRIVATE httplib::httplib CLI11::CLI11 spdlog::spdlog mne_release_flags
)
# Empty source list — placeholder until collectors land.
target_sources(merlion_node_exporter_lib PRIVATE
    src/placeholder.cpp
)

# ---------------------------------------------------------------------------
# Executable
# ---------------------------------------------------------------------------
add_executable(merlion-node-exporter src/main.cpp)
target_link_libraries(merlion-node-exporter
    PRIVATE merlion_node_exporter_lib mne_release_flags
)
set_target_properties(merlion-node-exporter PROPERTIES
    OUTPUT_NAME merlion-node-exporter
)

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
if(MNE_BUILD_TESTS)
    enable_testing()
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.7.1
        GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(Catch2)
    list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)

    add_executable(merlion_node_exporter_tests
        tests/placeholder_test.cpp
    )
    target_link_libraries(merlion_node_exporter_tests
        PRIVATE merlion_node_exporter_lib Catch2::Catch2WithMain
    )
    include(Catch)
    catch_discover_tests(merlion_node_exporter_tests)
endif()

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS merlion-node-exporter
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
