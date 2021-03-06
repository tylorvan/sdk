// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi Pointer subtypes.

library FfiTest;

import "package:expect/expect.dart";

import 'cstring.dart';

void main() {
  CString cs = CString.toUtf8("hello world!");

  Expect.equals("hello world!", cs.fromUtf8());

  cs.free();
}
