// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:patapata_core/patapata_annotation.dart';
import 'package:patapata_core/patapata_interface.dart';
import 'package:source_gen/source_gen.dart';

const String providerModelName = 'ProviderModel';
const String providerModelVariableName = 'ProviderModelVariable';

const _filterChecker = TypeChecker.fromRuntime(RepositoryField);
const _idChecker = TypeChecker.fromRuntime(RepositoryId);

typedef FormattedFieldRecord = ({
  String returnType,
  String sourceName,
  String getterName,
  String? comment
});

Builder repositoryBuilderFactory(BuilderOptions options) {
  return SharedPartBuilder([RepositoryBuilder()], 'sets');
}

class RepositoryBuilder extends GeneratorForAnnotation<RepositoryClass> {
  bool contains(ClassElement element, String target) {
    return element.interfaces.where((e) => e.element.name == target).isNotEmpty;
  }

  bool find(Element element, String target) {
    if (element is! ClassElement) {
      return element.name == target;
    }

    final tResult = contains(element, target);
    if (tResult) {
      return true;
    }

    final tSuper = element.supertype?.element as ClassElement?;
    if (tSuper == null) {
      return false;
    }

    return find(tSuper, target);
  }

  void checkClassFormat(ClassElement element) {
    final tErrors = <String>[];

    if (element.isPublic) {
      tErrors.add('${element.name} must be private class.');
    }

    if (!find(element, ProviderModelInterface.className)) {
      tErrors.add('${element.name} must be $providerModelName.');
    }

    if (tErrors.isNotEmpty) {
      throw InvalidGenerationSourceError(
        tErrors.join('\n'),
        element: element,
      );
    }
  }

  Iterable<FormattedFieldRecord> formatField(
    Set<FieldElement> fields,
  ) {
    return fields.map<FormattedFieldRecord?>((e) {
      final tInterfaceType = e.getter?.returnType;
      if (tInterfaceType is! InterfaceType ||
          tInterfaceType.typeArguments.length != 1) {
        return null;
      }

      return (
        returnType: tInterfaceType.typeArguments.first.toString(),
        sourceName: e.name,
        getterName: e.name.replaceAll('_', ''),
        comment: e.documentationComment,
      );
    }).nonNulls;
  }

  String formatParameter(ParameterElement parameter) {
    final tType = parameter.type.toString();
    final tName = parameter.name;
    final tRequired = parameter.isRequired;

    return '${tRequired ? 'required' : ''} $tType $tName';
  }

  @override
  Stream<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async* {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '${(RepositoryClass).toString()} cannot be assigned to anything other '
        'than a class.',
        element: element,
      );
    }

    checkClassFormat(element);

    final tSets = annotation
        .read('sets')
        .setValue
        .map((e) => e.toTypeValue()?.element?.name)
        .nonNulls;
    final tProviderModelFields = <FieldElement>{};
    final tCorrespondenceMap = {
      for (var e in tSets) e: <FieldElement>{},
    };
    final tErrors = <String>[];
    FieldElement? tIdInfo;

    for (final tAccessors in element.fields) {
      if (_idChecker.firstAnnotationOf(tAccessors) != null) {
        if (tIdInfo != null) {
          tErrors.add(
            '${element.name} cannot have multiple ${(RepositoryId)}.',
          );
          continue;
        }

        tIdInfo = tAccessors;
        continue;
      }

      final tFilterField = _filterChecker.firstAnnotationOf(tAccessors);
      if (tFilterField == null) {
        continue;
      }

      if (tAccessors.type is! InterfaceType ||
          !find((tAccessors.type as InterfaceType).element,
              ProviderModelVariableInterface.className)) {
        tErrors.add(
          '${element.name}.${tAccessors.name} must be '
          '$providerModelVariableName.',
        );
        continue;
      }

      if (!tAccessors.isPrivate) {
        tErrors.add(
          '${element.name}.${tAccessors.name} must be private field.',
        );
        continue;
      }

      tProviderModelFields.add(tAccessors);

      final tTargetSets = tFilterField
          .getField('sets')
          ?.toSetValue()
          ?.map((e) => e.toTypeValue()?.element?.name)
          .nonNulls;
      if (tTargetSets == null) {
        tErrors.add('${element.name}.${tAccessors.name} \'sets\' is null.');
        continue;
      }

      final tErrorSets = tTargetSets.where((e) => !tSets.contains(e));
      if (tErrorSets.isNotEmpty) {
        tErrors.add(
          '${element.name}.${tAccessors.name} -> [${tTargetSets.join(', ')}] '
          'is not defined by ${(RepositoryField).toString()} \'sets\'.',
        );
      }

      for (final tSet in tTargetSets) {
        tCorrespondenceMap[tSet]?.add(tAccessors);
      }
    }

    if (tIdInfo == null) {
      tErrors.add('${element.name} must have a ${(RepositoryId)}.');
    } else {
      for (final c in element.constructors) {
        if (c.isGenerative && c.name.isEmpty) {
          if (c.parameters.length != 1 ||
              c.parameters.single.name != tIdInfo.name ||
              !c.parameters.single.isRequired) {
            tErrors.add(
              'Generative constructor must always accept only ID.'
              'If class generation requires processing for initialization, '
              'consider writing a Named constructor.',
            );
          }

          continue;
        }

        if (!c.parameters.any((e) => e.name == tIdInfo!.name && e.isRequired)) {
          tErrors.add(
            '${c.name} constructor must receive the ID.',
          );
        }
      }
    }

    if (tErrors.isNotEmpty) {
      throw InvalidGenerationSourceError(
        tErrors.join('\n'),
        element: element,
      );
    }

    if (tCorrespondenceMap.isEmpty) {
      throw InvalidGenerationSourceError(
        'There is no match between the defined '
        '\'set\' and the specified \'set\'.',
        element: element,
      );
    }

    yield '// ignore_for_file: override_on_non_overriding_member';

    for (final e in tCorrespondenceMap.entries) {
      yield _generateFilterExtension(tIdInfo!, element.name, e.key, e.value);
    }

    yield _generateExtendClass(
      element,
      (tIdInfo!.type as InterfaceType).toString(),
      tIdInfo.name,
      tProviderModelFields,
      tCorrespondenceMap,
    );
  }

  String _generateFilterExtension(
    FieldElement idInfo,
    String baseName,
    String setName,
    Set<FieldElement> fields,
  ) {
    final tFormattedFields = formatField(fields);
    final tModelName = baseName.replaceAll('_', '');

    return '''
    extension RepositoryExtension$setName on $setName {
    ${idInfo.type} get ${idInfo.name} => (this as $tModelName).${idInfo.name};
      ${tFormattedFields.map((e) => '''
        ${e.comment ?? ''}
        ${e.returnType} get ${e.getterName} => (this as $tModelName).${e.getterName};
      ''').join('\n')}
    }
    ''';
  }

  String _generateExtendClass(
    ClassElement classElement,
    String idType,
    String idName,
    Set<FieldElement> fields,
    Map<String, Set<FieldElement>> filters,
  ) {
    final tBaseName = classElement.name;
    final tModelName = tBaseName.replaceAll('_', '');
    final tFormattedFields = formatField(fields);
    late final String tClassGenerateString;

    final fGenerateCacheDuration = () {
      if (classElement.interfaces
          .where((e) => e.element.name == (RepositoryModelCache).toString())
          .isEmpty) {
        return '''
        @override
        Duration? get repositoryCacheDuration => const Duration(seconds: 300);
        ''';
      }

      return '';
    };

    final tConstructorsString = classElement.constructors.map((c) {
      if (c.name.isEmpty) {
        if (c.parameters.single.isNamed) {
          tClassGenerateString = '$tModelName($idName: id)';
          return '$tModelName({required super.$idName,});';
        }

        tClassGenerateString = '$tModelName(id)';
        return '$tModelName(super.$idName);';
      }

      final tPositionalParameters = <String>[];
      final tNamedParameters = <String>[];
      final tOptionalParameters = <String>[];

      for (final e in c.parameters) {
        final tName = e.name;
        final tRequired = e.isRequired ? 'required' : '';

        if (e.isRequiredPositional) {
          tPositionalParameters.add('super.$tName');
          continue;
        }

        if (e.isNamed) {
          tNamedParameters.add('$tRequired super.$tName');
          continue;
        }

        if (e.isOptionalPositional) {
          tOptionalParameters.add('super.$tName');
          continue;
        }
      }

      if (tNamedParameters.isNotEmpty && tOptionalParameters.isNotEmpty) {
        throw InvalidGenerationSourceError(
          'The constructor cannot have both named and optional parameters.',
          element: classElement,
        );
      }

      var tParameters = tPositionalParameters.join(', ');

      if (tNamedParameters.isNotEmpty) {
        if (tParameters.isNotEmpty) {
          tParameters += ',';
        }

        tParameters += '{${tNamedParameters.join(', ')},}';
      }

      if (tOptionalParameters.isNotEmpty) {
        if (tParameters.isNotEmpty) {
          tParameters += ',';
        }

        tParameters += '[${tOptionalParameters.join(', ')},]';
      }

      return '$tModelName.${c.name}($tParameters) : super.${c.name}();';
    }).join('\n\n');

    return '''
    ${classElement.documentationComment ?? ''}
    class $tModelName extends $tBaseName with RepositoryModel<$tModelName, $idType>, ${filters.keys.join(', ')} {
      $tConstructorsString
      
      ${tFormattedFields.map((e) => '''
        @override
        ${e.returnType} get ${e.getterName} => ${e.sourceName}.unsafeValue;
      ''').join('\n')}

      @override
      $tModelName repositoryDefaultFactory($idType id) => $tClassGenerateString;

      @override
      Widget providersBuilder(Widget child) {
        return MultiProvider(
          providers: [
            InheritedProvider<$tModelName>.value(
              value: this,
              startListening: (c, v) {
                v.addListener(c.markNeedsNotifyDependents);
                return () => v.removeListener(c.markNeedsNotifyDependents);
              },
            ),
          ${filters.keys.map((e) => '''
            InheritedProvider<$e>.value(
              value: this,
              startListening: (c, v) {
                final tInstance = (v as $tModelName);
                tInstance.addListener(c.markNeedsNotifyDependents);
                return () => tInstance.removeListener(c.markNeedsNotifyDependents);
              },
            ),
            ''').join()}
          ],
          child: child,
        );
      }

      @override
      $idType get repositoryId => $idName;

      ${fGenerateCacheDuration()}

      @override
      Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
            $tModelName: {${tFormattedFields.map((e) => e.sourceName).join(', ')}},
            ${filters.entries.map((e) => '''
            ${e.key}: {${e.value.map((e) => e.name).join(', ')}},
            ''').join()}
          };
    }
    ''';
  }
}
