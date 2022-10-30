import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// The wrapper on [callback] to make it await itself before running.
typedef SyncCallback = Future<void> Function(
  Future<void> Function() callback,
);

/// Create the wrapper to make callback await itself before running.
SyncCallback useSyncCallback({final List<Object?>? keys}) =>
    use(_SyncCallbackHook(keys: keys));

class _SyncCallbackHook extends Hook<SyncCallback> {
  const _SyncCallbackHook({super.keys});

  @override
  _SyncCallbackHookState createState() => _SyncCallbackHookState();
}

class _SyncCallbackHookState
    extends HookState<SyncCallback, _SyncCallbackHook> {
  bool _isLoading = false;
  bool _mounted = true;
  Future<void>? _callback;

  @override
  SyncCallback build(final BuildContext context) =>
      (final Future<void> Function() callback) async {
        if (_mounted && !_isLoading && _callback == null) {
          _isLoading = true;
          try {
            await (_callback = callback());
          } finally {
            _callback = null;
            _isLoading = false;
          }
        }
      };

  @override
  void dispose() {
    _mounted = false;
    _callback?.ignore();
    super.dispose();
  }
}
