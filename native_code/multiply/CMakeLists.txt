# CMakeLists.txt en la carpeta 'multiply'

# Set the output folder where your program will be created
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Compile multiply.c into a shared library
add_library(multiplyLib SHARED multiply.c)

# Add current directory to the include search scope
target_include_directories(multiplyLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})