// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Iterable<int> foo() sync* {
  yield 1;
  yield* [2, 3];
}

class Class {
  Iterable<int> bar() sync* {
    yield 1;
    yield* [2, 3];
  }

  static Iterable<int> baz() sync* {
    yield 1;
    yield* [2, 3];
  }
}

main() {
  Iterable<int> qux() sync* {
    yield 1;
    yield* [2, 3];
  }

  foo().forEach(print);
  new Class().bar().forEach(print);
  Class.baz().forEach(print);
  qux().forEach(print);
}
