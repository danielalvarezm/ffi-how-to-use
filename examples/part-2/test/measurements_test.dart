import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:ffi_measurements/generated_bindings.dart';
import 'package:ffi_measurements/measurements.dart';
import 'package:test/test.dart';

void main() {
  late Measurements measurements;

  setUpAll(() async {
    measurements = await Measurements.open();
  });

  test('round-trips a UTF-8 label through C', () {
    const measurement = Measurement('Café temperature', 24.0);
    expect(measurements.readLabel(measurement), measurement.label);
  });

  test('rejects an embedded NUL rather than truncating the label', () {
    expect(
      () => measurements.readLabel(
        const Measurement('Outdoor\u0000 temperature', 20),
      ),
      throwsArgumentError,
    );
  });

  test('writes a batch summary into caller-owned memory', () {
    final summary = measurements.summarizeInto(const [
      Measurement('Outdoor temperature', 20.0),
      Measurement('Café temperature', 24.0),
    ]);
    expect(summary, (count: 2, minimum: 20.0, maximum: 24.0, mean: 22.0));
  });

  test('reports an empty batch explicitly', () {
    expect(
      () => measurements.summarizeInto(const []),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'A measurement batch cannot be empty.',
        ),
      ),
    );
  });

  test('returns an equivalent summary from C-owned memory', () {
    const batch = [
      Measurement('Outdoor temperature', 20.0),
      Measurement('Café temperature', 24.0),
    ];
    expect(measurements.summarize(batch), measurements.summarizeInto(batch));
  });

  test('returns a null pointer and the empty-batch status', () {
    final native = MeasurementBindings(
      DynamicLibrary.open('native_code/build/libmeasurements.so'),
    );
    using((arena) {
      final status = arena<Int>();
      expect(native.summarize(nullptr, 0, status), nullptr);
      expect(status.value, SUMMARY_EMPTY);
    });
    expect(
      () => measurements.summarize(const []),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'A measurement batch cannot be empty.',
        ),
      ),
    );
  });

  test('rejects non-finite values and sums', () {
    expect(
      () => measurements.summarizeInto(const [
        Measurement('Invalid', double.nan),
      ]),
      throwsArgumentError,
    );
    expect(
      () => measurements.summarizeInto(const [
        Measurement('First', 1.7e308),
        Measurement('Second', 1.7e308),
      ]),
      throwsArgumentError,
    );
  });
}
