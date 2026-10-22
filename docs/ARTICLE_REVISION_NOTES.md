# Notas para revisar el artículo de FFI de 2023

## 1. Propósito y evidencia

Estas notas preparan una revisión posterior, no sustituyen el artículo ni lo
publican. Se ha consultado el
[original de Lean Mind](https://leanmind.es/es/blog/explorando-la-integracion-de-librerias-nativas-en-flutter-mediante-ffi/),
fechado allí el 10-11-2023, y el historial real del repositorio.

Referencias del código antiguo:
- `ff3fc76`: separación de los ejemplos FFI y FFIGen.
- `8eaa325`: incorporación de `add`.
- `e70a0b2`: extracción a clases.
- `9474448`: cuatro pruebas de operaciones.
- `f82f2bf`: base de esta modernización; cambio de README posterior al código de 2023.

No atribuir al autor motivaciones, incidencias o aprendizajes personales que no
estén documentados. La futura redacción debe preservar su voz sin inventar una
narrativa retrospectiva.

## 2. Diferencias entre el original y el código modernizado

| Antes | Ahora | Efecto en la explicación |
| --- | --- | --- |
| SDK Dart 2.19, incompatible con Dart 3 | Dart 3.13.6 como mínimo y SDK fijado en CI | Actualizar preparación y versiones |
| FFIGen 7 y YAML en pubspec | FFIGen 23, script Dart programático | Sustituir configuración y comando |
| FFIGen en dependencies | Todas las herramientas en dev_dependencies | No confundir generación con ejecución |
| ffi y logger directos sin uso | Eliminados como dependencias directas | No exigir instalar utilidades innecesarias |
| Int32 para int de C | Int en firmas nativas | Explicar el contrato ABI, no asumir ancho fijo |
| Lógica en bin y tests importando bin | CLI en bin; bindings/carga en lib | Mostrar los dos enfoques sin duplicar wrappers |
| Ruta relativa al directorio actual | Ruta relativa al paquete fuente | Explicar dónde se busca realmente la biblioteca |
| Inicializador global de biblioteca | Apertura explícita desde main/tests | Hacer visible cuándo se carga y cómo falla |
| Lookup manual por llamada | Lookup una vez por instancia | Separar resolución y uso |
| Wrapper generado NativeLibrary | Clase generada MathOperationsFFIGen | No copiar APIs antiguas de memoria |
| Header con includes innecesarios | Include guard y declaraciones solamente | Enseñar un header mínimo |
| cmake --build seguido de make | Un único cmake --build | Evitar compilación redundante |
| app C con atoi y argumentos | Smoke C con valores fijos, suma y producto | Eliminar ejemplo de entrada sin validar |
| Cuatro tests con positivos | 34 tests, negativos, cero y errores | Mostrar evidencia sin prometer aritmética ilimitada |
| Bindings ignorados y sin lockfile | Ambos versionados; CI detecta drift | Explicar reproducibilidad y revisión |

Las funciones matemáticas C mantienen su implementación original.
El cambio de `Int32` a `Int` no implica que el ejemplo anterior produjera un
resultado incorrecto en Linux x64: en esa ABI coinciden los tamaños. Corrige el
modelo expresado por la firma para que corresponda a `int` de C.

## 3. Conceptos que deben corregirse o matizarse

### dart:ffi, package:ffi y ffigen

- **`dart:ffi`** forma parte del SDK. Aporta `DynamicLibrary`, punteros,
  firmas nativas y conversión a funciones invocables desde Dart.
- **`package:ffi`** es un paquete externo de utilidades, como asignación de
  memoria y conversión de cadenas. No es necesario para sumar dos enteros.
  Sigue presente transitivamente en las herramientas de desarrollo, no como
  importación del ejemplo.
- **`ffigen`** analiza headers con libclang y genera declaraciones Dart basadas
  en FFI. Es una herramienta de desarrollo. No compila C ni distribuye la .so.

No presentar FFI y FFIGen como dos motores independientes: la diferencia es
escribir los bindings a mano o generarlos.

### Dart, Flutter y plataformas

El repositorio ejecuta una aplicación de consola Dart, no Flutter.
Flutter puede reutilizar conceptos en plataformas nativas, pero necesita su
propia estrategia de compilación/empaquetado. No extrapolar a Flutter Web.
Tampoco decir que un archivo C++ arbitrario es directamente una ABI C: una API
C++ normalmente necesita una interfaz C compatible; no se demuestra aquí.

### Tipos y límites

`int` de Dart es el tipo visible para quien llama. `Int` es el marcador nativo
que corresponde a `int` en C. `Int32` corresponde a un contrato de 32 bits,
como `int32_t`, no a una garantía general del lenguaje C.

Los operandos y resultados deben caber en el entero de C. El overflow con signo
en C es comportamiento indefinido, no una excepción gestionada por Dart.
No utilizar valores límite en snippets sin diseñar otro contrato numérico.

### Carga y resolución

Distinguir abrir una biblioteca, encontrar un símbolo y ejecutar la función.
Una biblioteca puede existir pero tener una arquitectura incorrecta o no exportar
`add`. El cargador conserva el diagnóstico original y añade instrucciones.

Matiz importante: los inicializadores de variables globales de Dart son
**perezosos**. No afirmar que el antiguo archivo ejecutaba necesariamente
`DynamicLibrary.open` al importarlo. La mejora es sustituir esa carga global
implícita por una llamada explícita y comprobable.

## 4. Fragmentos actualizados recomendados

### Contrato C

```c
#ifndef MATH_OPERATIONS_H
#define MATH_OPERATIONS_H

/* Inputs and results must fit in a C int. Signed overflow is undefined. */
int multiply(int first, int second);
int add(int first, int second);

#endif
```

### Resolución manual

Extracto de `lib/manual_bindings.dart`, dentro del constructor:

```dart
_multiply = library
    .lookupFunction<Int Function(Int, Int), int Function(int, int)>(
      'multiply',
    )
```

Explicar los dos tipos: firma ABI y firma Dart. Mostrar después cómo se conserva
la función en un campo y se reutiliza. No es un programa completo por sí solo.

### Generación programática

El archivo ejecutable completo está en `tool/ffigen.dart`:

```dart
import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final root = Platform.script.resolve('../');
  await FfiGenerator(
    input: Input(
      entryPoints: [
        root.resolve('native_code/math_operations/math_operations.h'),
      ],
    ),
    output: Output(
      dart: DartOutput(path: root.resolve('lib/generated_bindings.dart')),
      style: const DynamicLibraryBindings(wrapperName: 'MathOperationsFFIGen'),
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded =
            node.originalName == 'multiply' || node.originalName == 'add',
      ),
    ],
  ).generate();
}
```

La selección de funciones es explícita: la API moderna no incluye por defecto
todas las declaraciones. También es explícito el estilo dinámico. El estilo
por defecto actual utiliza funciones externas con `@Native`, por lo que no se
debe asumir que siempre aparecerá una clase `NativeLibrary`.

Los ejemplos actuales de FFIGen también presentan build hooks/native assets.
Son una alternativa válida, pero añadirlos aquí ocultaría la comparación de
carga explícita y ampliaría las dependencias/configuración del ejemplo.
No presentarlos como incorrectos u obsoletos: simplemente quedan fuera del alcance.

### Uso compartiendo una biblioteca

Extracto del interior de un `main` asíncrono, con las importaciones de `bin`:

```dart
final library = await loadMathLibrary();
final generated = MathOperationsFFIGen(library);
final manual = MathOperationsWithFFI(library);

print(generated.multiply(10, 2)); // 20
print(manual.multiply(10, 2)); // 20
```

Para el artículo definitivo, copiar los fragmentos del commit revisado y ejecutar
de nuevo cualquier variante editorial. No reconstruir el archivo generado a mano.

## 5. Comandos realmente verificados

Entorno: Linux x64, Ubuntu 24.04/WSL2, Dart 3.13.6, GCC 13.3.0,
CMake 3.28.3 y libclang 18.1.3. Validación realizada el 2026-10-22.
Ver el detalle y las limitaciones en [VALIDATION.md](VALIDATION.md).

Desde la raíz, también en un clon local limpio sin artefactos previos:

```sh
dart pub get --enforce-lockfile
dart run tool/ffigen.dart
git diff --exit-code -- lib/generated_bindings.dart
dart format --output=none --set-exit-if-changed bin lib test tool
dart analyze --fatal-infos
cmake -S native_code -B native_code/build
cmake --build native_code/build
./native_code/build/app
dart run bin/ffi_example.dart
dart test
```

Resultados: bindings sin drift, formato sin cambios, análisis sin incidencias,
ejemplos con 20 y 12, y 34 tests correctos.
También se han comprobado `task run`, `task check` y `task test` con Task 3.54.0.
No confundir estas ejecuciones locales con un resultado de GitHub Actions:
el estado remoto se consulta en los checks del PR.

El comando abreviado `gcc -shared ...` del artículo se sustituye por CMake:
el target SHARED gestiona las opciones de biblioteca compartida y el flujo deja
el artefacto en una ubicación conocida. No mantener `make` después de
`cmake --build`, ni exigir instalar Flutter para generar bindings Dart.

## 6. Compatibilidad y limitaciones que permanecen

- Sólo Linux x64 ha sido verificado. WSL2 sigue siendo Linux, no soporte Windows.
- Otras plataformas necesitan compilación, exportación de símbolos, carga,
  empaquetado y, cuando corresponda, firma; deben probarse antes de prometerlas.
- Las rutas predeterminadas dependen de un checkout fuente completo.
  No se ha implementado distribución de ejecutables AOT/relocatable.
- La biblioteca no se compila automáticamente al hacer `dart pub get`.
- LLVM/libclang es necesario para regenerar. Los bindings versionados permiten
  usar el código preparado sin generar, pero la biblioteca C debe compilarse.
- No se enseñan memoria nativa, strings, callbacks, concurrencia, ownership,
  lifetimes, interoperabilidad web ni tratamiento de overflow.
- No hay Flutter UI, publicación de paquetes ni despliegue.
- Un resultado correcto en operaciones pequeñas no demuestra seguridad para
  entradas arbitrarias.
- Los builds en el montaje /mnt/c emitieron avisos de desfase de reloj;
  la comprobación en un clon dentro del sistema de archivos Linux no los emitió.

## 7. Cambios que afectan directamente a la explicación de 2023

1. Sustituir la instalación obligatoria de `ffi` por una explicación del SDK
   y las utilidades opcionales.
2. Reemplazar todos los `Int32` asociados a `int` C por `Int`, explicando por qué.
3. Sustituir rutas relativas al cwd e inicializadores globales por el cargador
   explícito; no atribuir a Dart inicialización global eager.
4. Retirar el bloque YAML y `flutter pub run ffigen`; usar el script Dart.
5. Mostrar la clase generada real y su estilo de bindings seleccionado.
6. Reemplazar el flujo de compilación por los dos comandos de CMake.
7. Corregir referencias a carpetas antiguas: ahora es `math_operations`,
   y el archivo de automatización es `Taskfile.yaml`.
8. Presentar suma y multiplicación en ambos enfoques, no sólo multiplicación.
9. Separar generación, compilación, carga y llamada: ninguna sustituye a las otras.
10. Cambiar cualquier promesa multiplataforma por el alcance Linux comprobado.
11. Corregir la etiqueta de la suma en el último snippet manual del original:
    anuncia FFIGen aunque usa el binding manual.

## 8. Propuesta de estructura editorial

1. **Qué queremos conectar:** una aplicación de consola Dart y dos funciones C.
2. **El contrato:** header, implementación, tipos ABI y dominio numérico.
3. **Construir la biblioteca:** CMake, salida esperada y smoke C.
4. **FFI manual:** cargar, resolver una vez, convertir y llamar.
5. **Qué trabajo automatiza FFIGen:** script, filtro y bindings generados.
6. **Comparar sin cambiar el problema:** mismas entradas y biblioteca.
7. **Hacerlo reproducible:** lockfile, regeneración comprobada, tests y CI.
8. **Qué cambia en Flutter y otras plataformas:** conceptos reutilizables,
   empaquetado distinto y límites verificados.
9. **Cierre breve:** aprendizajes técnicos y enlace al repositorio, sin publicidad.

Mantener un tono práctico, ejemplos pequeños y separación entre hechos
comprobados y posibles ampliaciones. La modernización del código no reescribe
automáticamente la experiencia del autor de 2023.

## 9. Fuentes técnicas para la revisión

- [Dart C interop](https://dart.dev/interop/c-interop)
- [Int: tipo int de C](https://api.dart.dev/dart-ffi/Int-class.html)
- [Utilidades package:ffi](https://pub.dev/packages/ffi)
- [FFIGen: API y deprecación YAML](https://pub.dev/packages/ffigen)
- [DynamicLibraryBindings](https://pub.dev/documentation/ffigen/23.0.0/ffigen/DynamicLibraryBindings-class.html)
- [CMake: configurar y construir](https://cmake.org/cmake/help/latest/manual/cmake.1.html)
