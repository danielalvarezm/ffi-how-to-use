import 'dart:ffi';
import 'package:ffi_example/generated_bindings.dart';

final path = "../native_code/build/libmultiplyLib.so";
final DynamicLibrary _dylib = DynamicLibrary.open(path);

final NativeLibrary _bindings = NativeLibrary(_dylib);

void main() {
  var firstDigit = 10;
  var secondDigit = 2;
  final result = _bindings.multiply(firstDigit, secondDigit);
  print("$firstDigit * $secondDigit = $result");
}