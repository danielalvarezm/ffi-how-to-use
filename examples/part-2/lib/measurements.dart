import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'generated_bindings.dart';

final class Measurement {
  const Measurement(this.label, this.value);

  final String label;
  final double value;
}

final class Measurements {
  Measurements(this._bindings);

  final MeasurementBindings _bindings;

  static Future<Measurements> open() async {
    if (!Platform.isLinux) {
      throw UnsupportedError('This example requires Linux or WSL.');
    }
    final source = await Isolate.resolvePackageUri(
      Uri.parse('package:ffi_measurements/measurements.dart'),
    );
    if (source == null) {
      throw StateError('Cannot locate the package. Run dart pub get.');
    }
    final path = source
        .resolve('../native_code/build/libmeasurements.so')
        .toFilePath();
    try {
      return Measurements(MeasurementBindings(DynamicLibrary.open(path)));
    } on ArgumentError catch (error) {
      throw FileSystemException(
        'Could not open the C library. Build it with CMake first. $error',
        path,
      );
    }
  }

  String readLabel(Measurement measurement) {
    return using((arena) {
      final native = arena<NativeMeasurement>();
      _writeMeasurement(native, measurement, arena);
      final borrowed = _bindings.measurement_label(native);
      return borrowed.cast<Utf8>().toDartString();
    });
  }
}

void _writeMeasurement(
  Pointer<NativeMeasurement> destination,
  Measurement measurement,
  Arena arena,
) {
  if (measurement.label.contains('\u0000')) {
    throw ArgumentError('A measurement label cannot contain NUL.');
  }
  destination.ref
    ..label = measurement.label.toNativeUtf8(allocator: arena).cast<Char>()
    ..value = measurement.value;
}
