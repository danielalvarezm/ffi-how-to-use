import 'package:ffi_measurements/measurements.dart';

Future<void> main() async {
  final measurements = await Measurements.open();
  const outdoor = Measurement('Outdoor temperature', 20.0);
  const cafe = Measurement('Café temperature', 24.0);
  print('Label read by C: ${measurements.readLabel(outdoor)}');
  print('Label read by C: ${measurements.readLabel(cafe)}');
  const batch = [outdoor, cafe];
  print(
    'Summary (Dart memory): ${_formatSummary(measurements.summarizeInto(batch))}',
  );
  print('Summary (C memory): ${_formatSummary(measurements.summarize(batch))}');

  final session = measurements.openSession();
  try {
    session.addBatch(const [outdoor]);
    session.addBatch(const [cafe]);
    print('Session summary: ${_formatSummary(session.snapshot())}');
  } finally {
    session.close();
  }
}

String _formatSummary(MeasurementSummary summary) =>
    'count=${summary.count}, min=${summary.minimum}, '
    'max=${summary.maximum}, mean=${summary.mean}';
