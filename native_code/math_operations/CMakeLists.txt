add_library(mathOperationsLib SHARED math_operations.c)
target_compile_features(mathOperationsLib PUBLIC c_std_99)
set_target_properties(mathOperationsLib PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

target_include_directories(mathOperationsLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
