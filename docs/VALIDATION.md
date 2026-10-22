# Validation record

Validation date: **2026-10-22**. Scope: the source-checkout console example,
not Flutter integration or distributable executables.

## Environment

- Ubuntu 24.04 x64 under WSL2.
- Dart 3.13.6 stable, downloaded from the official archive and SHA-256 checked.
- GCC 13.3.0; CMake 3.28.3; libclang 18.1.3.
- Task 3.54.0, official Linux binary with release checksum verification.
- Locked direct development dependencies: ffigen 23.0.0, test 1.33.0,
  lints 6.1.0. No direct runtime package dependencies.

The Windows host had no Dart, CMake, GCC, libclang or Task on PATH.
The checks below ran in **Linux**, after installing the documented native tools.
No native Windows compatibility is implied.

## Executed checks

All commands below returned exit code 0 in a fresh **local Git clone** of
implementation commit `6384b1e`, placed inside the Linux filesystem. Before
preparation, that clone had neither `.dart_tool/` nor `native_code/build/`.
The system toolchain and the user's pub download cache were already available;
this was not a pristine-OS or offline-install test.

| Command | Observed result |
| --- | --- |
| `dart pub get --enforce-lockfile` | Locked graph installed successfully |
| `dart run tool/ffigen.dart` | Real libclang-based generation completed |
| `git diff --exit-code -- lib/generated_bindings.dart` | No drift against committed output |
| `dart format --output=none --set-exit-if-changed bin lib test tool` | Six files, zero changes |
| `dart analyze --fatal-infos` | No issues found |
| `cmake -S native_code -B native_code/build` | Configuration completed |
| `cmake --build native_code/build` | Shared library and C app built |
| `./native_code/build/app` | Printed 10 * 2 = 20 and 10 + 2 = 12 |
| `dart run bin/ffi_example.dart` | Both variants printed product 20 and sum 12 |
| `dart test` | All 34 tests passed |
| `task run` | Ordered preparation and Dart execution succeeded |
| `task check` | Formatting and analysis succeeded |
| `task test` | Ordered preparation and all 34 tests succeeded |
| `git status --porcelain` | No tracked or untracked changes after preparation/tests |

Additional C source validation, also successful in the clean clone:

```sh
gcc -std=c99 -Wall -Wextra -Werror -pedantic \
  -I native_code/math_operations -fsyntax-only \
  native_code/main.c native_code/math_operations/math_operations.c
```

The original working checkout also passed generation, C build, Dart analysis,
both examples and all 34 tests. `task execute` was additionally run from its
`native_code/` subdirectory and succeeded.

## Test coverage

- Four original operation assertions, repeated for six small input pairs:
  (5, 2), (-5, 2), (-5, -2), (0, 7), (7, 0), (0, 0).
- Agreement between both approaches for each pair.
- A missing library: absolute attempted path and build guidance.
- An invalid library: original loader diagnostic retained.
- Missing native symbols: explicit failure in both binding approaches.
- A subprocess running the real CLI from an unrelated temporary directory:
  exit code 0 and all four expected output lines.

All arithmetic stays safely inside C int limits. Overflow is not tested or
supported.

## Issues encountered and resolved

1. A temporary SDK placed in WSL's `/tmp` disappeared when that WSL environment
   stopped. It was moved to a user cache for validation; no SDK is committed.
2. A deliberately restricted command PATH omitted `ldconfig`, causing FFIGen
   discovery to fail. Restoring the standard Linux `/usr/sbin` and `/sbin`
   entries fixed generation without any deprecated configuration override.
3. CMake/Make on the Windows-mounted checkout emitted clock-skew warnings.
   Repeating the entire workflow in a Linux-filesystem clone completed without
   those warnings and left the checkout unchanged.

These environment failures are not counted as passing checks before remediation.

## Remote CI and remaining limits

`.github/workflows/ci.yaml` checks a fresh Ubuntu 24.04 checkout with pinned
Dart 3.13.6, locked dependencies, actual binding regeneration, drift detection,
formatting, analysis, native build, both examples and tests.
Actions are pinned to the verified upstream commit references.

The table above records **local execution**, not a pre-emptive claim that GitHub
Actions passed. The PR checks are the authoritative remote result.

Not verified: other operating systems or CPU architectures, Flutter packaging,
AOT/relocatable distribution, arbitrary numeric inputs, or a completely empty
pub cache. No production deployment or article publication was performed.
