import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../routes.dart';
import '../payment.dart';

/// The screen used to create/edit credit card credentials.
@immutable
class PaymentNoteScreen extends HookConsumerWidget {
  /// The screen used to create/edit credit card credentials.
  const PaymentNoteScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: SafeArea(
        child: KeyboardDismissOnTap(
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Padding(
              padding: mediaQuery.viewInsets.copyWith(top: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  /// Grab Widget
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: theme.colorScheme.onSurface,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(4),
                        child: const SizedBox(height: 4, width: 36),
                      ),
                    ),
                  ),

                  /// Title / Clear
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      /// Title
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            $.payment.note.title,
                            style: theme.textTheme.displayMedium,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(40),
                            foregroundColor: theme.colorScheme.outline,
                            padding: const EdgeInsets.all(8),
                            shape: const CircleBorder(),
                          ),
                          icon: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Icon(icons.thrash, size: 24),
                          ),
                          onPressed: () async => syncCallback(
                            () => navigator
                                .pushNamed(Routes.paymentNoteClear.name),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Input Form
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        child: ColoredBox(
                          color: theme.colorScheme.surfaceTint,
                          child: KeyboardVisibilityBuilder(
                            builder: (final _, final bool isVisible) =>
                                SingleChildScrollView(
                              physics: !isVisible
                                  ? const NeverScrollableScrollPhysics()
                                  : null,
                              child: const PaymentNoteForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The form used to input a note on [PaymentNoteScreen].
@immutable
class PaymentNoteForm extends HookConsumerWidget {
  /// The form used to input a note on [PaymentNoteScreen].
  const PaymentNoteForm({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();

    final GlobalKey<State<StatefulWidget>> noteKey = useMemoized(GlobalKey.new);
    final TextEditingController noteController =
        useTextEditingController(text: ref.read(PaymentScreen.noteProvider));

    Future<void> requestFocus(final GlobalKey key) async {
      final KeyboardVisibilityController controller =
          KeyboardVisibilityController();
      if (!controller.isVisible) {
        await for (final bool state in controller.onChange) {
          if (state) {
            break;
          }
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((final _) async {
        if (key.currentContext != null) {
          await Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 150),
            alignment: 1 / 2,
          );
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Text(
            $.payment.note.description,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: TextField(
            maxLines: 10,
            minLines: 10,
            key: noteKey,
            controller: noteController,
            onTap: () async => requestFocus(noteKey),
            keyboardType: TextInputType.multiline,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(180),
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 16,
              ),
            ),
          ),
        ),

        /// Divider
        const SizedBox(height: 24),
        Divider(height: 1, color: theme.colorScheme.outline),

        /// Deny / Approve
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: <Widget>[
              /// Deny
              Expanded(
                child: OutlinedButton(
                  onPressed: () async => syncCallback(navigator.maybePop),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text($.payment.note.deny),
                  ),
                ),
              ),

              /// Approve
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async => syncCallback(() async {
                    ref
                        .read(
                          PaymentScreen.noteProvider.notifier,
                        )
                        .state = noteController.text;
                    await navigator.maybePop();
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text($.payment.note.approve),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The screen used to clear a note on [PaymentScreen].
@immutable
class PaymentNoteClearScreen extends HookConsumerWidget {
  /// The screen used to clear a note on [PaymentScreen].
  const PaymentNoteClearScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title / Clear
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              $.alert.noteClear.title,
                              style: theme.textTheme.displaySmall,
                              textAlign: TextAlign.start,
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              fixedSize: const Size.square(30),
                              foregroundColor: theme.colorScheme.outline,
                              padding: const EdgeInsets.all(6),
                              shape: const CircleBorder(),
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Icon(icons.cross, size: 16),
                            ),
                            onPressed: () async =>
                                syncCallback(navigator.maybePop),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

                      /// Body
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          $.alert.noteClear.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Actions
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: <Widget>[
                            /// Deny
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.shadow,
                                  backgroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () async =>
                                    syncCallback(navigator.maybePop),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.noteClear.deny),
                                ),
                              ),
                            ),

                            /// Approve
                            const SizedBox(width: 24),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () async => syncCallback(() async {
                                  ref.invalidate(PaymentScreen.noteProvider);
                                  await navigator.maybePop();
                                  await navigator.maybePop();
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.noteClear.approve),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
