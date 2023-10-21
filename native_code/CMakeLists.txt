cmake_minimum_required(VERSION 3.5)

project(FfiExample)

# Configures the output folder for the generated files
set(CMAKE_BINARY_DIR "${CMAKE_SOURCE_DIR}/build")
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR})
set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR})

# Adds the 'math_operations' subfolder to the project
add_subdirectory(math_operations)

# Compiles the main.c file into an executable
add_executable(app main.c)

# Links the executable with the shared library
target_link_libraries(app mathOperationsLib)