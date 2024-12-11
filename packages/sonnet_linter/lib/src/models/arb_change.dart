import 'package:analyzer/dart/element/type.dart';

import 'interpolation.dart';

class ArbChange {
  const ArbChange({
    required this.string,
    required this.chosenAbbreviation,
    this.params = const [],
  });

  final String string;
  final String chosenAbbreviation;
  final List<Param> params;
}

enum KnownParamType {
  string('String'),
  integer('int'),
  ;

  const KnownParamType(this.asString);

  final String asString;
}

class ParamType {
  ParamType(this.knownType);
  final KnownParamType knownType;
}

class ArbParamType extends ParamType {
  ArbParamType(super.knownType);

  static ArbParamType? fromString(String? string) {
    switch (string?.toLowerCase()) {
      case 'string':
        return ArbParamType(KnownParamType.string);
      case 'int':
        return ArbParamType(KnownParamType.integer);
      default:
        return null;
    }
  }

  String get name => knownType.asString;
}

class DartParamType extends ParamType {
  DartParamType(super.knownType, this.dartType);

  final DartType dartType;

  static DartParamType? fromType(DartType? type) {
    // null assertion for ide analyzer
    if (type == null) return null;

    switch (type.element?.name?.toLowerCase()) {
      case 'string':
        return DartParamType(KnownParamType.string, type);
      case 'int':
        return DartParamType(KnownParamType.integer, type);
      default:
        return null;
    }
  }

  String get name => knownType.asString;
}

class Param {
  const Param({
    required this.name,
    required this.paramType,
    required this.interpolation,
  });

  final String name;
  final ParamType? paramType;
  final Interpolation interpolation;
}
