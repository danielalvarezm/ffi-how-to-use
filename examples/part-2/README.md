# Dart FFI and FFIGen, Part 2

[English](#introduction) | [Español](#español)

## Introduction

We'll use one example to learn how to pass data between **Dart** and **C**. We start with a temperature measurement: a label and a value.
Then we'll pass a batch to C and get back its count, minimum, maximum and mean.
We'll get the same result using memory allocated by Dart or by C.
Finally, we'll split the measurements into two batches and accumulate them in a session. C notifies Dart each time it accepts a batch.

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
Summary (Dart memory): count=2, min=20.0, max=24.0, mean=22.0
Summary (C memory): count=2, min=20.0, max=24.0, mean=22.0
Batch accepted: count=1, total=1
Batch accepted: count=1, total=2
Session summary: count=2, min=20.0, max=24.0, mean=22.0
```

FFIGen may warn that it can't find the definition of `measurement_session`. That's expected: the header declares the type but keeps its layout private to C.

## Tests

After setup, run `dart test` and `dart analyze`.

## Structure and memory

- `bin/` runs the demo. `lib/` contains the Dart API and the generated bindings.
- `native_code/` contains the C library. `tool/` generates the bindings and `test/` checks the Dart-to-C calls.
- Dart uses an arena to allocate the struct and its NUL-terminated UTF-8 label. C borrows the label, and Dart copies it back to a string before the arena releases both allocations.
- For a batch, Dart allocates a contiguous array, the labels and the output struct in the same arena. C writes to the output without keeping any pointers. Dart copies the result before releasing the arena. An empty batch returns an error.
- In the second version, C allocates the output. Dart checks the status and pointer, copies the result and calls `summary_free` from the same library. An empty batch and an allocation failure have different statuses.
- C allocates the session and stores only the running totals. Dart owns each temporary batch and the snapshot buffer. Call `close()` on the Dart session to release the C handle.
- Dart creates and closes a callback for each call that needs one. C calls it on the same thread after accepting the batch and doesn't store it. Don't use or close that session from its callback. If the callback throws, Dart reports the error when C returns and the batch still counts.

## Español

### Introducción

Vamos a usar un solo ejemplo para aprender a pasar datos entre **Dart** y **C**. Empezamos con una medición de temperatura: una etiqueta y un valor.
Después pasamos un lote a C y recuperamos la cantidad, el mínimo, el máximo y la media.
Obtenemos el mismo resultado con memoria reservada por Dart o por C.
Por último, repartimos las mediciones en dos lotes y los acumulamos en una sesión. C avisa a Dart cada vez que acepta un lote.

### Configuración y ejecución

Necesitamos Dart 3.13.6, CMake 3.16 o posterior, un compilador de C y LLVM/libclang 18 o posterior. Desde esta carpeta, en Linux o WSL2, sigue los [comandos de configuración y ejecución](#setup-and-run). En esa sección también está la salida esperada.

FFIGen puede avisar de que no encuentra la definición de `measurement_session`. Es normal: el header declara el tipo, pero solo C conoce su estructura interna.

### Tests

Después de la configuración, ejecuta `dart test` y `dart analyze`.

### Estructura y memoria

- `bin/` ejecuta la demo. `lib/` contiene la API de Dart y los bindings generados.
- `native_code/` contiene la biblioteca de C. `tool/` genera los bindings y `test/` comprueba las llamadas de Dart a C.
- Dart usa un `Arena` para reservar la estructura y su etiqueta UTF-8 terminada en NUL. C toma prestada la etiqueta y Dart la copia a un string antes de liberar ambas reservas.
- Para el lote, Dart reserva el array contiguo, las etiquetas y la estructura de salida juntos. C escribe el resultado sin guardar punteros. Dart copia el resultado antes de liberar la memoria. Si el lote está vacío, C devuelve un error.
- En la segunda versión, C reserva la salida. Dart comprueba el estado y el puntero, copia el resultado y llama a `summary_free` de la misma biblioteca. Un lote vacío y un fallo de reserva tienen estados distintos.
- C reserva la sesión y guarda solo los valores acumulados. Dart se encarga de la memoria de cada lote y del búfer para consultar el resumen. Llama a `close()` en la sesión de Dart para liberar el puntero de C.
- Dart crea y cierra el callback en cada llamada que lo necesita. C lo ejecuta en el mismo hilo tras aceptar el lote y no lo guarda. No uses ni cierres esa sesión desde su callback. Si el callback lanza un error, Dart lo comunica cuando C devuelve el control y el lote sigue contando.
