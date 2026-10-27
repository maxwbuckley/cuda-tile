# -----------------------------------------------------------------------------
# Set and verify build type for CUDA Tile. If no CMAKE_BUILD_TYPE or
# CMAKE_CONFIGURATION_TYPES is set, default to `Release` build. If
# CMAKE_BUILD_TYPE is set to an unsupported value, print an error message
# and exit.
# -----------------------------------------------------------------------------
macro(set_cuda_tile_build_type)
  set(CMAKE_BUILD_TYPE_OPTIONS Release Debug RelWithDebInfo MinSizeRel)
  set(DEFAULT_BUILD_TYPE "Release")

  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "CMAKE_BUILD_TYPE not set, defaulting to ${DEFAULT_BUILD_TYPE}")
    set(CMAKE_BUILD_TYPE "${DEFAULT_BUILD_TYPE}" CACHE STRING "Build type (default ${DEFAULT_BUILD_TYPE})" FORCE)
  else()
    message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

    if(NOT CMAKE_BUILD_TYPE IN_LIST CMAKE_BUILD_TYPE_OPTIONS)
      message(FATAL_ERROR "
      Unsupported build type selected. Use -DCMAKE_BUILD_TYPE=<type> to specify a valid build type for CUDA Tile.
      Available options are:
        * -DCMAKE_BUILD_TYPE=Release - For an optimized build with no assertions or debug info.
        * -DCMAKE_BUILD_TYPE=Debug - For an unoptimized build with assertions and debug info.
        * -DCMAKE_BUILD_TYPE=RelWithDebInfo - For an optimized build with no assertions but with debug info.
        * -DCMAKE_BUILD_TYPE=MinSizeRel - For a build optimized for size instead of speed.
      ")
    endif()
  endif()
endmacro(set_cuda_tile_build_type)

# -----------------------------------------------------------------------------
# Apply strict compiler warnings to a CUDA Tile target.
#
# This must be used instead of add_compile_options() because
# add_compile_options() propagates to LLVM/MLIR subdirectory targets.
# Call cuda_tile_enable_warnings(<target>) after each CUDA Tile target
# is created.
# -----------------------------------------------------------------------------
function(cuda_tile_enable_warnings target)
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(${target} PRIVATE
      -Wall
      -Wextra
      -Wpedantic
      -Wnon-virtual-dtor
      -Woverloaded-virtual
      -Wcast-align
      -Wunused
      -Wformat=2
      -Werror
      # MLIR tablegen-generated .inc headers contain methods with unused
      # parameters (e.g. getODSOperandIndexAndLength) and doc comments with
      # LaTeX backslashes that GCC interprets as line continuations. Suppress
      # these specific sub-warnings while keeping the rest of -Wunused and
      # -Wextra active.
      -Wno-unused-parameter
      -Wno-comment
    )
    # GCC's -Wshadow warns about constructor parameters that share names
    # with members — a ubiquitous C++ pattern. Use -Wshadow=local to catch
    # local-variable shadowing without those false positives. Clang's
    # -Wshadow already excludes the constructor case.
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      target_compile_options(${target} PRIVATE -Wshadow=local)
    else()
      target_compile_options(${target} PRIVATE -Wshadow)
    endif()
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(${target} PRIVATE
      /W4
      /WX
      # MLIR tablegen-generated .inc headers contain methods with unreferenced
      # formal parameters. Suppress C4100 (unreferenced formal parameter) to
      # match the -Wno-unused-parameter suppression on GNU/Clang.
      /wd4100
    )
  endif()
endfunction()
