import 'dart:ffi';
import 'package:ffi_example/generated_bindings.dart';

// This path is relative to the root of the project, and may need to be changed depending on where you run the example from.
final path = "native_code/build/libmultiplyLib.so";
final DynamicLibrary _dylib = DynamicLibrary.open(path);

void main() {
  multiplyUsingFFIGen();
  multiplyUsingFFI();
}

void multiplyUsingFFIGen() {
  // This is the generated bindings from the FFIGen tool.
  final NativeLibrary _bindings = NativeLibrary(_dylib);

  var firstDigit = 10;
  var secondDigit = 2;
  final result = _bindings.multiply(firstDigit, secondDigit);
  print("Using FFIGen -> $firstDigit * $secondDigit = $result");
}

void multiplyUsingFFI() {
  // If you don't want to use the FFIGen tool, you can use the FFI directly.
  final int Function(int, int) multiplyFFI = _dylib
      .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("multiply")
      .asFunction();

  var firstDigit = 10;
  var secondDigit = 2;
  final result = multiplyFFI(firstDigit, secondDigit);
  print("Using FFI -> $firstDigit * $secondDigit = $result");
}
