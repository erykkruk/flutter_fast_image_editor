cmake_minimum_required(VERSION 3.10)
project(fast_image_editor)

add_library(fast_image_editor SHARED
    ../src/image_edit.cpp
)

target_include_directories(fast_image_editor PRIVATE
    ../src
)

set_target_properties(fast_image_editor PROPERTIES
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
)

target_compile_options(fast_image_editor PRIVATE
    -fvisibility=hidden
)

# Android 15 requires 16KB page alignment for native libraries
target_link_options(fast_image_editor PRIVATE
    -Wl,-z,max-page-size=16384
)
