cmake_minimum_required(VERSION 3.6)

set(lib_name pbc)
set(target_name ext_${lib_name})

project(${lib_name})

set(${target_name}_src
  alloc.c
  array.c
  bootstrap.c
  context.c
  decode.c
  map.c
  pattern.c
  pbc-lua.c
  proto.c
  register.c
  rmessage.c
  stringpool.c
  varint.c
  wmessage.c
)

add_library(${target_name} STATIC
  ${${target_name}_src}
)

target_include_directories(${target_name} PRIVATE ../lua/luajit/include)
target_include_directories(${target_name} PUBLIC ..)

set_target_properties(${target_name}
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    FOLDER "External"
)

