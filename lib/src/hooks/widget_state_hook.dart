import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Creates a callback on essential [State] methods of the widget.
void useWidgetState({
  final VoidCallback? initState,
  final VoidCallback? dispose,
  final VoidCallback? deactivate,
  final VoidCallback? reassemble,
  final List<Object?>? keys,
}) =>
    use(
      _WidgetStateHook(
        initState: initState,
        dispose: dispose,
        deactivate: deactivate,
        reassemble: reassemble,
        keys: keys,
      ),
    );

class _WidgetStateHook extends Hook<void> {
  const _WidgetStateHook({
    this.initState,
    this.dispose,
    this.deactivate,
    this.reassemble,
    super.keys,
  });

  final VoidCallback? initState;
  final VoidCallback? dispose;
  final VoidCallback? deactivate;
  final VoidCallback? reassemble;

  @override
  _WidgetStateHookState createState() => _WidgetStateHookState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(ObjectFlagProperty<VoidCallback?>.has('initState', initState))
        ..add(ObjectFlagProperty<VoidCallback?>.has('deactivate', deactivate))
        ..add(ObjectFlagProperty<VoidCallback?>.has('dispose', dispose))
        ..add(ObjectFlagProperty<VoidCallback?>.has('reassemble', reassemble)),
    );
  }
}

class _WidgetStateHookState extends HookState<void, _WidgetStateHook> {
  @override
  void initHook() {
    hook.initState?.call();
    super.initHook();
  }

  @override
  void build(final BuildContext context) {}

  @override
  void dispose() {
    hook.dispose?.call();
    super.dispose();
  }

  @override
  void deactivate() {
    hook.deactivate?.call();
    super.deactivate();
  }

  @override
  void reassemble() {
    hook.reassemble?.call();
    super.reassemble();
  }
}
