import 'dart:ffi';

import 'package:test/test.dart';
import '../bin/ffi_example.dart';

void main() {
  final path = "native_code/build/libmathOperationsLib.so";
  final DynamicLibrary _dynamicLib = DynamicLibrary.open(path);
  final firstDigit = 5;
  final secondDigit = 2;

  test('Multiply using ffigen', () {
    final mathOperationsFFIGen = MathOperationsFFIGen(_dynamicLib);
    expect(mathOperationsFFIGen.multiply(firstDigit, secondDigit), 10);
  });

  test('Add using ffigen', () {
    final mathOperationsFFIGen = MathOperationsFFIGen(_dynamicLib);
    expect(mathOperationsFFIGen.add(firstDigit, secondDigit), 7);
  });

  test('Multiply using ffi', () {
    final mathOperationsWithFFI = MathOperationsWithFFI(_dynamicLib);
    expect(mathOperationsWithFFI.multiply(firstDigit, secondDigit), 10);
  });

  test('Add using ffi', () {
    final mathOperationsWithFFI = MathOperationsWithFFI(_dynamicLib);
    expect(mathOperationsWithFFI.add(firstDigit, secondDigit), 7);
  });
}