// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/services/available_declarations.dart';

/// Compute which suggestion sets should be included into completion inside
/// the given [resolvedUnit] of a file.  Depending on the file path, it might
/// include different sets, e.g. inside the `lib/` directory of a `Pub` package
/// only regular dependencies can be referenced, but `test/` can reference
/// both regular and "dev" dependencies.
List<protocol.IncludedSuggestionSet> computeIncludedSetList(
  DeclarationsTracker tracker,
  ResolvedUnitResult resolvedUnit,
) {
  var analysisContext = resolvedUnit.session.analysisContext;
  var context = tracker.getContext(analysisContext);
  if (context == null) return const [];

  var librariesObject = context.getLibraries(resolvedUnit.path);
  var includedSetList = <protocol.IncludedSuggestionSet>[];

  var importedUriSet = resolvedUnit.libraryElement.importedLibraries
      .map((importedLibrary) => importedLibrary.source.uri)
      .toSet();

  void includeLibrary(
    Library library,
    int importedRelevance,
    int deprecatedRelevance,
    int otherwiseRelevance,
  ) {
    int relevance;
    if (importedUriSet.contains(library.uri)) {
      relevance = importedRelevance;
    } else if (library.isDeprecated) {
      relevance = deprecatedRelevance;
    } else {
      relevance = otherwiseRelevance;
    }

    includedSetList.add(
      protocol.IncludedSuggestionSet(library.id, relevance),
    );
  }

  for (var library in librariesObject.context) {
    includeLibrary(library, 8, 2, 5);
  }

  for (var library in librariesObject.dependencies) {
    includeLibrary(library, 7, 1, 4);
  }

  for (var library in librariesObject.sdk) {
    includeLibrary(library, 6, 0, 3);
  }

  return includedSetList;
}

/// Convert the [LibraryChange] into the corresponding protocol notification.
protocol.Notification createCompletionAvailableSuggestionsNotification(
  LibraryChange change,
) {
  return protocol.CompletionAvailableSuggestionsParams(
    changedLibraries: change.changed.map((library) {
      return protocol.AvailableSuggestionSet(
        library.id,
        library.uriStr,
        library.declarations.map((declaration) {
          return _protocolAvailableSuggestion(declaration);
        }).toList(),
      );
    }).toList(),
    removedLibraries: change.removed,
  ).toNotification();
}

protocol.AvailableSuggestion _protocolAvailableSuggestion(
    Declaration declaration) {
  var label = declaration.name;
  if (declaration.kind == DeclarationKind.ENUM_CONSTANT) {
    label = '${declaration.name2}.${declaration.name}';
  }

  return protocol.AvailableSuggestion(
    label,
    _protocolElement(declaration),
    docComplete: declaration.docComplete,
    docSummary: declaration.docSummary,
    parameterNames: declaration.parameterNames,
    parameterTypes: declaration.parameterTypes,
    requiredParameterCount: declaration.requiredParameterCount,
    relevanceTags: declaration.relevanceTags,
  );
}

protocol.Element _protocolElement(Declaration declaration) {
  return protocol.Element(
    _protocolElementKind(declaration.kind),
    declaration.name,
    _protocolElementFlags(declaration),
    location: protocol.Location(
      declaration.locationPath,
      declaration.locationOffset,
      0, // length
      declaration.locationStartLine,
      declaration.locationStartColumn,
    ),
    parameters: declaration.parameters,
    returnType: declaration.returnType,
    typeParameters: declaration.typeParameters,
  );
}

int _protocolElementFlags(Declaration declaration) {
  return protocol.Element.makeFlags(
    isAbstract: declaration.isAbstract,
    isConst: declaration.isConst,
    isFinal: declaration.isFinal,
    isDeprecated: declaration.isDeprecated,
  );
}

protocol.ElementKind _protocolElementKind(DeclarationKind kind) {
  switch (kind) {
    case DeclarationKind.CLASS:
      return protocol.ElementKind.CLASS;
    case DeclarationKind.CLASS_TYPE_ALIAS:
      return protocol.ElementKind.CLASS_TYPE_ALIAS;
    case DeclarationKind.ENUM:
      return protocol.ElementKind.ENUM;
    case DeclarationKind.ENUM_CONSTANT:
      return protocol.ElementKind.ENUM_CONSTANT;
    case DeclarationKind.FUNCTION:
      return protocol.ElementKind.FUNCTION;
    case DeclarationKind.FUNCTION_TYPE_ALIAS:
      return protocol.ElementKind.FUNCTION_TYPE_ALIAS;
    case DeclarationKind.GETTER:
      return protocol.ElementKind.GETTER;
    case DeclarationKind.MIXIN:
      return protocol.ElementKind.MIXIN;
    case DeclarationKind.SETTER:
      return protocol.ElementKind.SETTER;
    case DeclarationKind.VARIABLE:
      return protocol.ElementKind.TOP_LEVEL_VARIABLE;
  }
  return protocol.ElementKind.UNKNOWN;
}

class CompletionLibrariesWorker implements SchedulerWorker {
  final DeclarationsTracker tracker;

  CompletionLibrariesWorker(this.tracker);

  @override
  AnalysisDriverPriority get workPriority {
    if (tracker.hasWork) {
      return AnalysisDriverPriority.priority;
    } else {
      return AnalysisDriverPriority.nothing;
    }
  }

  @override
  Future<void> performWork() async {
    tracker.doWork();
  }
}
