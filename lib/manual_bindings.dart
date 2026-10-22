import 'dart:ffi';

/// Handwritten bindings for the two functions declared in math_operations.h.
class MathOperationsWithFFI {
  MathOperationsWithFFI(DynamicLibrary library)
    : _multiply = library
          .lookupFunction<Int Function(Int, Int), int Function(int, int)>(
            'multiply',
          ),
      _add = library
          .lookupFunction<Int Function(Int, Int), int Function(int, int)>(
            'add',
          );

  // C int maps to Int in the native signature and int in the Dart signature.
  // Resolve each symbol once per instance, rather than once per invocation.
  final int Function(int, int) _multiply;
  final int Function(int, int) _add;

  int multiply(int first, int second) => _multiply(first, second);

  int add(int first, int second) => _add(first, second);
}
