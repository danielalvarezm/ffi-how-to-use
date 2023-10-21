# Set the output folder where your program will be created
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Compile math_operations.c into a shared library
add_library(mathOperationsLib SHARED math_operations.c)

# Add current directory to the include search scope
target_include_directories(mathOperationsLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})