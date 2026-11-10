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

typedef MeasurementSummary = ({
  int count,
  double minimum,
  double maximum,
  double mean,
});

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

  MeasurementSummary summarizeInto(List<Measurement> batch) {
    return _withNativeBatch(batch, (native, count, arena) {
      final output = arena<NativeSummary>();
      _checkStatus(_bindings.summarize_into(native, count, output));
      return _copySummary(output);
    });
  }

  MeasurementSummary summarize(List<Measurement> batch) {
    return _withNativeBatch(batch, (native, count, arena) {
      final status = arena<Int>();
      final output = _bindings.summarize(native, count, status);
      try {
        _checkStatus(status.value);
        if (output == nullptr) {
          throw StateError('C reported success without a summary.');
        }
        return _copySummary(output);
      } finally {
        if (output != nullptr) {
          _bindings.summary_free(output);
        }
      }
    });
  }
}

T _withNativeBatch<T>(
  List<Measurement> batch,
  T Function(Pointer<NativeMeasurement>, int, Arena) call,
) {
  return using((arena) {
    final count = batch.length;
    final Pointer<NativeMeasurement> native = count == 0
        ? nullptr
        : arena<NativeMeasurement>(count);
    for (var i = 0; i < count; i++) {
      _writeMeasurement(native + i, batch[i], arena);
    }
    return call(native, count, arena);
  });
}

MeasurementSummary _copySummary(Pointer<NativeSummary> pointer) {
  final result = pointer.ref;
  return (
    count: result.count,
    minimum: result.minimum,
    maximum: result.maximum,
    mean: result.mean,
  );
}

void _checkStatus(int status) {
  switch (status) {
    case SUMMARY_OK:
      return;
    case SUMMARY_EMPTY:
      throw ArgumentError('A measurement batch cannot be empty.');
    case SUMMARY_INVALID:
      throw ArgumentError('Measurements and their sum must be finite.');
    case SUMMARY_ALLOCATION_FAILED:
      throw StateError('C could not allocate memory for the summary.');
    default:
      throw StateError('Unexpected native summary status: $status.');
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
