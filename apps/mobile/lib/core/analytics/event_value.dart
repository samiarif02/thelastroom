import 'package:content/content.dart';

/// One analytics property value. The only kinds are a content id, an enum name, a whole
/// number, a decimal and a boolean (docs/rules/analytics.md).
///
/// There's deliberately no way to wrap a `String`: text a player typed, or a name or email,
/// can't become a property without a compile error. An id has to come from an [Identified]
/// content item, whose ids `validateContent` holds to snake_case. Anything else that varies
/// (a provider, a notification type, a score band) is an enum.
sealed class EventValue {
  const EventValue();

  /// A mission, follow-up, lesson or other content item, sent as its id.
  const factory EventValue.id(Identified item) = _IdValue;

  /// An enum value, sent as its Dart name (`ScoreBucket.from60` → `from60`).
  const factory EventValue.name(Enum value) = _NameValue;

  const factory EventValue.count(int value) = _IntValue;

  const factory EventValue.number(double value) = _DoubleValue;

  const factory EventValue.flag(bool value) = _BoolValue;

  /// What the analytics backend receives: a `String` (only ever an id or an enum name), an
  /// `int`, a `double` or a `bool`.
  Object get wire => switch (this) {
    _IdValue(:final item) => item.id,
    _NameValue(:final value) => value.name,
    _IntValue(:final value) => value,
    _DoubleValue(:final value) => value,
    _BoolValue(:final value) => value,
  };
}

final class _IdValue extends EventValue {
  const _IdValue(this.item);

  final Identified item;
}

final class _NameValue extends EventValue {
  const _NameValue(this.value);

  final Enum value;
}

final class _IntValue extends EventValue {
  const _IntValue(this.value);

  final int value;
}

final class _DoubleValue extends EventValue {
  const _DoubleValue(this.value);

  final double value;
}

final class _BoolValue extends EventValue {
  const _BoolValue(this.value);

  final bool value;
}
