# Dart FFI and FFIGen, Part 2

[English](#introduction) | [Español](#español)

## Introduction

We'll use one example to learn how to pass data between **Dart** and **C**. We start with a temperature measurement: a label and a value.

## Setup and run

Use Dart 3.13.6, CMake 3.16 or later, a C compiler and LLVM/libclang 18 or later. Run the commands below from this directory in Linux or WSL2.

```sh
dart pub get
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/measurements.dart
```

Expected output:

```text
Label read by C: Outdoor temperature
Label read by C: Café temperature
```

## Tests

After setup, run `dart test` and `dart analyze`.

## Structure and memory

- `bin/` runs the demo. `lib/` contains the Dart API and the generated bindings.
- `native_code/` contains the C library. `tool/` generates the bindings and `test/` checks the Dart-to-C calls.
- Dart uses an arena to allocate the struct and its NUL-terminated UTF-8 label. C borrows the label, and Dart copies it back to a string before the arena releases both allocations.

## Español

### Introducción

Vamos a usar un solo ejemplo para aprender a pasar datos entre **Dart** y **C**. Empezamos con una medición de temperatura: una etiqueta y un valor.

### Configuración y ejecución

Necesitamos Dart 3.13.6, CMake 3.16 o posterior, un compilador de C y LLVM/libclang 18 o posterior. Desde esta carpeta, en Linux o WSL2, sigue los [comandos de configuración y ejecución](#setup-and-run). En esa sección también está la salida esperada.

### Tests

Después de la configuración, ejecuta `dart test` y `dart analyze`.

### Estructura y memoria

- `bin/` ejecuta la demo. `lib/` contiene la API de Dart y los bindings generados.
- `native_code/` contiene la biblioteca de C. `tool/` genera los bindings y `test/` comprueba las llamadas de Dart a C.
- Dart usa un arena para reservar la estructura y su etiqueta UTF-8 terminada en NUL. C toma prestada la etiqueta y Dart la copia a un string antes de que el arena libere ambas reservas.
