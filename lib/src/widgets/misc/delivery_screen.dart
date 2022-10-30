import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/settings.dart';
import '../../providers/api_providers.dart';
import '../../routes.dart';

class DeliveryScreen extends HookConsumerWidget {
  const DeliveryScreen({this.deliveryType, super.key});

  /// The initial delivery type to show on this screen.
  final DeliveryType? deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final AsyncValue<Iterable<UserAddressesModel>> addresses =
        ref.watch(addressesProvider);

    final SyncCallback syncCallback = useSyncCallback();
    final ValueNotifier<DeliveryType> deliveryType =
        useState(this.deliveryType ?? Settings().deliveryType);

    if (this.deliveryType == null) {
      unawaited(
        useMemoized(
          () async => syncCallback(
            () async => deliveryType.value =
                await ref.read(deliveryTypeProvider.future),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (navigator.canPop()) {
          return true;
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (final _) => syncCallback(
            () async => (await Routes.current(container))
                .pushReplacement(navigator, container),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: theme.colorScheme.surface,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leadingWidth: double.infinity,
          leading: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: TextButton(
                onPressed: () async => syncCallback(navigator.maybePop),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icons.misc.arrowLeft, size: 14),
                      const SizedBox(width: 12),
                      Flexible(child: Text($.delivery.back))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  $.delivery.title,
                  style: theme.textTheme.displayMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: deliveryType.value ==
                                    DeliveryType.delivery
                                ? null
                                : () =>
                                    deliveryType.value = DeliveryType.delivery,
                            style: TextButton.styleFrom(
                              disabledBackgroundColor:
                                  theme.colorScheme.secondary,
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                color:
                                    deliveryType.value == DeliveryType.delivery
                                        ? theme.colorScheme.surface
                                        : null,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text($.delivery.deliveryTab),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: deliveryType.value == DeliveryType.pickup
                                ? null
                                : () =>
                                    deliveryType.value = DeliveryType.pickup,
                            style: TextButton.styleFrom(
                              disabledBackgroundColor:
                                  theme.colorScheme.secondary,
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                color: deliveryType.value == DeliveryType.pickup
                                    ? theme.colorScheme.surface
                                    : null,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text($.delivery.pickupTab),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              (final DeliveryType deliveryType) {
                switch (deliveryType) {
                  case DeliveryType.delivery:
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24)
                              .copyWith(bottom: 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              /// Where To
                              Flexible(
                                child: Row(
                                  children: <Widget>[
                                    const SizedBox(width: 16),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        fixedSize: const Size.square(40),
                                        disabledBackgroundColor:
                                            theme.colorScheme.secondary,
                                        disabledForegroundColor:
                                            theme.colorScheme.surface,
                                      ),
                                      icon: Icon(icons.marker, size: 16),
                                      padding: const EdgeInsets.all(12),
                                      onPressed: null,
                                    ),
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: Text(
                                        $.delivery.whereTo,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),

                              if (addresses is AsyncData &&
                                  addresses.valueOrNull != null) ...<Widget>[
                                const SizedBox(height: 16),
                                for (final UserAddressesModel address
                                    in addresses.value!)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: AddressRadio(address),
                                  ),
                                const SizedBox(height: 10),
                              ],

                              /// Add New Address
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    textStyle: theme.textTheme.titleMedium,
                                  ),
                                  onPressed: () async => syncCallback(
                                    () => Routes.map.push(navigator, container),
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
                                          child: Text($.delivery.addAddress),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  case DeliveryType.pickup:
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[],
                      ),
                    );
                }
              }(deliveryType.value)
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
          child: ElevatedButton(
            onPressed: () async => syncCallback(navigator.maybePop),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text($.delivery.done),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
    );
  }
}

/// The widget used to pick the [address].
class AddressRadio extends HookConsumerWidget {
  /// The widget used to pick the [address].
  const AddressRadio(this.address, {super.key});

  /// The address to show in this radio.
  final UserAddressesModel address;

  /// The provider of the current selected [address].
  static final StateProvider<UserAddressesModel?> provider =
      StateProvider<UserAddressesModel?>((final _) => null);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isSelected = ref.watch(
          provider.select((final _) => _ == null ? null : _ == address),
        ) ??
        ref.watch(
          activeAddressProvider.select((final _) => _.valueOrNull == address),
        );
    final IsMounted isMounted = useIsMounted();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isSelected
              ? null
              : () => isMounted()
                  ? ref.read(provider.notifier).state = address
                  : null,
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
                              child: SizedBox.fromSize(
                                size: const Size.square(14),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    address.displayLong ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(DiagnosticsProperty<UserAddressesModel>('address', address)),
    );
  }
}
