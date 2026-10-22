# Dart FFI and FFIGen: a small C example

[English](#dart-ffi-and-ffigen-a-small-c-example) | [Español](#español)

A Dart console application calls two C functions, `multiply` and `add`, through
the same shared library:

- Manual FFI uses handwritten signatures and symbol lookups from `dart:ffi`.
- FFIGen generates those bindings from the C header.

`dart:ffi` is part of the Dart SDK. The external `package:ffi` supplies memory
and string helpers that these integer-only calls do not need. FFIGen generates
Dart bindings, not the compiled C library.

This is the example from the
[2023 Lean Mind article](https://leanmind.es/es/blog/explorando-la-integracion-de-librerias-nativas-en-flutter-mediante-ffi/),
updated for Dart 3 and FFIGen's Dart configuration API. Use the commands below
for the current version.

## Requirements and compatibility

Linux x64 is verified on Ubuntu 24.04, under WSL2 and in GitHub Actions.
Native Windows, macOS, Android and iOS are not implemented or tested.
This is not a Flutter application. Flutter native packaging and Flutter Web are
outside its scope.

| Tool | Version |
| --- | --- |
| Dart SDK | 3.13.6 |
| CMake | 3.16 or later |
| C compiler | GCC on Linux |
| LLVM/libclang | 18 or later, for binding generation |
| Task | v3, optional |

Install [Dart 3.13.6](https://dart.dev/get-dart/archive) and put `dart` on your PATH.
Flutter is not required. On Ubuntu 24.04, install the native tools:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends build-essential cmake libclang-18-dev
```

`dart pub get` installs the development tools: FFIGen 23.0.0, test 1.33.0 and
lints 6.1.0. The committed `pubspec.lock` fixes the dependency versions.
There are no direct runtime package dependencies.

## Prepare and run

From a clone of this repository, run these commands at its root:

```sh
dart pub get --enforce-lockfile
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Expected application output, apart from any tooling messages:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

The C-only example uses fixed operands, 10 and 2. Run it with:

```sh
./native_code/build/app
```

It prints `10 * 2 = 20` and `10 + 2 = 12`.

### Using Task

If you have [Task v3](https://taskfile.dev/docs/installation) installed:

```sh
task run       # Install dependencies, generate bindings, build C and run Dart
task test      # Prepare the project and run tests
task check     # Check formatting and analysis after installing dependencies
```

Individual tasks are `task generate`, `task ffigen`, `task build` and
`task execute`. Task runs preparation in order and resolves paths from its
Taskfile, including when invoked from a repository subdirectory.

## Tests

After preparing the project:

```sh
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
dart test
```

The 34 tests cover positive, negative and zero inputs, agreement between the
bindings, missing or invalid libraries, missing symbols and CLI execution from
another working directory.

[GitHub Actions](.github/workflows/ci.yaml) runs dependency installation,
binding regeneration, formatting, analysis, the native build, both examples
and tests on Linux. Check the PR or Actions run for its current result.

## Bindings and library loading

Manual bindings are in `lib/manual_bindings.dart`. The native `Int` type maps
to C `int`, while the Dart callable uses Dart `int`. Each manual symbol lookup
is cached per instance.

`tool/ffigen.dart` selects `multiply` and `add` and generates the
`MathOperationsFFIGen` class using `DynamicLibraryBindings`. Both approaches
receive the same opened library. The generated class caches lookups on first use.

Bindings are committed so they can be inspected and used without regeneration.
Do not edit `lib/generated_bindings.dart` by hand. After changing the header or
generator script, run:

```sh
dart run tool/ffigen.dart
git diff -- lib/generated_bindings.dart
```

CI regenerates the file and checks for differences. CMake must still compile
the native library, even when the committed bindings are used.

`loadMathLibrary()` resolves `native_code/build/libmathOperationsLib.so`
relative to the source package, not the process working directory.
Its optional `path` argument selects another build location. An explicitly
provided relative path is relative to the process working directory.
Load errors report the attempted absolute path and the original loader error.
The CLI reports errors to stderr and exits with status 1.

## Limitations and troubleshooting

- Operands and results must fit in a C int. Signed C overflow is undefined.
- The loader expects a source checkout. AOT or relocatable executable
  distribution is not implemented.
- A successful `dart pub get` does not compile C. If the library is missing,
  run both CMake commands and check for
  `native_code/build/libmathOperationsLib.so`.
- If libclang is missing, install `libclang-18-dev` and check
  `ldconfig -p | grep libclang`. FFIGen invokes `ldconfig` during discovery,
  so keep `/sbin` or `/usr/sbin` on PATH.
- Use a Linux library built for the Dart VM's architecture. A Windows DLL
  cannot be loaded by Linux Dart.
- For missing symbols, rebuild and inspect
  `nm -D native_code/build/libmathOperationsLib.so`. Generating bindings
  does not supply a C implementation.
- Preparation commands assume the repository root. The prepared entry point
  can be run by absolute path from another directory.
- If a WSL build under `/mnt/c` reports clock-skew warnings, use a clone
  inside the Linux filesystem.

## Repository structure

```text
.github/workflows/ci.yaml             Linux checks
bin/ffi_example.dart                  Console entry point
lib/manual_bindings.dart              Handwritten FFI
lib/generated_bindings.dart           Committed FFIGen output
lib/native_library.dart               Linux source-checkout loader
native_code/
  CMakeLists.txt                      Native build
  main.c                              C-only example
  math_operations/
    CMakeLists.txt
    math_operations.h                 C declarations
    math_operations.c                 Arithmetic functions
test/ffi_example_test.dart             Operation and loading tests
tool/ffigen.dart                      Generator configuration
analysis_options.yaml                 Dart lints
pubspec.yaml / pubspec.lock            Dependencies and locked versions
Taskfile.yaml                         Command shortcuts
```

Further reading: [Dart C interop](https://dart.dev/interop/c-interop),
[C int in Dart FFI](https://api.dart.dev/dart-ffi/Int-class.html),
[FFIGen](https://pub.dev/packages/ffigen) and
[CMake commands](https://cmake.org/cmake/help/latest/manual/cmake.1.html).

## Español

### Qué hace el ejemplo

Una aplicación de consola Dart llama a `multiply` y `add` de una biblioteca C.
Compara bindings escritos a mano con `dart:ffi` y bindings generados por FFIGen.

`dart:ffi` forma parte del SDK. Las utilidades de `package:ffi` no son necesarias
para estas operaciones con enteros. FFIGen genera código Dart, pero no compila
la biblioteca C. El proyecto es el ejemplo del
[artículo de Lean Mind de 2023](https://leanmind.es/es/blog/explorando-la-integracion-de-librerias-nativas-en-flutter-mediante-ffi/),
actualizado para Dart 3 y la configuración Dart de FFIGen.

### Requisitos y compatibilidad

Se ha verificado Linux x64 en Ubuntu 24.04, bajo WSL2 y en GitHub Actions.
No se ha implementado ni probado soporte nativo para Windows, macOS, Android
o iOS. No hay una aplicación Flutter. El empaquetado para Flutter nativo y
Flutter Web quedan fuera del ejemplo.

Necesitas [Dart 3.13.6](https://dart.dev/get-dart/archive) en el PATH, CMake 3.16
o posterior, GCC y libclang 18 o posterior para generar bindings.
[Task v3](https://taskfile.dev/docs/installation) es opcional. No necesitas Flutter.

En Ubuntu 24.04, instala las herramientas nativas:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends build-essential cmake libclang-18-dev
```

FFIGen 23.0.0, test 1.33.0 y lints 6.1.0 se instalan como herramientas de
desarrollo. `pubspec.lock` conserva las versiones exactas. No hay dependencias
directas de paquetes en ejecución.

### Preparación y ejecución

Desde la raíz de un clon del repositorio:

```sh
dart pub get --enforce-lockfile
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Salida esperada de la aplicación, aparte de los mensajes de las herramientas:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

El ejemplo C se ejecuta con `./native_code/build/app`. Usa los valores fijos
10 y 2, e imprime `10 * 2 = 20` y `10 + 2 = 12`.

Con Task, los mismos pasos se pueden ejecutar así:

```sh
task run       # Instala dependencias, genera bindings, compila C y ejecuta Dart
task test      # Prepara el proyecto y ejecuta los tests
task check     # Comprueba formato y análisis con las dependencias instaladas
```

### Pruebas

Después de preparar el proyecto:

```sh
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
dart test
```

Los 34 tests cubren positivos, negativos, cero, consistencia entre bindings,
bibliotecas ausentes o inválidas, símbolos ausentes y ejecución desde otro
directorio. La [CI Linux](.github/workflows/ci.yaml) comprueba la instalación,
generación, formato, análisis, compilación, ejemplos y tests.
El resultado actual se consulta en el PR o en GitHub Actions.

### Bindings y carga de la biblioteca

El código manual está en `lib/manual_bindings.dart`. Usa `Int` para representar
el `int` de C y resuelve cada símbolo una vez por instancia.
`tool/ffigen.dart` genera `lib/generated_bindings.dart`, cuya clase
`MathOperationsFFIGen` recibe la misma biblioteca y resuelve los símbolos en
su primer uso.

Los bindings están versionados. No edites el archivo generado a mano.
Si cambias el header o la configuración, ejecuta:

```sh
dart run tool/ffigen.dart
git diff -- lib/generated_bindings.dart
```

La CI comprueba que la generación coincide con el archivo versionado.
Usarlo sin regenerar no evita tener que compilar la biblioteca con CMake.

El cargador de `lib/native_library.dart` busca
`native_code/build/libmathOperationsLib.so` respecto al paquete fuente.
Su argumento opcional `path` permite elegir otra ubicación. Si se proporciona
una ruta relativa, se resuelve respecto al directorio de ejecución.
Los errores de carga incluyen la ruta absoluta y el diagnóstico original.
La consola escribe los errores en stderr y termina con código 1.

### Limitaciones y problemas frecuentes

- Los operandos y resultados deben caber en un `int` de C. El overflow con
  signo es comportamiento indefinido.
- El cargador necesita un checkout fuente. No se implementa distribución AOT
  ni de ejecutables reubicables.
- Instalar dependencias Dart no compila C. Si falta la biblioteca, ejecuta
  ambos comandos de CMake y busca `native_code/build/libmathOperationsLib.so`.
- Si falta libclang, instala `libclang-18-dev` y comprueba
  `ldconfig -p | grep libclang`. Mantén `/sbin` o `/usr/sbin` en el PATH.
- La biblioteca debe ser de Linux y de la arquitectura de la VM Dart.
  Si faltan símbolos, recompila e inspecciona
  `nm -D native_code/build/libmathOperationsLib.so`.
- Los comandos de preparación asumen la raíz del repositorio. El punto de
  entrada preparado se puede ejecutar por ruta absoluta desde otro directorio.
- Si WSL muestra avisos de desfase de reloj al compilar bajo `/mnt/c`,
  utiliza un clon dentro del sistema de archivos Linux.

La [estructura de archivos](#repository-structure) aparece en la sección inglesa.
