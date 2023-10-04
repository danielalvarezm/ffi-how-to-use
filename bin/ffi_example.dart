import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';

final path = absolute('/home/daniel/Escritorio/Leanmind/Formacion/Articulos/ffi_example/native_code/build/libmultiplyLib.so');

// Dynamic library object
final DynamicLibrary _nativeAddLib = DynamicLibrary.open(path);


final multiply = _nativeAddLib.lookupFunction('multiply');
final result = multiply(2, 3);
