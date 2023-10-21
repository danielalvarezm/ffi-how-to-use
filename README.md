# FFI/FFIGEN HOW TO USE EXAMPLE

This repository is an example of how to integrate a C project into your Dart/Flutter project using [ffi](https://pub.dev/packages/ffi) and [ffigen](https://pub.dev/packages/ffigen) Dart packages.

In this case, a C project has been created with a library containing a function that multiplies two numbers. This library is used in a Dart project (it would also work for Flutter) to display the result of the multiplication in the console.

## Index
* [Getting started](#getting-started)
* [Project structure](#project-structure)

<a name="getting-started"></a>
## Getting started
* Install [taskfile](https://taskfile.dev/installation/) to automate processes. If you don't want to use it, you can run the commands in the [Taskfile.yaml](https://github.com/danielalvarezm/ffi-how-to-use/blob/main/Taskfile.yaml) file manually.
* Install [ffigen](https://pub.dev/packages/ffigen#installing-llvm) dependencies.
* Install project dependencies with `dart pub get`.
* You should have everything you need to compile and run a C project. If not, install the necessary dependencies (Cmake, gcc, etc).
* Run `task generate` to generate all dependencies and bindings needed. This includes:
    *  `dart pub get`: Install dart dependencies
    * `task build`: Generate C shared library, dependencies and executable 
    * `task ffigen`: Generate dart code with ffigen from C lang
* Run `task execute` or `task run` (generate + execute) to run the example.

>💡 All task commands have to be run from the root folder of the project.

<a name="project-structure"></a>
## Project structure
```
├── /bin # Dart code interacting with native code
├── /lib # Bindings generated for native code
├── /native_code # C code
│  ├── /build # Build files, executables, shared library, etc (this folder is generated automatically if you use taskfile).
│  ├── /multiply # Example of a library
│  ├── main.c # Example of library use
│  ├── CMakeLists.txt # To build the native code
├── pubspec.yaml # Dart dependencies
├── taskfile.yml # File with different tasks to automate processes
...
```
