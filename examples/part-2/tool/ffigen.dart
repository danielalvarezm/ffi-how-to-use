import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final root = Platform.script.resolve('../');
  const functions = {'measurement_label'};

  await FfiGenerator(
    input: Input(entryPoints: [root.resolve('native_code/measurements.h')]),
    output: Output(
      dart: DartOutput(path: root.resolve('lib/generated_bindings.dart')),
      style: const DynamicLibraryBindings(wrapperName: 'MeasurementBindings'),
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = functions.contains(node.originalName),
        struct: (node) {
          if (node.originalName == 'measurement') {
            node.isIncluded = true;
            node.name = 'NativeMeasurement';
          }
        },
      ),
    ],
  ).generate();
}
