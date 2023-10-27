import 'dart:ffi';
import 'package:ffi_example/generated_bindings.dart';

// This path is relative to the root of the project, and may need to be changed depending on where you run the example from.
final path = "native_code/build/libmathOperationsLib.so";
final DynamicLibrary _dynamicLib = DynamicLibrary.open(path);

void main() {
  var firstDigit = 10;
  var secondDigit = 2;

  // with ffigen
  final mathOperationsFFIGen = MathOperationsFFIGen(_dynamicLib);
  print("Multiply with ffigen: ${mathOperationsFFIGen.multiply(firstDigit, secondDigit)}");
  print("Add with ffigen: ${mathOperationsFFIGen.add(firstDigit, secondDigit)}");

  // with ffi
  final mathOperationsWithFFI = MathOperationsWithFFI(_dynamicLib);
  print("Multiply with ffi: ${mathOperationsWithFFI.multiply(firstDigit, secondDigit)}");
  print("Add with ffi: ${mathOperationsWithFFI.add(firstDigit, secondDigit)}");
}

class MathOperationsFFIGen {
  final NativeLibrary _bindings;

  MathOperationsFFIGen(DynamicLibrary dynamicLibrary) : _bindings = NativeLibrary(dynamicLibrary); // Generated bindings from the FFIGen tool.

  int multiply(int firstDigit, int secondDigit) {
    return _bindings.multiply(firstDigit, secondDigit);
  }

  int add(int firstDigit, int secondDigit) {
    return _bindings.add(firstDigit, secondDigit);
  }
}

class MathOperationsWithFFI {
  final DynamicLibrary _dylib;

  MathOperationsWithFFI(this._dylib);

  int multiply(int firstDigit, int secondDigit) {
    final int Function(int, int) multiplyFFI = _dylib.lookup<NativeFunction<Int32 Function(Int32, Int32)>>("multiply").asFunction();
    return multiplyFFI(firstDigit, secondDigit);
  }

  int add(int firstDigit, int secondDigit) {
    final int Function(int, int) addFFI = _dylib.lookup<NativeFunction<Int32 Function(Int32, Int32)>>("add").asFunction();
    return addFFI(firstDigit, secondDigit);
  }
}
