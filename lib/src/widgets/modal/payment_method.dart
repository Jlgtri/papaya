import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../hooks/sync_callback_hook.dart';

/// The screen used to create/edit credit card credentials.
@immutable
class PaymentMethodScreen extends HookConsumerWidget {
  /// The screen used to create/edit credit card credentials.
  const PaymentMethodScreen({super.key});

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

                  /// Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      $.profile.payment.addNew,
                      style: theme.textTheme.displayMedium,
                    ),
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
                              padding: const EdgeInsets.all(16),
                              child: const CreditCardForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// Confirm
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                            .copyWith(bottom: 7),
                    child: ElevatedButton(
                      onPressed: () async => syncCallback(navigator.maybePop),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text($.profile.payment.addNew),
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

/// The callback with String [value].
typedef StringCallback = FutureOr<void> Function(String value);

/// The widget used to fill in credit card credentials.
@immutable
class CreditCardForm extends HookConsumerWidget {
  /// The widget used to fill in credit card credentials.
  const CreditCardForm({
    this.onNumberSubmitted,
    this.onExpirationDateSubmitted,
    this.onCVCSubmitted,
    super.key,
  });

  /// The callback for the card number field.
  final StringCallback? onNumberSubmitted;

  /// The callback for the card expiry field.
  final StringCallback? onExpirationDateSubmitted;

  /// The callback for the card cvc/cvc field.
  final StringCallback? onCVCSubmitted;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final CreditCardNumberInputFormatter numberMask =
        useMemoized(CreditCardNumberInputFormatter.new);
    final GlobalKey<State<StatefulWidget>> numberKey =
        useMemoized(GlobalKey.new);
    final TextEditingController numberController = useTextEditingController();
    final FocusNode numberFocusNode = useFocusNode();
    final ValueNotifier<bool> numberHasFocus =
        useState(numberFocusNode.hasFocus);
    final ValueNotifier<bool> numberEmpty =
        useState(numberController.text.isEmpty);
    useMemoized(() {
      numberController.addListener(() {
        final bool empty = numberController.text.isEmpty;
        if (numberEmpty.value != empty) {
          numberEmpty.value = empty;
        }
      });
      numberFocusNode.addListener(() {
        numberHasFocus.value = numberFocusNode.hasFocus;
      });
    });

    final CreditCardExpirationDateFormatter expirationDateMask =
        useMemoized(CreditCardExpirationDateFormatter.new);
    final GlobalKey<State<StatefulWidget>> expirationDateKey =
        useMemoized(GlobalKey.new);
    final TextEditingController expirationDateController =
        useTextEditingController();
    final FocusNode expirationDateFocusNode = useFocusNode();
    final ValueNotifier<bool> expirationDateHasFocus =
        useState(expirationDateFocusNode.hasFocus);
    final ValueNotifier<bool> expirationDateEmpty =
        useState(expirationDateController.text.isEmpty);
    useMemoized(() {
      expirationDateController.addListener(() {
        final bool empty = expirationDateController.text.isEmpty;
        if (expirationDateEmpty.value != empty) {
          expirationDateEmpty.value = empty;
        }
      });
      expirationDateFocusNode.addListener(() {
        expirationDateHasFocus.value = expirationDateFocusNode.hasFocus;
      });
    });

    final CreditCardCvcInputFormatter cvcMask =
        useMemoized(CreditCardCvcInputFormatter.new);
    final GlobalKey<State<StatefulWidget>> cvcKey = useMemoized(GlobalKey.new);
    final TextEditingController cvcController = useTextEditingController();
    final FocusNode cvcFocusNode = useFocusNode();
    final ValueNotifier<bool> cvcHasFocus = useState(cvcFocusNode.hasFocus);
    final ValueNotifier<bool> cvcEmpty = useState(cvcController.text.isEmpty);

    useMemoized(() {
      cvcController.addListener(() {
        final bool empty = cvcController.text.isEmpty;
        if (cvcEmpty.value != empty) {
          cvcEmpty.value = empty;
        }
      });
      cvcFocusNode.addListener(() => cvcHasFocus.value = cvcFocusNode.hasFocus);
    });

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
        /// Number Title
        Text(
          $.payment.payment.creditCard.cardNumber,
          style: theme.textTheme.titleMedium,
        ),

        /// Number Field
        const SizedBox(height: 16),
        TextField(
          key: numberKey,
          controller: numberController,
          focusNode: numberFocusNode,
          onTap: () async => requestFocus(numberKey),
          onSubmitted: onNumberSubmitted,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[numberMask],
          textInputAction: TextInputAction.next,
          onEditingComplete: () async {
            expirationDateFocusNode.requestFocus();
            await requestFocus(expirationDateKey);
          },
          decoration: InputDecoration(
            hintText: 'XXXX XXXX XXXX XXXX',
            suffixIconConstraints: const BoxConstraints(),
            suffixIcon: numberHasFocus.value && !numberEmpty.value
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 2, right: 8),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      icon: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(icons.crossCircle, size: 24),
                      ),
                      onPressed: () =>
                          numberController.value = numberMask.formatEditUpdate(
                        numberController.value,
                        const TextEditingValue(
                          selection: TextSelection.collapsed(offset: 0),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),

        /// Expiration Date / cvc
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            /// Expiration Date
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Expiration Date Title
                  Text(
                    $.payment.payment.creditCard.expirationDate,
                    style: theme.textTheme.titleMedium,
                  ),

                  /// Expiration Date Field
                  const SizedBox(height: 16),
                  TextField(
                    key: expirationDateKey,
                    controller: expirationDateController,
                    focusNode: expirationDateFocusNode,
                    onTap: () async => requestFocus(expirationDateKey),
                    onSubmitted: onExpirationDateSubmitted,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[expirationDateMask],
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () async {
                      cvcFocusNode.requestFocus();
                      await requestFocus(cvcKey);
                    },
                    decoration: InputDecoration(
                      hintText: 'MM / YY',
                      suffixIconConstraints: const BoxConstraints(),
                      suffixIcon: expirationDateHasFocus.value &&
                              !expirationDateEmpty.value
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 2, right: 8),
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Icon(icons.crossCircle, size: 24),
                                ),
                                onPressed: () =>
                                    expirationDateController.value =
                                        expirationDateMask.formatEditUpdate(
                                  expirationDateController.value,
                                  const TextEditingValue(
                                    selection:
                                        TextSelection.collapsed(offset: 0),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            /// CVC
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// CVC Title
                  Text(
                    $.payment.payment.creditCard.cvc,
                    style: theme.textTheme.titleMedium,
                  ),

                  /// CVC Field
                  const SizedBox(height: 16),
                  TextField(
                    key: cvcKey,
                    controller: cvcController,
                    focusNode: cvcFocusNode,
                    onTap: () async => requestFocus(cvcKey),
                    onSubmitted: onCVCSubmitted,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[cvcMask],
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: $.payment.payment.creditCard.cvcHint,
                      suffixIconConstraints: const BoxConstraints(),
                      suffixIcon: cvcHasFocus.value && !cvcEmpty.value
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 2, right: 8),
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Icon(icons.crossCircle, size: 24),
                                ),
                                onPressed: () => cvcController.value =
                                    cvcMask.formatEditUpdate(
                                  cvcController.value,
                                  const TextEditingValue(
                                    selection:
                                        TextSelection.collapsed(offset: 0),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(
            ObjectFlagProperty<StringCallback?>.has(
              'onNumberSubmitted',
              onNumberSubmitted,
            ),
          )
          ..add(
            ObjectFlagProperty<StringCallback?>.has(
              'onExpirationDateSubmitted',
              onExpirationDateSubmitted,
            ),
          )
          ..add(
            ObjectFlagProperty<StringCallback?>.has(
              'onCVCSubmitted',
              onCVCSubmitted,
            ),
          ),
      );
}
