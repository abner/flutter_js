
// Must Fix Utf8 because QuickJS need end with terminator '\0'
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

class Utf8NullTerminated extends Struct {
  
  @Uint8()
  int char;

  static Pointer<Utf8NullTerminated> toUtf8(String s) {
    final bytes = Utf8Encoder().convert(s);
    final ptr = allocate<Utf8NullTerminated>(count: bytes.length + 1);
    for (var i = 0; i < bytes.length; i++) {
      ptr.elementAt(i).ref.char = bytes[i];
    }
    // Add the terminator '\0'
    ptr.elementAt(bytes.length).ref.char = 0;
    return ptr;
  }

  static String fromUtf8(Pointer<Utf8NullTerminated> ptr) {
    final bytes = List<int>();
    var len = 0;
    while (true) {
      final char = ptr.elementAt(len++).ref.char;
      if (char == 0) break;
      bytes.add(char);
    }
    return Utf8Decoder().convert(bytes);
  }

}