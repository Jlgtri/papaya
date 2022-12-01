import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Create the wrapper to make callback await itself before running.
T? useNotNull<T extends Object?>(final T value) => use(_NotNullHook<T>(value));

class _NotNullHook<T extends Object?> extends Hook<T?> {
  const _NotNullHook(this.value);

  /// The value to use in this hook.
  final T value;

  @override
  _NotNullHookState<T> createState() => _NotNullHookState<T>();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<T>('value', value)),
      );
}

class _NotNullHookState<T extends Object?>
    extends HookState<T?, _NotNullHook<T>> {
  T? _previous;

  @override
  void didUpdateHook(final _NotNullHook<T> old) =>
      _previous = old.value ?? _previous;

  @override
  T? build(final BuildContext context) => hook.value ?? _previous;

  @override
  String get debugLabel => 'useNotNull';

  @override
  Object? get debugValue => _previous;
}
