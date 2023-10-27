import 'dart:ffi';
import 'package:ffi_example/generated_bindings.dart';

// This path is relative to the root of the project, and may need to be changed depending on where you run the example from.
final path = "native_code/build/libmathOperationsLib.so";
final DynamicLibrary _dylib = DynamicLibrary.open(path);

void main() {
  var firstDigit = 10;
  var secondDigit = 2;

  mathOperationsWithFFIGen(firstDigit, secondDigit);
  mathOperationsWithFFI(firstDigit, secondDigit);
}

void mathOperationsWithFFIGen(int firstDigit, int secondDigit) {
  // This is the generated bindings from the FFIGen tool.
  final NativeLibrary _bindings = NativeLibrary(_dylib);

  final multiplyResult = _bindings.multiply(firstDigit, secondDigit);
  final addResult = _bindings.add(firstDigit, secondDigit);

  print("Using FFIGen -> $firstDigit * $secondDigit = $multiplyResult");
  print("Using FFIGen -> $firstDigit + $secondDigit = $addResult");
}

void mathOperationsWithFFI(int firstDigit, int secondDigit) {
  // If you don't want to use the FFIGen tool, you can use the FFI directly.
  final int Function(int, int) multiplyFFI = _dylib.lookup<NativeFunction<Int32 Function(Int32, Int32)>>("multiply").asFunction();
  final int Function(int, int) addFFI = _dylib.lookup<NativeFunction<Int32 Function(Int32, Int32)>>("add").asFunction();

  final multiplyResult = multiplyFFI(firstDigit, secondDigit);
  final addResult = addFFI(firstDigit, secondDigit);

  print("Using FFI -> $firstDigit * $secondDigit = $multiplyResult");
  print("Using FFI -> $firstDigit + $secondDigit = $addResult");
}
