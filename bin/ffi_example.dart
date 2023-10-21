import 'dart:ffi';
import 'package:ffi_example/generated_bindings.dart';

// This path is relative to the root of the project, and may need to be changed depending on where you run the example from.
final path = "native_code/build/libmathOperationsLib.so";
final DynamicLibrary _dylib = DynamicLibrary.open(path);

void main() {
  mathOperationsWithFFIGen();
  mathOperationsWithFFI();
}

void mathOperationsWithFFIGen() {
  // This is the generated bindings from the FFIGen tool.
  final NativeLibrary _bindings = NativeLibrary(_dylib);

  var firstDigit = 10;
  var secondDigit = 2;
  final multiplyResult = _bindings.multiply(firstDigit, secondDigit);
  print("Using FFIGen -> $firstDigit * $secondDigit = $multiplyResult");
  final addResult = _bindings.add(firstDigit, secondDigit);
  print("Using FFIGen -> $firstDigit + $secondDigit = $addResult");
}

void mathOperationsWithFFI() {
  // If you don't want to use the FFIGen tool, you can use the FFI directly.
  final int Function(int, int) multiplyFFI = _dylib
      .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("multiply")
      .asFunction();

  final int Function(int, int) addFFI = _dylib
      .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("add")
      .asFunction();

  var firstDigit = 10;
  var secondDigit = 2;
  final multiplyResult = multiplyFFI(firstDigit, secondDigit);
  print("Using FFI -> $firstDigit * $secondDigit = $multiplyResult");
  final addResult = addFFI(firstDigit, secondDigit);
  print("Using FFI -> $firstDigit + $secondDigit = $addResult");
}
