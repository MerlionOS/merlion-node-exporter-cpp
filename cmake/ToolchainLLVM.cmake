# Optional toolchain file that forces the build to use Homebrew LLVM clang
# on macOS instead of Apple Clang. Apple Clang ships with a libc++ that
# trails mainline by several C++23 features we use (std::expected,
# std::format), so we fail fast rather than degrade silently.
#
# Usage:
#   cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=cmake/ToolchainLLVM.cmake
#
# Or, equivalently, set $CC / $CXX in the environment before configuring.

if(APPLE)
    execute_process(
        COMMAND brew --prefix llvm
        OUTPUT_VARIABLE _LLVM_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE _BREW_RESULT
    )
    if(NOT _BREW_RESULT EQUAL 0)
        message(FATAL_ERROR
            "ToolchainLLVM.cmake: `brew --prefix llvm` failed. "
            "Install with `brew install llvm` or unset the toolchain file."
        )
    endif()
    set(CMAKE_C_COMPILER   "${_LLVM_PREFIX}/bin/clang"   CACHE FILEPATH "" FORCE)
    set(CMAKE_CXX_COMPILER "${_LLVM_PREFIX}/bin/clang++" CACHE FILEPATH "" FORCE)
    # Make sure the rpath finds Homebrew's libc++ at runtime.
    set(CMAKE_INSTALL_RPATH "${_LLVM_PREFIX}/lib/c++")
    set(CMAKE_BUILD_RPATH   "${_LLVM_PREFIX}/lib/c++")
endif()
