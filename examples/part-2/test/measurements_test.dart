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
}
