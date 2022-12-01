import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../providers/api.dart';
import '../../routes.dart';
import '../payment.dart';
import 'payment_method.dart';

/// The widget used to input tips amount into [PaymentScreen.tipsProvider].
@immutable
class PaymentTipForm extends HookConsumerWidget {
  /// The widget used to input tips amount into [PaymentScreen.tipsProvider].
  const PaymentTipForm({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final double tips = ref.watch(PaymentScreen.tipsProvider);

    final GlobalKey<State<StatefulWidget>> customTipKey =
        useMemoized(GlobalKey.new);
    final TextEditingController customTipController =
        useTextEditingController();
    final FocusNode customTipFocusNode = useFocusNode();
    final ValueNotifier<String> customTip = useState(customTipController.text);
    final ValueNotifier<bool> customTipHasFocus =
        useState(customTipFocusNode.hasFocus);
    useMemoized(
      () => customTipController
          .addListener(() => customTip.value = customTipController.text),
    );
    useMemoized(
      () => customTipFocusNode.addListener(
        () => customTipHasFocus.value = customTipFocusNode.hasFocus,
      ),
    );
    final RegExp customTipFilteringRegExp = useMemoized(
      () => RegExp(
        r'^([1-9]{1}[0-9]{0,}(\.[0-9]{0,2})?|0(\.[0-9]{0,2})?|\.[0-9]{1,2})$',
      ),
    );

    Future<void> requestFocus(final GlobalKey key) async {
      await for (final bool state in KeyboardVisibilityController().onChange) {
        if (state) {
          break;
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
        /// Quick Tip Title
        Text(
          $.payment.payment.quickTip,
          style: theme.textTheme.titleMedium,
        ),

        /// Quick Tip Buttons
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            for (int index = 1; index < 5; index++) ...<Widget>[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: tips == index * 5
                        ? theme.colorScheme.surface
                        : theme.colorScheme.shadow,
                    backgroundColor: tips == index * 5
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                    ),
                  ),
                  onPressed: () {
                    if (tips == index * 5) {
                      ref
                        ..invalidate(PaymentScreen.tipsProvider)
                        ..invalidate(PaymentScreen.customTipsProvider);
                    } else {
                      customTipController.value = TextEditingValue.empty;
                      customTipFocusNode.unfocus();
                      (ref.read(PaymentScreen.tipsProvider.notifier)).state =
                          index * 5;
                      ref.invalidate(PaymentScreen.customTipsProvider);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(r'$' + (index * 5).toString()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ]
          ]..removeLast(),
        ),

        /// Custom Tip Title
        const SizedBox(height: 16),
        Text(
          $.payment.payment.customTip,
          style: theme.textTheme.titleMedium,
        ),

        /// Custom Tip Field
        const SizedBox(height: 16),
        TextField(
          key: customTipKey,
          controller: customTipController,
          focusNode: customTipFocusNode,
          onTap: () async => requestFocus(customTipKey),
          onChanged: (final _) => ref.invalidate(PaymentScreen.tipsProvider),
          onSubmitted: (final String value) {
            ref.read(PaymentScreen.customTipsProvider.notifier).state = true;
            ref.read(PaymentScreen.tipsProvider.notifier).state =
                double.tryParse(value) ?? 0;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              maxWidth: 40,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                r'$',
                style: theme.inputDecorationTheme.hintStyle
                    ?.copyWith(color: const Color(0xff374957)),
              ),
            ),
            suffixIcon: customTipHasFocus.value
                ? Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 2),
                    child: IconButton(
                      style: IconButton.styleFrom(padding: EdgeInsets.zero),
                      icon: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(icons.crossCircle, size: 24),
                      ),
                      onPressed: () {
                        customTipController.value = TextEditingValue.empty;
                        customTipFocusNode.unfocus();
                        if (ref.read(PaymentScreen.customTipsProvider)) {
                          ref
                            ..invalidate(PaymentScreen.tipsProvider)
                            ..invalidate(
                              PaymentScreen.customTipsProvider,
                            );
                        }
                      },
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 46,
              maxWidth: 46,
            ),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(
              customTipFilteringRegExp,
              replacementString: customTip.value,
            ),
            LengthLimitingTextInputFormatter(10)
          ],
          keyboardType: TextInputType.number,
        )
      ],
    );
  }
}

@immutable
class PaymentMethodForm extends HookConsumerWidget {
  const PaymentMethodForm({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);
    final Iterable<CreditCardModel> creditCards = ref.watch(
      creditCardsProvider.select(
        (final _) => _.valueOrNull ?? const Iterable<CreditCardModel>.empty(),
      ),
    );

    final SyncCallback syncCallback = useSyncCallback();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Payment Method Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            $.payment.payment.paymentMethod,
            style: theme.textTheme.titleMedium,
          ),
        ),

        /// Apple Pay
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(0),
              foregroundColor: theme.colorScheme.onBackground,
              backgroundColor: theme.colorScheme.surface,
            ),
            onPressed: () => ref
                .read(PaymentScreen.paymentMethodProvider.notifier)
                .state = PaymentMethod.applePay,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icons.ios, size: 24),
                  const SizedBox(width: 8),
                  Text($.payment.payment.applePay),
                ],
              ),
            ),
          ),
        ),

        /// Google Pay
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(0),
              foregroundColor: theme.colorScheme.onBackground,
              backgroundColor: theme.colorScheme.surface,
            ),
            onPressed: () => ref
                .read(PaymentScreen.paymentMethodProvider.notifier)
                .state = PaymentMethod.googlePay,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(assets.google, width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text($.payment.payment.googlePay),
                ],
              ),
            ),
          ),
        ),

        if (creditCards.isEmpty) ...<Widget>[
          /// Credit Card Title
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              $.payment.payment.creditCard.addTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.shadow,
              ),
            ),
          ),

          /// Credit Card Form
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CreditCardForm(),
          ),
          const SizedBox(height: 6),
        ] else ...<Widget>[
          /// Select Credit Card Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Text(
              $.payment.payment.creditCard.selectTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),

          /// Credit Cards
          for (final CreditCardModel card in creditCards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: CreditCardRadio(
                card,
                isSelected: true,
                onPressed: () {},
              ),
            ),

          /// Add Payment Method
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: theme.textTheme.titleMedium,
              ),
              onPressed: () async => syncCallback(
                () => rootNavigator.pushNamed(Routes.paymentMethod.name),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icons.plusCircle),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text($.payment.payment.creditCard.addCard),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}



/// The widget used to pick the credit [card].
@immutable
class CreditCardRadio extends HookConsumerWidget {
  /// The widget used to pick the credit [card].
  const CreditCardRadio(
    this.card, {
    required this.isSelected,
    this.onPressed,
    super.key,
  });

  /// The card credentials to show in this radio.
  final CreditCardModel card;

  /// If this radio is selected.
  final bool isSelected;

  /// The callback on this radio.
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return TextButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xffA3A3A7),
                ),
              ),
              child: SizedBox.fromSize(
                size: const Size.square(24),
                child: isSelected
                    ? Align(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.fromSize(size: const Size.square(14)),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                $.payment.payment.creditCard
                    .title(card.card?.brand ?? '', card.card?.last4 ?? ''),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.shadow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<Object?>('card', card))
          ..add(DiagnosticsProperty<bool>('isSelected', isSelected))
          ..add(DiagnosticsProperty<VoidCallback?>('onPressed', onPressed)),
      );
}
