import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// The wrapper on [callback] to make it await itself before running.
typedef SyncCallback = Future<void> Function(
  Future<void> Function() callback,
);

/// Create the wrapper to make callback await itself before running.
SyncCallback useSyncCallback({
  final bool? discard,
  final bool? postFrame,
  final List<Object?>? keys,
}) =>
    use(_SyncCallbackHook(postFrame: postFrame, keys: keys));

class _SyncCallbackHook extends Hook<SyncCallback> {
  const _SyncCallbackHook({
    final bool? discard,
    final bool? postFrame,
    super.keys,
  })  : discard = discard ?? true,
        postFrame = postFrame ?? false;

  final bool discard;
  final bool postFrame;

  @override
  _SyncCallbackHookState createState() => _SyncCallbackHookState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<bool>('discard', discard))
          ..add(DiagnosticsProperty<bool>('postFrame', postFrame)),
      );
}

class _SyncCallbackHookState
    extends HookState<SyncCallback, _SyncCallbackHook> {
  bool _mounted = true;
  late final StreamController<Future<void>> _callbacks;
  late final StreamSubscription<Future<void>> _callbacksSubscription;

  @override
  void initHook() {
    super.initHook();
    _callbacks = StreamController<Future<void>>();
    _callbacksSubscription =
        _callbacks.stream.listen((final Future<void> future) async {
      _callbacksSubscription.pause();
      try {
        if (hook.postFrame) {
          final Completer<void> completer = Completer<void>();
          WidgetsBinding.instance.addPostFrameCallback(
            (final _) => future.then(completer.complete),
          );
          await completer.future;
        } else {
          await future;
        }
      } finally {
        _callbacksSubscription.resume();
      }
    });
  }

  @override
  SyncCallback build(final BuildContext context) =>
      (final Future<void> Function() callback) async {
        if (_mounted && (!hook.discard || !_callbacksSubscription.isPaused)) {
          final Completer<void> completer = Completer<void>();
          _callbacks.add(callback().then(completer.complete));
          return completer.future;
        }
      };

  @override
  void dispose() {
    _mounted = false;
    unawaited(
      _callbacksSubscription.cancel().then((final _) => _callbacks.close()),
    );
    super.dispose();
  }
}
