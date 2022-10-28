import 'dart:convert';

import 'package:json_converters_lite/json_converters_lite.dart';
import 'package:meta/meta.dart';

/// The custom converter to convert to [String].
@immutable
@optionalTypeArgs
class OptionalStringConverter<T extends Object?>
    implements JsonConverter<T?, String?> {
  /// The custom converter to convert to [String].
  const OptionalStringConverter(this.converter);

  /// The converter for the children.
  final JsonConverter<T?, Object?> converter;

  @override
  String? toJson(final T? value) =>
      value != null ? json.encode(converter.toJson(value)) : null;

  @override
  T? fromJson(final String? value) =>
      value is String ? converter.fromJson(json.decode(value)) : null;
}

/// The custom converter to convert to [String].
@immutable
@optionalTypeArgs
class StringConverter<T extends Object, S extends Object>
    implements JsonConverter<T, String> {
  /// The custom converter to convert to [String].
  const StringConverter(this.converter);

  /// The converter for the children.
  final JsonConverter<T, S> converter;

  @override
  String toJson(final T value) => json.encode(converter.toJson(value));

  @override
  T fromJson(final String value) => converter.fromJson(json.decode(value) as S);
}
