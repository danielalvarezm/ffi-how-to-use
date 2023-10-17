import 'dart:ffi';
import 'package:ffi_example/generated_bindings.dart';

// This path is relative to the root of the project, and may need to be changed depending on where you run the example from.
final path = "native_code/build/libmultiplyLib.so";
final DynamicLibrary _dylib = DynamicLibrary.open(path);

final NativeLibrary _bindings = NativeLibrary(_dylib);

void main() {
  var firstDigit = 10;
  var secondDigit = 2;
  final result = _bindings.multiply(firstDigit, secondDigit);
  print("$firstDigit * $secondDigit = $result");
}