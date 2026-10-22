import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi_example/generated_bindings.dart';
import 'package:ffi_example/manual_bindings.dart';
import 'package:ffi_example/native_library.dart';
import 'package:test/test.dart';

void main() {
  late MathOperationsWithFFI manual;
  late MathOperationsFFIGen generated;

  setUpAll(() async {
    final library = await loadMathLibrary();
    manual = MathOperationsWithFFI(library);
    generated = MathOperationsFFIGen(library);
  });

  // All inputs and results are deliberately small: signed C overflow is undefined.
  const cases = [
    (first: 5, second: 2, sum: 7, product: 10),
    (first: -5, second: 2, sum: -3, product: -10),
    (first: -5, second: -2, sum: -7, product: 10),
    (first: 0, second: 7, sum: 7, product: 0),
    (first: 7, second: 0, sum: 7, product: 0),
    (first: 0, second: 0, sum: 0, product: 0),
  ];

  for (final value in cases) {
    group('(${value.first}, ${value.second})', () {
      // Preserve the original four operation tests for every input pair.
      test('Multiply using ffigen', () {
        expect(generated.multiply(value.first, value.second), value.product);
      });
      test('Add using ffigen', () {
        expect(generated.add(value.first, value.second), value.sum);
      });
      test('Multiply using ffi', () {
        expect(manual.multiply(value.first, value.second), value.product);
      });
      test('Add using ffi', () {
        expect(manual.add(value.first, value.second), value.sum);
      });
      test('Both approaches agree', () {
        expect(
          manual.multiply(value.first, value.second),
          generated.multiply(value.first, value.second),
        );
        expect(
          manual.add(value.first, value.second),
          generated.add(value.first, value.second),
        );
      });
    });
  }

  test('Missing library reports its path and build instructions', () async {
    final temporary = Directory.systemTemp.createTempSync('ffi-missing-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final missing = temporary.uri.resolve('missing.so').toFilePath();

    await expectLater(
      loadMathLibrary(path: missing),
      throwsA(
        isA<FileSystemException>()
            .having((error) => error.path, 'path', missing)
            .having(
              (error) => error.message,
              'message',
              contains('cmake --build'),
            ),
      ),
    );
  });

  test('Invalid shared library preserves the loader diagnostic', () async {
    final temporary = Directory.systemTemp.createTempSync('ffi-invalid-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final invalid = File.fromUri(temporary.uri.resolve('invalid.so'));
    invalid.writeAsStringSync('Not a shared library');

    await expectLater(
      loadMathLibrary(path: invalid.path),
      throwsA(
        isA<FileSystemException>()
            .having((error) => error.path, 'path', invalid.path)
            .having(
              (error) => error.message,
              'message',
              contains('Loader error:'),
            ),
      ),
    );
  });

  test('Missing native symbols fail explicitly', () {
    final library = DynamicLibrary.process();
    expect(() => MathOperationsWithFFI(library), throwsArgumentError);
    // Generated bindings resolve symbols lazily, on their first invocation.
    expect(() => MathOperationsFFIGen(library).add(1, 2), throwsArgumentError);
  });

  test(
    'CLI loads the library outside the repository working directory',
    () async {
      final source = (await Isolate.resolvePackageUri(
        Uri.parse('package:ffi_example/native_library.dart'),
      ))!;
      final entryPoint = source.resolve('../bin/ffi_example.dart').toFilePath();
      final temporary = Directory.systemTemp.createTempSync('ffi-cli-');
      addTearDown(() => temporary.deleteSync(recursive: true));

      final result = await Process.run(Platform.resolvedExecutable, [
        entryPoint,
      ], workingDirectory: temporary.path);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        result.stdout,
        [
          'Multiply with ffigen: 20',
          'Add with ffigen: 12',
          'Multiply with ffi: 20',
          'Add with ffi: 12',
          '',
        ].join('\n'),
      );
    },
  );
}
