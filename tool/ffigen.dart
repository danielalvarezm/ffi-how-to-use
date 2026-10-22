import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final root = Platform.script.resolve('../');
  await FfiGenerator(
    input: Input(
      entryPoints: [
        root.resolve('native_code/math_operations/math_operations.h'),
      ],
    ),
    output: Output(
      dart: DartOutput(path: root.resolve('lib/generated_bindings.dart')),
      // Keep explicit library loading so both examples use the same .so.
      style: const DynamicLibraryBindings(wrapperName: 'MathOperationsFFIGen'),
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded =
            node.originalName == 'multiply' || node.originalName == 'add',
      ),
    ],
  ).generate();
}
