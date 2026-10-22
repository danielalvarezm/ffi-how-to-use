import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

/// Loads the Linux library explicitly, with no work performed at import time.
///
/// The default path is relative to this source package, not Directory.current.
/// An explicit [path] can be used for a different build directory or in tests.
Future<DynamicLibrary> loadMathLibrary({String? path}) async {
  if (!Platform.isLinux) {
    throw UnsupportedError('This example currently supports Linux only.');
  }

  if (path == null) {
    final source = await Isolate.resolvePackageUri(
      Uri.parse('package:ffi_example/native_library.dart'),
    );
    if (source == null) {
      throw StateError(
        'Cannot locate the ffi_example package. Run dart pub get.',
      );
    }
    path = source
        .resolve('../native_code/build/libmathOperationsLib.so')
        .toFilePath();
  }

  final libraryPath = File(path).absolute.path;
  try {
    return DynamicLibrary.open(libraryPath);
  } on ArgumentError catch (error) {
    throw FileSystemException(
      'Could not open the C library. From the repository root, run '
      'cmake -S native_code -B native_code/build && '
      'cmake --build native_code/build. Loader error: $error',
      libraryPath,
    );
  }
}
