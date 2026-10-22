# Dart FFI and FFIGen

[English](#introduction) | [Español](#español)

## Introduction

This project is a practical example of how to use **FFI** in **Dart** to work with a native library. We'll learn how to write bindings by hand and how to generate them with **FFIGen**.

To compare both approaches, we'll use a small **C** library with addition and multiplication.

## Setup and run

For this project, we'll need the following tools:

- [Dart SDK 3.13.6](https://dart.dev/get-dart/archive).
- CMake 3.16 or later and a C compiler.
- LLVM/libclang 18 or later. See the [FFIGen installation instructions](https://pub.dev/packages/ffigen#requirements).

Run these commands from the repository root:

```sh
dart pub get
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Expected output:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

The generator configuration is in `tool/ffigen.dart`. Rerun it if you change the C header.
The generated bindings and `pubspec.lock` are committed.
Don't edit `lib/generated_bindings.dart` by hand, as it is generated automatically.

We recommend using [Task](https://taskfile.dev/docs/installation) to make running the project easier. `task run` performs the same setup and execution.

## Tests

The project has been tested on:
* Linux
* Windows (WSL2)

To run the tests after setup:

```sh
dart test
```

To format and analyze the code:

```sh
dart format .
dart analyze
```

With Task, we can use these commands:
* `task test`: run the tests.
* `task format`: format the code.
* `task check`: analyze the code.

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

Este proyecto es un ejemplo práctico de cómo usar **FFI** en **Dart**, para trabajar
con una biblioteca nativa. Aprenderemos a cómo escribir los bindings a mano, y cómo
generarlos también con **FFIGen**.

Para comparar ambos enfoques, usaremos un ejemplo de una pequeña biblioteca de **C**, con operaciones de suma y multiplicación.

### Configuración y ejecución

Para este proyecto son necesarias las siguientes herramientas:

- [Dart SDK 3.13.6](https://dart.dev/get-dart/archive).
- CMake 3.16 o posterior y un compilador C.
- LLVM/libclang 18 o posterior. Consulta las [instrucciones de instalación de FFIGen](https://pub.dev/packages/ffigen#requirements).

Ejecuta estos comandos desde la raíz del repositorio:

```sh
dart pub get
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Output esperado:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

La configuración del generador está en `tool/ffigen.dart`. Ejecútalo de nuevo si cambias el header C.
Los bindings generados y `pubspec.lock` están versionados.
No edites `lib/generated_bindings.dart` a mano, ya que es autogenerado.

Se recomienda usar [Task](https://taskfile.dev/docs/installation) para facilitar la ejecución. Con `task run` se realiza la misma preparación y ejecución.

### Tests

El proyecto ha sido probado en:
* Linux
* Windows (WSL2)

Para ejecutar los tests, después de la preparación:

```sh
dart test
```

Para dar formato y analizar el código:

```sh
dart format .
dart analyze
```

Con Task podríamos usar los siguientes comandos:
* `task test`: ejecutar los tests.
* `task format`: dar formato al código.
* `task check`: analizar el código.

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
