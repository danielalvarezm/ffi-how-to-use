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

  test('accumulates two batches in an opaque session', () {
    final session = measurements.openSession();
    addTearDown(session.close);
    const first = Measurement('Outdoor temperature', 20.0);
    const second = Measurement('Café temperature', 24.0);
    expect(session.snapshot, throwsStateError);
    session.addBatch(const [first]);
    expect(session.snapshot().count, 1);
    session.addBatch(const [second]);
    expect(
      session.snapshot(),
      measurements.summarizeInto(const [first, second]),
    );
  });

  test('does not change the session when a batch is rejected', () {
    final session = measurements.openSession();
    addTearDown(session.close);
    session.addBatch(const [Measurement('Outdoor temperature', 20.0)]);
    final before = session.snapshot();
    expect(() => session.addBatch(const []), throwsArgumentError);
    expect(
      () => session.addBatch(const [
        Measurement('Would change the total', 24.0),
        Measurement('Invalid', double.infinity),
      ]),
      throwsArgumentError,
    );
    expect(session.snapshot(), before);
  });

  test('rejects use after close and allows closing twice', () {
    final session = measurements.openSession();
    session.close();
    expect(session.close, returnsNormally);
    expect(() => session.addBatch(const []), throwsStateError);
    expect(session.snapshot, throwsStateError);
  });

  test('notifies synchronously and in order for accepted batches only', () {
    final session = measurements.openSession();
    addTearDown(session.close);
    final events = <String>[];
    void onBatchAccepted(int count, int total) => events.add('$count/$total');

    session.addBatch(const [
      Measurement('Outdoor temperature', 20.0),
    ], onBatchAccepted: onBatchAccepted);
    events.add('first call returned');
    expect(
      () => session.addBatch(const [], onBatchAccepted: onBatchAccepted),
      throwsArgumentError,
    );
    session.addBatch(const [
      Measurement('Café temperature', 24.0),
    ], onBatchAccepted: onBatchAccepted);
    events.add('second call returned');

    expect(events, [
      '1/1',
      'first call returned',
      '1/2',
      'second call returned',
    ]);
    expect(session.snapshot().count, 2);
  });

  test('rejects reentry and closing the same session from the callback', () {
    final session = measurements.openSession();
    addTearDown(session.close);
    session.addBatch(
      const [Measurement('Outdoor temperature', 20.0)],
      onBatchAccepted: (_, _) {
        expect(() => session.addBatch(const []), throwsStateError);
        expect(session.snapshot, throwsStateError);
        expect(session.close, throwsStateError);
      },
    );
    expect(session.snapshot().count, 1);
  });

  test('rethrows callback errors in Dart without rolling back the batch', () {
    final session = measurements.openSession();
    addTearDown(session.close);
    final failure = StateError('Callback failed.');
    expect(
      () => session.addBatch(const [
        Measurement('Outdoor temperature', 20.0),
      ], onBatchAccepted: (_, _) => throw failure),
      throwsA(same(failure)),
    );
    expect(session.snapshot().count, 1);
  });
}
