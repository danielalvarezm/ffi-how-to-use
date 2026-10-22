import 'dart:io';

import 'package:ffi_example/generated_bindings.dart';
import 'package:ffi_example/manual_bindings.dart';
import 'package:ffi_example/native_library.dart';

Future<void> main() async {
  try {
    final library = await loadMathLibrary();
    const first = 10;
    const second = 2;

    final generated = MathOperationsFFIGen(library);
    print('Multiply with ffigen: ${generated.multiply(first, second)}');
    print('Add with ffigen: ${generated.add(first, second)}');

    final manual = MathOperationsWithFFI(library);
    print('Multiply with ffi: ${manual.multiply(first, second)}');
    print('Add with ffi: ${manual.add(first, second)}');
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } on ArgumentError catch (error) {
    // A library can load successfully but still lack the expected C symbols.
    stderr.writeln('Could not resolve a native function: $error');
    exitCode = 1;
  } on UnsupportedError catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
