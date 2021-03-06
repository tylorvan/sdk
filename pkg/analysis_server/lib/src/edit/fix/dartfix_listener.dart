// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show Location, SourceChange, SourceEdit, SourceFileEdit;

/// Tasks use this API to report results.
class DartFixListener {
  final AnalysisServer server;

  final List<DartFixSuggestion> suggestions = <DartFixSuggestion>[];
  final List<DartFixSuggestion> otherSuggestions = <DartFixSuggestion>[];
  final SourceChange sourceChange = new SourceChange('dartfix');

  DartFixListener(this.server);

  /// Record a source change to be sent to the client.
  void addSourceChange(
      String description, Location location, SourceChange change) {
    suggestions.add(new DartFixSuggestion(description, location: location));
    for (SourceFileEdit fileEdit in change.edits) {
      for (SourceEdit sourceEdit in fileEdit.edits) {
        sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
      }
    }
  }

  /// Record edits for a single source to be sent to the client.
  void addSourceEdits(String description, Location location, Source source,
      Iterable<SourceEdit> edits) {
    suggestions.add(new DartFixSuggestion(description, location: location));
    for (SourceEdit edit in edits) {
      sourceChange.addEdit(source.fullName, -1, edit);
    }
  }

  /// Record a source change to be sent to the client.
  void addSourceFileEdit(
      String description, Location location, SourceFileEdit fileEdit) {
    suggestions.add(new DartFixSuggestion(description, location: location));
    for (SourceEdit sourceEdit in fileEdit.edits) {
      sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
    }
  }

  /// Record a recommendation to be sent to the client.
  void addRecommendation(String description, [Location location]) {
    otherSuggestions
        .add(new DartFixSuggestion(description, location: location));
  }

  /// Return the [Location] representing the specified offset and length
  /// in the given compilation unit.
  Location locationFor(ResolvedUnitResult result, int offset, int length) {
    final locInfo = result.unit.lineInfo.getLocation(offset);
    final location = new Location(
        result.path, offset, length, locInfo.lineNumber, locInfo.columnNumber);
    return location;
  }
}
