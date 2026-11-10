import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final root = Platform.script.resolve('../');
  final header = root.resolve('native_code/measurements.h');
  const functions = {'measurement_label', 'summarize_into'};
  const structs = {
    'measurement': 'NativeMeasurement',
    'summary': 'NativeSummary',
  };
  const statuses = {'SUMMARY_OK', 'SUMMARY_EMPTY', 'SUMMARY_INVALID'};

  await FfiGenerator(
    input: Input(entryPoints: [header], include: (uri) => uri == header),
    output: Output(
      dart: DartOutput(path: root.resolve('lib/generated_bindings.dart')),
      style: const DynamicLibraryBindings(wrapperName: 'MeasurementBindings'),
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = functions.contains(node.originalName),
        struct: (node) {
          final name = structs[node.originalName];
          if (name != null) {
            node.isIncluded = true;
            node.name = name;
          }
        },
        macroConstant: (node) =>
            node.isIncluded = statuses.contains(node.originalName),
      ),
    ],
  ).generate();
}
