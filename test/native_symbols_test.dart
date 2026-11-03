import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A symbol missing from the native library only fails at runtime on a device,
/// inside `DynamicLibrary.lookup`, so these names are checked against the source.
void main() {
  final bindings = File('lib/src/native_bindings.dart').readAsStringSync();
  final header = File('src/image_edit.h').readAsStringSync();
  final implementation = File('src/image_edit.cpp').readAsStringSync();
  final lookedUpSymbols = RegExp(r"\.lookup<[^']*'(\w+)'")
      .allMatches(bindings)
      .map((match) => match.group(1)!)
      .toSet();

  test('finds the lookups, so the checks below are not vacuous', () {
    expect(lookedUpSymbols, contains('image_edit_blur'));
    expect(lookedUpSymbols, contains('image_edit_free_buffer'));
  });

  test('every symbol looked up from Dart is declared and implemented', () {
    for (final symbol in lookedUpSymbols) {
      final declaration = RegExp('\\b$symbol\\s*\\(');
      expect(header, matches(declaration), reason: '$symbol not in the header');
      expect(implementation, matches(declaration),
          reason: '$symbol not in the implementation');
    }
  });

  test('every symbol looked up from Dart has the library prefix', () {
    for (final symbol in lookedUpSymbols) {
      expect(symbol, startsWith('image_edit_'));
    }
  });

  test('stb is compiled as internal to the library', () {
    expect(implementation, contains('#define STB_IMAGE_STATIC'));
    expect(implementation, contains('#define STB_IMAGE_WRITE_STATIC'));
  });
}
