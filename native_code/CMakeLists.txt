cmake_minimum_required(VERSION 3.16)

project(FfiExample LANGUAGES C)

add_subdirectory(math_operations)

add_executable(app main.c)
target_link_libraries(app PRIVATE mathOperationsLib)
