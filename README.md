# Dart FFI and FFIGen: a small C example

[English](#dart-ffi-and-ffigen-a-small-c-example) | [Español](#español)

A Dart **console application** calling two C functions, `multiply` and `add`,
through the same shared library:

- **Manual FFI:** handwritten native signatures and symbol lookups using
  the SDK's `dart:ffi`.
- **FFIGen:** bindings generated from the C header with `package:ffigen`.

Both approaches ultimately use Dart FFI. FFIGen generates bindings; it does not
compile or package the C library. The external `package:ffi` provides helpers
such as native allocation and string conversion, which these integer-only calls
do not need.

The example accompanied the 2023 article
[Explorando la integración de librerías nativas en Flutter mediante FFI](https://leanmind.es/es/blog/explorando-la-integracion-de-librerias-nativas-en-flutter-mediante-ffi/).
It has since been modernized: Dart 3, programmatic FFIGen configuration, explicit
library loading, reproducible preparation, expanded tests and Linux CI.
The article's old snippets are not instructions for the current checkout.

There is **no Flutter UI** here. The concepts apply to Flutter on native platforms,
but bundling libraries in a Flutter application is separate work.
This example does not support Flutter Web.

## Scope and prerequisites

The verified environment is **Linux x64, Ubuntu 24.04 under WSL2**.
Windows is only the host of that Linux environment, not a supported native target.
macOS, Windows, Android and iOS have not been implemented or tested.

| Tool | Selected version | Reason |
| --- | --- | --- |
| Dart SDK | 3.13.6 stable | Same minimum SDK, formatter and pinned CI SDK |
| FFIGen | 23.0.0 | Current programmatic generator API |
| test | 1.33.0 | Compatible current test runner |
| lints | 6.1.0 | Official recommended analysis rules |
| CMake | 3.16+ (tested: 3.28.3) | Out-of-source build with `-S`, `-B` and `--build` |
| C compiler | Tested: GCC 13.3.0 | Compiles the C shared library |
| LLVM/libclang | 18+ (tested: 18.1.3) | Required when regenerating bindings |
| Task | Optional; tested: 3.54.0 | Convenience wrapper for the same commands |

The SDK constraint intentionally starts at the tested SDK, rather than claiming
support for untested older SDKs. Dependency constraints allow compatible releases;
the committed `pubspec.lock` fixes the exact application dependency graph.
FFIGen, test and lints are all development dependencies. Unused `logger` and the
unnecessary direct `ffi` dependency have been removed. `ffi` 2.2.0 still appears
**transitively** in the locked development tools.

Install [Dart 3.13.6](https://dart.dev/get-dart/archive) and put `dart` on your PATH.
Flutter is not required. On Ubuntu 24.04, install the native tools:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends build-essential cmake libclang-18-dev
dart --version
cmake --version
gcc --version
```

## Prepare and run

Run preparation commands from the repository root:

```sh
git clone https://github.com/danielalvarezm/ffi-how-to-use.git
cd ffi-how-to-use

dart pub get --enforce-lockfile
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Expected application output (tooling may print additional build-hook messages):

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

The C-only smoke example uses the same small fixed inputs:

```sh
./native_code/build/app
```

It prints `10 * 2 = 20` and `10 + 2 = 12`. Unlike the original C example,
it no longer takes command-line operands: avoiding `atoi` keeps input parsing
and out-of-range values outside this demonstration.

### Optional Task workflow

Install [Task v3](https://taskfile.dev/docs/installation), then:

```sh
task run       # locked dependencies -> bindings -> C build -> Dart example
task test      # same preparation -> tests
task check     # format check and analysis, after dependencies are installed
```

Individual tasks remain available: `task generate`, `task ffigen`,
`task build`, and `task execute`. Preparation uses sequential task calls,
not parallel dependencies. Task resolves its working directory from the Taskfile,
so it can also be invoked from a repository subdirectory.

## How the two approaches differ

The C declarations remain simple:

```c
int multiply(int first, int second);
int add(int first, int second);
```

The manual class in `lib/manual_bindings.dart` resolves both symbols once per
instance with `lookupFunction<Int Function(Int, Int), int Function(int, int)>`.
The native `Int` models **C int**; the Dart callable uses Dart `int`.
Do not substitute `Int32` just because C int is commonly 32 bits.
A fixed-width API would instead declare `int32_t` in C and use `Int32` in Dart.

The script `tool/ffigen.dart` explicitly includes only `multiply` and `add`.
It selects `DynamicLibraryBindings(wrapperName: 'MathOperationsFFIGen')`,
rather than the generator's default `@Native` external bindings.
This keeps manual and generated calls on the same explicitly opened library,
without adding build hooks or native-asset configuration to this project.
The generated class caches symbol lookups lazily, on first use.

FFIGen's old YAML configuration is deprecated. Regenerate after changing the
header or generator script:

```sh
dart run tool/ffigen.dart
git diff -- lib/generated_bindings.dart
```

Bindings are **committed** so readers can inspect both approaches immediately.
Normal builds can use the committed file without running the generator.
Do not edit generated code by hand. CI regenerates it and rejects drift.
The lockfile is also committed because this is an executable example.
Compiled libraries and `.dart_tool/` are not committed.

### Loading and numeric limits

`loadMathLibrary()` opens the library explicitly when called.
It resolves the package's source location with `Isolate.resolvePackageUri`
and loads `native_code/build/libmathOperationsLib.so` from there, not from the
process working directory. The CLI and tests share that loader.

The loader accepts an optional `path` for another build location; an explicit
relative path is relative to the process working directory. Errors contain the
attempted absolute path, build instructions and the original loader diagnostic.
Missing symbols also fail explicitly; the CLI reports errors to stderr and exits
with status 1.

This path strategy is for running a **source checkout**. Relocatable/AOT
executables, deployment and library redistribution are not covered.
Operands and results must fit in a C int. Signed C overflow is undefined;
Dart's wider integer range does not make arbitrary values safe.

## Tests and checks

After preparing the project:

```sh
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
dart test
```

The 34 tests retain the original four operation checks across positive,
negative and zero inputs, compare both approaches, check absent/invalid libraries
and absent symbols, and run the CLI from an unrelated working directory.

These commands, both examples, regeneration without drift, and the Task workflow
were executed successfully on Ubuntu 24.04/WSL2 on **2026-10-22**, including a fresh
local clone with no build output or Dart package configuration. See
[the validation record](docs/VALIDATION.md) for details and limitations.
[GitHub Actions](.github/workflows/ci.yaml) independently runs the Linux checks
on pull requests and pushes to `main`; consult the PR checks for its actual status.

## Repository structure

```text
.github/workflows/ci.yaml             Linux checks
bin/ffi_example.dart                  Console entry point
lib/manual_bindings.dart              Handwritten FFI
lib/generated_bindings.dart           Committed FFIGen output
lib/native_library.dart               Explicit Linux source-checkout loader
native_code/
  CMakeLists.txt                      Shared library and C smoke executable
  main.c                              C-only usage example
  math_operations/
    CMakeLists.txt
    math_operations.h                 Public C declarations
    math_operations.c                 Two arithmetic functions
test/ffi_example_test.dart             Operation and loading tests
tool/ffigen.dart                      Programmatic generator configuration
docs/ARTICLE_REVISION_NOTES.md         Spanish notes for revising the article
docs/VALIDATION.md                     Executed checks and environment
analysis_options.yaml                 Recommended Dart lints
pubspec.yaml / pubspec.lock            Development tools and locked versions
Taskfile.yaml                         Optional command shortcuts
```

## Troubleshooting

- **Cannot open the .so:** run both CMake commands from the repository root.
  The default output must be `native_code/build/libmathOperationsLib.so`.
  A successful Dart dependency install does not build C.
- **Wrong architecture or invalid library:** use a Linux library built for the
  same architecture as the Dart VM. A Windows DLL cannot be loaded by Linux Dart.
  The loader includes the operating system's original error.
- **Missing symbol:** rebuild after changing the header/implementation; inspect
  exports with `nm -D native_code/build/libmathOperationsLib.so`.
  Generating a Dart declaration does not supply its C implementation.
- **libclang not found:** install `libclang-18-dev` and check
  `ldconfig -p | grep libclang`. FFIGen's Linux discovery invokes `ldconfig`,
  so keep `/sbin` or `/usr/sbin` on PATH. Installing Dart alone is insufficient.
- **Stale bindings:** rerun `dart run tool/ffigen.dart`; do not use the old
  `flutter pub run ffigen` command or restore the deprecated YAML block.
- **Paths:** build/generation commands above assume the repository root.
  Running the prepared Dart entry point by absolute path from another directory
  is tested. Moving only the Dart files or compiled executable is not supported.
- **WSL clock-skew warnings on /mnt/c:** build a clean clone inside the Linux
  filesystem. That removed the timestamp warnings during this validation.

Adding another platform would require its build/output conventions, loader,
packaging (and possibly signing/export rules), and real tests. Merely selecting
another filename extension is not verified platform support.

## References

- [Dart C interop](https://dart.dev/interop/c-interop)
- [C int and Dart FFI Int](https://api.dart.dev/dart-ffi/Int-class.html)
- [package:ffi utilities](https://pub.dev/packages/ffi)
- [FFIGen documentation](https://pub.dev/packages/ffigen)
- [CMake command-line build workflow](https://cmake.org/cmake/help/latest/manual/cmake.1.html)

## Español

### Qué demuestra este proyecto

Una aplicación de **consola Dart** llama a dos funciones C, `multiply` y `add`,
usando la misma biblioteca compartida de dos maneras:

- **FFI manual:** firmas nativas y resolución de símbolos escritas a mano con
  `dart:ffi`, que forma parte del SDK.
- **FFIGen:** bindings generados desde el header C mediante un script Dart.
  El generador no compila ni distribuye la biblioteca C.

No es una aplicación Flutter con interfaz gráfica. Los conceptos pueden
reutilizarse en Flutter nativo, pero su empaquetado queda fuera del ejemplo;
Flutter Web no está soportado. Las utilidades externas de `package:ffi` no son
necesarias para estas operaciones con enteros.

El proyecto acompañaba al
[artículo original de 2023 en Lean Mind](https://leanmind.es/es/blog/explorando-la-integracion-de-librerias-nativas-en-flutter-mediante-ffi/).
Esta modernización actualiza SDK, generación, carga, automatización y pruebas
sin cambiar las dos operaciones. Los snippets antiguos del artículo no son las
instrucciones del código actual.

### Requisitos y alcance

Se ha verificado **Linux x64**, tanto en Ubuntu 24.04 bajo WSL2 como en la CI de
Linux. Esto no implica compatibilidad nativa con Windows. macOS, Android e iOS
tampoco están implementados ni comprobados.

- [Dart 3.13.6 estable](https://dart.dev/get-dart/archive), disponible en el PATH.
  No necesitas instalar Flutter.
- CMake 3.16 o posterior y compilador C. Se probaron CMake 3.28.3 y GCC 13.3.0.
- LLVM/libclang 18 o posterior para regenerar bindings; se probó 18.1.3.
- [Task v3](https://taskfile.dev/docs/installation), opcional; se probó 3.54.0.

FFIGen 23.0.0, test 1.33.0 y lints 6.1.0 son herramientas de desarrollo.
`pubspec.lock` conserva las versiones exactas y los bindings generados también
están versionados. No hay dependencias directas de paquetes en ejecución;
`ffi` sólo permanece transitivamente entre las herramientas.

### Preparación y ejecución

En Ubuntu 24.04, instala las herramientas nativas:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends build-essential cmake libclang-18-dev
```

Después de instalar Dart, ejecuta desde la raíz del repositorio:

```sh
dart pub get --enforce-lockfile
dart run tool/ffigen.dart
cmake -S native_code -B native_code/build
cmake --build native_code/build
dart run bin/ffi_example.dart
```

Salida esperada de la aplicación, aparte de posibles mensajes de las herramientas:

```text
Multiply with ffigen: 20
Add with ffigen: 12
Multiply with ffi: 20
Add with ffi: 12
```

El ejemplo exclusivo de C se ejecuta con `./native_code/build/app` e imprime
`10 * 2 = 20` y `10 + 2 = 12`. Usa valores fijos, no argumentos de consola.

Si tienes Task, puedes utilizar el mismo flujo mediante estos atajos:

```sh
task run       # dependencias -> bindings -> compilación C -> ejemplo Dart
task test      # preparación y tests
task check     # formato y análisis, con las dependencias ya instaladas
```

### Pruebas y funcionamiento

Después de preparar el proyecto:

```sh
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
dart test
```

Hay 34 tests que cubren positivos, negativos, cero, consistencia entre enfoques,
bibliotecas ausentes o inválidas, símbolos ausentes y ejecución desde otro
directorio. El [registro de validación](docs/VALIDATION.md) detalla las
comprobaciones ejecutadas; consulta los checks del PR para el estado actual de CI.

El código manual está en `lib/manual_bindings.dart`; la configuración del
generador, en `tool/ffigen.dart`; y su salida, en `lib/generated_bindings.dart`.
Ambos enfoques usan `Int` para representar el `int` de C y comparten el cargador
explícito de `lib/native_library.dart`. No edites a mano el archivo generado:
regenera los bindings al cambiar el header o la configuración; la CI detecta
diferencias respecto al archivo versionado.

### Problemas frecuentes y límites

- **No se encuentra la biblioteca:** ejecuta ambos comandos de CMake. La salida
  predeterminada es `native_code/build/libmathOperationsLib.so`; instalar
  dependencias Dart no compila C.
- **No se encuentra libclang:** instala `libclang-18-dev` y comprueba
  `ldconfig -p | grep libclang`. Mantén `/sbin` o `/usr/sbin` en el PATH.
- **Falta un símbolo o la arquitectura no coincide:** recompila la biblioteca
  para la arquitectura de la VM Dart e inspecciona los símbolos con
  `nm -D native_code/build/libmathOperationsLib.so`.
- **Rutas:** los comandos de preparación asumen la raíz del repositorio.
  El cargador resuelve la biblioteca respecto al paquete fuente, no al directorio
  de ejecución. No se cubre distribución AOT ni de ejecutables reubicables.
- **Números:** operandos y resultados deben caber en un `int` de C. El overflow
  con signo es comportamiento indefinido; no se admiten enteros arbitrarios.

La [estructura del repositorio](#repository-structure) y los detalles técnicos
completos están en la sección inglesa. Las
[notas para revisar el artículo](docs/ARTICLE_REVISION_NOTES.md) están en español;
no modifican ni publican el artículo original.
