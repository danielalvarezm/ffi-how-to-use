cmake_minimum_required(VERSION 3.16)
project(FfiMeasurements LANGUAGES C)

add_library(measurements SHARED measurements.c)
set_target_properties(measurements PROPERTIES
  C_STANDARD 99
  C_STANDARD_REQUIRED YES
  C_EXTENSIONS NO
)
