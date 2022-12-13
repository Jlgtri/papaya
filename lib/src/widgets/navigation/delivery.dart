import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/address.dart';
import '../../models/cart_store.dart';
import '../../models/settings.dart';
import '../../providers/api.dart';
import '../../providers/misc.dart';
import '../../routes.dart';

/// The screen used to pick current [deliveryType] or current active address.
@immutable
class DeliveryScreen extends HookConsumerWidget {
  /// The screen used to pick current [deliveryType] or current active address.
  const DeliveryScreen({this.deliveryType, super.key});

  /// The initial delivery type to show on this screen.
  final DeliveryType? deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();

    final ValueNotifier<DeliveryType> deliveryType =
        useState(this.deliveryType ?? DeliveryType.values.first);
    final ObjectRef<bool> manuallySet = useRef(false);

    final PageController pageController = usePageController(
      initialPage: DeliveryType.values.indexOf(deliveryType.value),
    );
    useMemoized(
      () => pageController.addListener(() {
        if (!manuallySet.value) {
          final DeliveryType $deliveryType = DeliveryType.values.elementAt(
            (((pageController.page ?? 0) + 1 / 2) / DeliveryType.values.length)
                .round(),
          );
          if (deliveryType.value != $deliveryType) {
            deliveryType.value = $deliveryType;
          }
        }
      }),
    );

    if (this.deliveryType == null) {
      unawaited(
        useMemoized(
          () async => syncCallback(() async {
            unawaited(
              pageController.animateToPage(
                DeliveryType.values
                    .indexOf(await ref.read(deliveryTypeProvider.future)),
                duration: const Duration(milliseconds: 333),
                curve: Curves.ease,
              ),
            );
          }),
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
            () async => navigator.pushReplacementNamed(
              (await Routes.current(container)).name,
            ),
          ),
        );
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: theme.colorScheme.surface,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
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
                        Icon(icons.arrow.left, size: 14),
                        const SizedBox(width: 12),
                        Flexible(child: Text($.delivery.back))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DeliveryTypeSwitcher(
                  deliveryType.value,
                  onChanged: (final DeliveryType $deliveryType) async {
                    manuallySet.value = true;
                    try {
                      await pageController.animateToPage(
                        DeliveryType.values
                            .indexOf(deliveryType.value = $deliveryType),
                        duration: const Duration(milliseconds: 333),
                        curve: Curves.ease,
                      );
                    } finally {
                      if (deliveryType.value == $deliveryType) {
                        manuallySet.value = false;
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ExpandablePageView(
                  controller: pageController,
                  children: const <Widget>[
                    DeliveryDeliveryLoader(
                      key: PageStorageKey<DeliveryType>(DeliveryType.delivery),
                    ),
                    DeliveryPickupLoader(
                      key: PageStorageKey<DeliveryType>(DeliveryType.pickup),
                    )
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16)
                .copyWith(bottom: 8 + mediaQuery.padding.bottom),
            child: ElevatedButton(
              onPressed: () async => syncCallback(() async {
                final bool unathorized =
                    await ref.read(skippedAuthorizationProvider.future);
                final UserAddressesModel? currentAddress =
                    await ref.read(currentAddressProvider.future);
                final UserAddressesModel? selectedAddress =
                    ref.read(AddressRadio.provider);

                /// User is Authorized.
                /// User has selected [DeliveryType.delivery].
                /// User has [selectedAddress] different from existing default.
                if (!unathorized &&
                    deliveryType.value == DeliveryType.delivery &&
                    selectedAddress?.userAddressId != null &&
                    currentAddress != selectedAddress) {
                  await ref.read(
                    defaultAddressProvider(selectedAddress!.userAddressId!)
                        .future,
                  );
                }

                /// User is Unauthorized.
                /// User has selected [DeliveryType.delivery].
                /// User has [selectedAddress] different from existing default.
                final Isar isar = await ref.read(isarProvider.future);
                if (unathorized &&
                    deliveryType.value == DeliveryType.delivery &&
                    selectedAddress != null &&
                    currentAddress != selectedAddress) {
                  await isar.writeTxn(
                    () async => isar.address.putAll(<Address>[
                      for (final Address $address
                          in await isar.address.where().findAll())
                        $address
                          ..defaultAddress =
                              $address.id == selectedAddress.addressId
                    ]),
                  );
                }

                /// [DeliveryType] is different from [Settings.deliveryType].
                final Settings settings =
                    await ref.read(settingsProvider.future);
                if (settings.deliveryType != deliveryType.value) {
                  await isar.writeTxn(
                    () => isar.settings
                        .put(settings..deliveryType = deliveryType.value),
                  );
                }
                await navigator.maybePop();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text($.delivery.done),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
      );
}

/// The callback on the [deliveryType]
typedef DeliveryTypeCallback = FutureOr<void> Function(
  DeliveryType deliveryType,
);

/// The switcher of [Settings.deliveryType] on [DeliveryScreen].
@immutable
class DeliveryTypeSwitcher extends HookConsumerWidget {
  /// The switcher of [Settings.deliveryType] on [DeliveryScreen].
  const DeliveryTypeSwitcher(this.deliveryType, {this.onChanged, super.key});

  /// The current active [DeliveryType].
  final DeliveryType deliveryType;

  /// The callback on the [deliveryType] of this switch.
  final DeliveryTypeCallback? onChanged;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return CustomAnimatedToggleSwitch<DeliveryType>(
      height: 40,
      values: DeliveryType.values,
      current: deliveryType,
      onChanged: onChanged,
      indicatorSize: Size.infinite,
      backgroundIndicatorBuilder: (final _, final __) => Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: theme.colorScheme.secondary,
        child: const SizedBox.expand(),
      ),
      wrapperBuilder: (final _, final __, final Widget child) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: theme.colorScheme.surface,
        ),
        child: child,
      ),
      iconBuilder: (final _, final __, final ___) => FractionallySizedBox(
        widthFactor: 1 / 2,
        child: Center(
          child: Text(
            (final DeliveryType deliveryType) {
              switch (deliveryType) {
                case DeliveryType.delivery:
                  return $.store.delivery;
                case DeliveryType.pickup:
                  return $.store.pickup;
              }
            }(__.value),
            style: theme.textTheme.titleMedium?.copyWith(
              color: ColorTween(
                begin: theme.colorScheme.shadow,
                end: theme.colorScheme.surface,
              ).transform(
                __.value == DeliveryType.delivery
                    ? 1 - ___.position
                    : ___.position,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(EnumProperty<DeliveryType>('deliveryType', deliveryType))
          ..add(
            DiagnosticsProperty<DeliveryTypeCallback?>(
              'onChanged',
              onChanged,
            ),
          ),
      );
}

/// The widget used to load delivery addresses.
@immutable
class DeliveryDeliveryLoader extends HookConsumerWidget {
  /// The widget used to load delivery addresses.
  const DeliveryDeliveryLoader({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<Iterable<UserAddressesModel>?> addresses =
        ref.watch(currentAddressesProvider);
    final Iterable<UserAddressesModel>? prevAddresses =
        usePrevious<Iterable<UserAddressesModel>?>(addresses.valueOrNull);
    return addresses.asData?.value != null || prevAddresses != null
        ? DeliveryDelivery(addresses.asData?.value ?? prevAddresses!)
        : Stack(
            alignment: Alignment.center,
            children: const <Widget>[
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: DeliveryDelivery(
                  Iterable<UserAddressesModel>.empty(),
                ),
              ),
              CircularProgressIndicator.adaptive(),
            ],
          );
  }
}

/// The widget used to show delivery [addresses].
@immutable
class DeliveryDelivery extends HookConsumerWidget {
  /// The widgetused  to show delivery [addresses].
  const DeliveryDelivery(this.addresses, {super.key});

  /// The addresses to show in this delivery.
  final Iterable<UserAddressesModel> addresses;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final SyncCallback syncCallback = useSyncCallback();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 24).copyWith(bottom: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Where To
              Row(
                children: <Widget>[
                  const SizedBox(width: 16),
                  IconButton(
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(40),
                      disabledBackgroundColor: theme.colorScheme.secondary,
                      disabledForegroundColor: theme.colorScheme.surface,
                    ),
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(icons.marker, size: 16),
                    ),
                    padding: const EdgeInsets.all(12),
                    onPressed: null,
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      $.delivery.whereTo,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              const SizedBox(height: 16),
              for (final UserAddressesModel address in addresses)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: AddressRadio(address),
                ),
              const SizedBox(height: 10),

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
                    () => navigator.pushNamed(Routes.map.name),
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
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(IterableProperty<UserAddressesModel>('addresses', addresses)),
      );
}

/// The widget to load current store's pickup eta.
@immutable
class DeliveryPickupLoader extends HookConsumerWidget {
  /// The widget to load current store's pickup eta.
  const DeliveryPickupLoader({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      (ref.watch(cartProvider)).when<Widget>(
        loading: () => Stack(
          alignment: Alignment.center,
          children: const <Widget>[
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: DeliveryPickup(
                StoreModel(),
                StoreEtaModel(),
              ),
            ),
            CircularProgressIndicator.adaptive(),
          ],
        ),
        data: (final List<CartStore> cart) {
          if (cart.isEmpty) {
            return const SizedBox.shrink();
          }
          final AsyncValue<StoreModel?> store =
              ref.watch(storeProvider(cart.first.id));
          final AsyncValue<StoreEtaModel?> pickupEta =
              ref.watch(storeEtaPickupProvider(cart.first.id));

          if (store.isLoading || pickupEta.isLoading) {
            return Stack(
              alignment: Alignment.center,
              children: const <Widget>[
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: DeliveryPickup(
                    StoreModel(),
                    StoreEtaModel(),
                  ),
                ),
                CircularProgressIndicator.adaptive(),
              ],
            );
          } else if (pickupEta.asData != null &&
              store.asData != null &&
              (store.value != null || cart.first.store != null)) {
            return DeliveryPickup(
              store.value ?? cart.first.store!,
              pickupEta.value,
            );
          }
          return const SizedBox.shrink();
        },
        error: (final _, final __) => const SizedBox.shrink(),
      );
}

/// The widget to show [store] pickup [eta].
@immutable
class DeliveryPickup extends HookConsumerWidget {
  /// The widget to show [store] pickup [eta].
  const DeliveryPickup(this.store, this.eta, {super.key});

  /// The store to show in pickup.
  final StoreModel store;

  /// The approximate time to pickup in this store.
  final StoreEtaModel? eta;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// Store Name
              Flexible(
                child: Row(
                  children: <Widget>[
                    IconButton(
                      style: IconButton.styleFrom(
                        fixedSize: const Size.square(40),
                        disabledBackgroundColor: theme.colorScheme.secondary,
                        disabledForegroundColor: theme.colorScheme.surface,
                      ),
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Icon(icons.marker, size: 16),
                      ),
                      padding: const EdgeInsets.all(12),
                      onPressed: null,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        store.name ?? '',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),

              /// Address
              const SizedBox(height: 16),
              Flexible(
                child: Text(
                  store.address?.displayLong ?? '',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                ),
              ),

              /// Pickup Eta
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  eta?.min != null && eta?.max != null
                      ? $.delivery.pickupTime(eta!.min!, eta!.max!)
                      : '',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<StoreModel>('store', store))
          ..add(DiagnosticsProperty<StoreEtaModel>('eta', eta)),
      );
}

/// The widget used to pick the [address].
@immutable
class AddressRadio extends HookConsumerWidget {
  /// The widget used to pick the [address].
  const AddressRadio(this.address, {super.key});

  /// The address to show in this radio.
  final UserAddressesModel address;

  /// The provider of the current selected [address].
  static final AutoDisposeStateProvider<UserAddressesModel?> provider =
      StateProvider.autoDispose<UserAddressesModel?>((final _) => null);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool? isSelected = ref.watch(
          provider.select(
            (final _) => _ == null ? null : _ == address,
          ),
        ) ??
        ref.watch(
          currentAddressProvider.select(
            (final _) => _.valueOrNull == null ? null : _.value! == address,
          ),
        );
    final bool? prevIsSelected = usePrevious<bool?>(isSelected);
    final SyncCallback syncCallback = useSyncCallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isSelected ?? prevIsSelected ?? false
              ? null
              : () async => syncCallback(
                    () async => ref.read(provider.notifier).state = address,
                  ),
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
                    child: isSelected ?? prevIsSelected ?? false
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
                      color: theme.colorScheme.shadow,
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
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserAddressesModel>('address', address)),
      );
}
