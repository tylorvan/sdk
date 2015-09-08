// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unittest test of the CPS ir generated by the dart2dart compiler.
library dart_backend.sexpr2_test;

import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart';
import 'package:compiler/src/cps_ir/cps_ir_nodes_sexpr.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:expect/expect.dart';

import '../../../../pkg/analyzer2dart/test/test_helper.dart';
import '../../../../pkg/analyzer2dart/test/sexpr_data.dart';

import 'test_helper.dart';

main(List<String> args) {
  performTests(TEST_DATA, asyncTester, runTest, args);
}

runTest(TestSpec result) {
  return compilerFor(result.input).then((Compiler compiler) {
    void checkOutput(String elementName,
                     Element element,
                     String expectedOutput) {
      FunctionDefinition ir = compiler.irBuilder.getIr(element);
      if (expectedOutput == null) {
        Expect.isNull(ir, "\nInput:\n${result.input}\n"
                          "No CPS IR expected for $element");
      } else {
        Expect.isNotNull(ir, "\nInput:\n${result.input}\n"
                             "No CPS IR for $element");
        expectedOutput = expectedOutput.trim();
        String output = ir.accept(new SExpressionStringifier()).trim();
        Expect.equals(expectedOutput, output,
            "\nInput:\n${result.input}\n"
            "Expected for '$elementName':\n$expectedOutput\n"
            "Actual for '$elementName':\n$output\n");
      }
    }

    if (result.output is String) {
      checkOutput('main', compiler.mainFunction, result.output);
    } else {
      assert(result.output is Map<String, String>);
      result.output.forEach((String elementName, String output) {
        Element element;
        if (elementName.contains('.')) {
          ClassElement cls = compiler.mainApp.localLookup(
              elementName.substring(0, elementName.indexOf('.')));
          element = cls.localLookup(
              elementName.substring(elementName.indexOf('.') + 1));
        } else {
          element = compiler.mainApp.localLookup(elementName);
        }
        checkOutput(elementName, element, output);
      });
    }
  });
}