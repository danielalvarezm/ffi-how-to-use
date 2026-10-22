# Dart FFI and FFIGen

[English](#introduction) | [Español](#español)

## Introduction

This project is a practical example of using Dart FFI to work with a native
library. It shows how to write bindings by hand and how to generate them
with FFIGen.

A small C library with addition and multiplication serves as the example
for both approaches.

## Setup and run

Install these tools and make them available on your PATH:

- [Dart SDK 3.13.6](https://dart.dev/get-dart/archive).
- CMake 3.16 or later and a C compiler.
- LLVM/libclang 18 or later. See the [FFIGen installation instructions](https://pub.dev/packages/ffigen#requirements).

Run these commands from the repository root:

```sh
dart pub get --enforce-lockfile
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Expected application output:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

The generator configuration is in `tool/ffigen.dart`. Rerun it after changing
the C header. The generated bindings and `pubspec.lock` are committed.
Do not edit `lib/generated_bindings.dart` by hand.

With [Task v3](https://taskfile.dev/docs/installation), `task run` performs
the same preparation and execution.

## Tests

Tested on Linux in GitHub Actions and on Ubuntu under WSL2 on Windows.

After setup:

```sh
dart test
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
```

The 34 tests cover both binding approaches, positive and negative values,
zero, loading errors and execution from another working directory.
Inputs and results must fit in a C `int`.

The C-only example can be checked with `./native_code/build/app`.
It prints `10 * 2 = 20` and `10 + 2 = 12`.

Task shortcuts are `task test` for preparation and tests, and `task check`
for formatting and analysis. [GitHub Actions](.github/workflows/ci.yaml)
also checks generation, compilation, examples and tests.

## Project structure

```text
bin/ffi_example.dart                  Console entry point
lib/
  manual_bindings.dart                Handwritten FFI bindings
  generated_bindings.dart             FFIGen output
  native_library.dart                 Shared library loader
native_code/
  CMakeLists.txt                      Native build configuration
  main.c                              C-only example
  math_operations/
    CMakeLists.txt
    math_operations.h                 C declarations
    math_operations.c                 C implementation
tool/ffigen.dart                      Binding generator configuration
test/ffi_example_test.dart             Tests
Taskfile.yaml                         Command shortcuts
pubspec.yaml / pubspec.lock            Dependencies and locked versions
analysis_options.yaml                 Analysis rules
.github/workflows/ci.yaml             CI checks
```

## Español

### Introducción

Este proyecto es un ejemplo práctico de cómo usar FFI en Dart para trabajar
con una biblioteca nativa. Muestra cómo escribir los bindings a mano y cómo
generarlos con FFIGen.

Para comparar ambos enfoques se utiliza una pequeña biblioteca C con
operaciones de suma y multiplicación.

### Configuración y ejecución

Instala estas herramientas y añádelas al PATH:

- [Dart SDK 3.13.6](https://dart.dev/get-dart/archive).
- CMake 3.16 o posterior y un compilador C.
- LLVM/libclang 18 o posterior. Consulta las [instrucciones de instalación de FFIGen](https://pub.dev/packages/ffigen#requirements).

Ejecuta estos comandos desde la raíz del repositorio:

```sh
dart pub get --enforce-lockfile
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Salida esperada de la aplicación:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

La configuración del generador está en `tool/ffigen.dart`. Ejecútalo de nuevo
si cambias el header C. Los bindings generados y `pubspec.lock` están
versionados. No edites `lib/generated_bindings.dart` a mano.

Con [Task v3](https://taskfile.dev/docs/installation), `task run` realiza
la misma preparación y ejecución.

### Pruebas

Probado en Linux mediante GitHub Actions y en Ubuntu bajo WSL2 en Windows.

Después de configurar el proyecto:

```sh
dart test
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
```

Los 34 tests cubren ambos enfoques, valores positivos y negativos, cero,
errores de carga y ejecución desde otro directorio.
Los operandos y resultados deben caber en un `int` de C.

El ejemplo exclusivo de C se puede comprobar con `./native_code/build/app`.
Imprime `10 * 2 = 20` y `10 + 2 = 12`.

Los atajos de Task son `task test` para preparación y tests, y `task check`
para formato y análisis. [GitHub Actions](.github/workflows/ci.yaml)
también comprueba la generación, compilación, ejemplos y tests.

### Estructura

```text
bin/ffi_example.dart                  Punto de entrada de consola
lib/
  manual_bindings.dart                Bindings FFI manuales
  generated_bindings.dart             Salida de FFIGen
  native_library.dart                 Cargador de la biblioteca
native_code/
  CMakeLists.txt                      Configuración de compilación nativa
  main.c                              Ejemplo exclusivo de C
  math_operations/
    CMakeLists.txt
    math_operations.h                 Declaraciones C
    math_operations.c                 Implementación C
tool/ffigen.dart                      Configuración del generador de bindings
test/ffi_example_test.dart             Tests
Taskfile.yaml                         Atajos de comandos
pubspec.yaml / pubspec.lock            Dependencias y versiones fijadas
analysis_options.yaml                 Reglas de análisis
.github/workflows/ci.yaml             Comprobaciones de CI
```
