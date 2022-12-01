import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../generated/models.g.dart';
import '../hooks/not_null_hook.dart';
import '../hooks/sync_callback_hook.dart';
import '../models/cart_store.dart';
import '../models/settings.dart';
import '../providers/api.dart';
import '../providers/misc.dart';
import '../routes.dart';
import 'misc/delivery.dart';
import 'modal/payment_tip.dart';
import 'modal/profile_edit.dart';
import 'navigation/cart.dart';
import 'navigation/profile.dart';

/// The current step on the [PaymentScreen].
enum PaymentStep {
  /// Means user is providing his personal data.
  customer,

  /// Means user is picking order's delivery type.
  deliveryType,

  /// Means user is choosing his payment method.
  payment;
}

/// The picked payment method on the [PaymentScreen].
enum PaymentMethod {
  /// Means user wants to pay using Apple Pay.
  applePay,

  /// Means user wants to pay using Google Pay.
  googlePay,

  /// Means user wants to pay using Credit Card.
  creditCard;
}

/// The screen used to process a payment.
@immutable
class PaymentScreen extends HookConsumerWidget {
  /// The screen used to process a payment.
  const PaymentScreen({super.key});

  /// The provider of the current modal route opened value.
  static final AutoDisposeStateProvider<bool> modalOpenedProvider =
      StateProvider.autoDispose<bool>((final _) => false);

  /// The provider of the current tips value on this screen.
  static final AutoDisposeStateProvider<String> noteProvider =
      StateProvider.autoDispose<String>((final _) => '');

  /// The provider of the current tips value on this screen.
  static final AutoDisposeStateProvider<double> tipsProvider =
      StateProvider.autoDispose<double>((final _) => 0);

  /// The provider of the current custom tips value on this screen.
  static final AutoDisposeStateProvider<bool> customTipsProvider =
      StateProvider.autoDispose<bool>((final _) => false);

  /// The provider of the current [PaymentMethod] value on this screen.
  static final AutoDisposeStateProvider<PaymentMethod?> paymentMethodProvider =
      StateProvider.autoDispose<PaymentMethod?>((final _) => null);

  /// The provider of the current discount code value on this screen.
  static final AutoDisposeStateProvider<String?> discountCodeProvider =
      StateProvider.autoDispose<String?>((final _) => null);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final bool modalOpened = ref.watch(modalOpenedProvider);
    final double tips = ref.watch(tipsProvider);
    final String? discountCode = ref.watch(discountCodeProvider);
    final DeliveryType? initialDeliveryType =
        ref.watch(deliveryTypeProvider.select((final _) => _.valueOrNull));
    final AsyncValue<List<CartStore>> cart = ref.watch(cartProvider);
    final AsyncValue<UserProfileModel?> profile =
        ref.watch(profileProvider(null));
    final bool? unauthorized = ref
        .watch(skippedAuthorizationProvider.select((final _) => _.valueOrNull));
    final AsyncValue<StoreEtaModel?>? deliveryEta =
        cart.valueOrNull?.firstOrNull == null
            ? null
            : ref.watch(storeEtaDeliveryProvider(cart.value!.first.id));
    final AsyncValue<StoreEtaModel?>? pickupEta =
        cart.valueOrNull?.firstOrNull == null
            ? null
            : ref.watch(storeEtaPickupProvider(cart.value!.first.id));
    final OrderCalculateModel? calculate = useNotNull<OrderCalculateModel?>(
      initialDeliveryType != null && cart.valueOrNull != null
          ? ref.watch(
              orderCalculateProvider(
                OrderCalculateRequestModel(
                  deliveryTip: (tips * 100).toInt(),
                  handoffTypeId: initialDeliveryType.index + 1,
                  cartItems: <OrderCalculateRequestCartItemsModel>[
                    for (final CartStore store in cart.value!)
                      for (final CartStoreProduct product in store.products)
                        OrderCalculateRequestCartItemsModel(
                          productId: product.id,
                          quantity: product.amount,
                        )
                  ],
                ),
              ).select((final _) => _.valueOrNull),
            )
          : null,
    );

    // final AsyncValue<OrderCalculateModel?>? calculateDiscount =
    //     initialDeliveryType != null &&
    //             cart.valueOrNull != null &&
    //             (discountCode?.isNotEmpty ?? false)
    //         ? ref.watch(
    //             orderCalculateProvider(
    //               OrderCalculateRequestModel(
    //                 discountCode: discountCode,
    //                 deliveryTip: (tips * 100).toInt(),
    //                 handoffTypeId: initialDeliveryType.index + 1,
    //                 cartItems: <OrderCalculateRequestCartItemsModel>[
    //                   for (final CartStore store in cart.value!)
    //                     for (final CartStoreProduct product in store.products)
    //                       OrderCalculateRequestCartItemsModel(
    //                         productId: product.id,
    //                         quantity: product.amount,
    //                       )
    //                 ],
    //               ),
    //             ),
    //           )
    //         : null;
    final ValueNotifier<PaymentStep> paymentStep =
        useState(PaymentStep.values.first);
    final SyncCallback syncCallback = useSyncCallback();
    final ObjectRef<UserProfileModel?> customer = useRef(null);
    final ObjectRef<DeliveryType?> deliveryType = useRef(null);
    final ObjectRef<UserAddressesModel?> address = useRef(null);

    Future<void> payment() async {
      final CartStore? cartStore = cart.valueOrNull?.firstOrNull;
      if (cartStore != null && initialDeliveryType != null) {
        final PaymentIntentModel? paymentIntent = await ref.read(
          paymentIntentProvider(
            PaymentIntentRequestModel(
              handoffTypeId: initialDeliveryType.index + 1,
              discountCode: discountCode,
              deliveryTip: (tips * 100).toInt(),
              store: PaymentIntentRequestStoreModel(
                id: cartStore.id,
                name: cartStore.store?.name,
              ),
              cartItems: <PaymentIntentRequestCartItemsModel>[
                for (final CartStore store in cart.value!)
                  for (final CartStoreProduct product in store.products)
                    PaymentIntentRequestCartItemsModel(
                      productId: product.id,
                      quantity: product.amount,
                    ),
              ],
            ),
          ).future,
        );
        print(paymentIntent);
        if (paymentIntent != null && paymentIntent.paymentIntent != null) {
          final String note = ref.read(noteProvider);
          final order = await ref.read(
            orderProvider(
              OrderRequestModel(
                saveCard: true,
                memo: note.isEmpty ? null : note,
                paymentIntentId: paymentIntent.paymentIntent!.id,
                paymentMethodId: paymentIntent.paymentIntent!.id,
                address: address.value,
                handoffTypeId: initialDeliveryType.index + 1,
                discountCode: discountCode,
                deliveryTip: (tips * 100).toInt(),
                store: OrderRequestStoreModel(id: cartStore.id),
                cartItems: <OrderRequestCartItemsModel>[
                  for (final CartStore store in cart.value!)
                    for (final CartStoreProduct product in store.products)
                      OrderRequestCartItemsModel(
                        productId: product.id,
                        quantity: product.amount,
                      ),
                ],
              ),
            ).future,
          );
          print(order);
        }
      }
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
          statusBarColor:
              modalOpened ? Colors.transparent : theme.colorScheme.surface,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor:
              modalOpened ? Colors.transparent : theme.colorScheme.surface,
        ),
        child: KeyboardDismissOnTap(
          child: Material(
            child: CustomScrollView(
              slivers: <Widget>[
                /// Back Button
                SliverAppBar(
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: modalOpened
                        ? Colors.transparent
                        : theme.colorScheme.surface,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                    systemNavigationBarIconBrightness: Brightness.dark,
                    systemNavigationBarColor: modalOpened
                        ? Colors.transparent
                        : theme.colorScheme.surface,
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
                              Flexible(child: Text($.payment.back))
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Title
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      $.payment.title,
                      style: theme.textTheme.displayMedium,
                      maxLines: 1,
                    ),
                  ),
                ),

                /// Cart Information
                if (initialDeliveryType == null ||
                    calculate == null ||
                    unauthorized == null ||
                    profile.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else
                  SliverSafeArea(
                    top: false,
                    minimum: mediaQuery.viewInsets.copyWith(top: 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          /// Payment Summary
                          ColoredBox(
                            color: const Color(0xffF6F6F6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  for (final CartStore store in cart.value!)
                                    PaymentStoreLoader(store),
                                  PaymentSummary(calculate),
                                ],
                              ),
                            ),
                          ),

                          /// Customer Information
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: PaymentCustomerInformation(
                              profile.valueOrNull,
                              authorize: unauthorized,
                              focused: customer.value == null &&
                                      paymentStep.value != PaymentStep.customer
                                  ? null
                                  : paymentStep.value == PaymentStep.customer,
                              onPressed: (final UserProfileModel $customer) {
                                if (paymentStep.value != PaymentStep.customer) {
                                  customer.value = null;
                                  paymentStep.value = PaymentStep.customer;
                                } else {
                                  customer.value = $customer;
                                  paymentStep.value = PaymentStep.deliveryType;
                                }
                              },
                            ),
                          ),

                          /// Order Details
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: PaymentOrderDetails(
                              initialDeliveryType,
                              deliveryEta?.valueOrNull,
                              pickupEta?.valueOrNull,
                              focused: customer.value == null ||
                                      deliveryType.value == null &&
                                          paymentStep.value !=
                                              PaymentStep.deliveryType
                                  ? null
                                  : paymentStep.value ==
                                      PaymentStep.deliveryType,
                              onPressed: (
                                final DeliveryType $deliveryType,
                                final UserAddressesModel? $address,
                              ) {
                                if (paymentStep.value !=
                                    PaymentStep.deliveryType) {
                                  paymentStep.value = PaymentStep.deliveryType;
                                } else {
                                  deliveryType.value = $deliveryType;
                                  address.value = $address;
                                  paymentStep.value = PaymentStep.payment;
                                }
                              },
                            ),
                          ),

                          /// Payment
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: PaymentPayment(
                              calculate,
                              focused: customer.value == null ||
                                      deliveryType.value == null ||
                                      paymentStep.value != PaymentStep.payment
                                  ? null
                                  : paymentStep.value == PaymentStep.payment,
                              onPressed: () async => syncCallback(() async {
                                if (paymentStep.value != PaymentStep.payment) {
                                  paymentStep.value = PaymentStep.payment;
                                } else {
                                  await payment();
                                }
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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
}

/// The widget that shows a loader for [PaymentStore].
@immutable
class PaymentStoreLoader extends HookConsumerWidget {
  /// The widget that shows a loader for [PaymentStore].
  const PaymentStoreLoader(this.store, {super.key});

  /// The store with the products to show in this widget.
  final CartStore store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<DeliveryType> deliveryType =
        ref.watch(deliveryTypeProvider);
    if (deliveryType.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    } else if (deliveryType.asData?.value == null) {
      return const SizedBox.shrink();
    }

    final AsyncValue<StoreModel?>? $store = store.store?.address == null
        ? ref.watch(storeProvider(store.id))
        : null;

    final AsyncValue<StoreEtaModel?> storeEta;
    switch (deliveryType.value!) {
      case DeliveryType.delivery:
        storeEta = ref.watch(storeEtaDeliveryProvider(store.id));
        break;
      case DeliveryType.pickup:
        storeEta = ref.watch(storeEtaPickupProvider(store.id));
        break;
    }
    return storeEta.isLoading || ($store?.isLoading ?? false)
        ? const Center(child: CircularProgressIndicator.adaptive())
        : PaymentStore(
            store..store = $store?.valueOrNull ?? store.store,
            storeEta.value,
            deliveryType: deliveryType.value!,
          );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties..add(DiagnosticsProperty<CartStore>('store', store)),
    );
  }
}

/// The widget that shows information about a [store] with [eta].
@immutable
class PaymentStore extends HookConsumerWidget {
  /// The widget that shows information about a [store] with [eta].
  const PaymentStore(
    this.store,
    this.eta, {
    required this.deliveryType,
    super.key,
  });

  /// The store with the products to show in this widget.
  final CartStore store;

  /// The eta for the [deliveryType].
  final StoreEtaModel? eta;

  /// The delivery type used to show this information.
  final DeliveryType deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    assert(store.store != null, 'The store property must not be null.');
    assert(
      eta == null || (eta!.min != null && eta!.max != null),
      'Eta values must not be null.',
    );
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        /// Store Name
        if (store.store?.name?.isNotEmpty ?? false)
          Text(
            store.store!.name!,
            style: theme.textTheme.headlineSmall,
          ),

        /// Estimated Time Icon / Estimated Time
        if (eta != null) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                icons.car,
                color: theme.colorScheme.secondary,
                size: 16,
              ),
              const SizedBox(width: 8),

              /// Estimated Time
              Text(
                (final DeliveryType deliveryType) {
                  switch (deliveryType) {
                    case DeliveryType.delivery:
                      return $.delivery.deliveryTime(eta!.min!, eta!.max!);
                    case DeliveryType.pickup:
                      return $.delivery.pickupTime(eta!.min!, eta!.max!);
                  }
                }(deliveryType),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],

        /// Store Address
        if (store.store?.address?.displayLong?.isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            store.store!.address!.displayLong!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.shadow,
            ),
          )
        ],

        /// Estimated Time Abs.
        if (eta != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            $.payment.storeDeliveryTime(
              DateFormat('hh:mm a')
                  .format(DateTime.now().add(Duration(minutes: eta!.max!))),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.shadow,
            ),
          ),
        ],

        /// Products
        const SizedBox(height: 24),
        Material(
          clipBehavior: Clip.hardEdge,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CartStoreProducts(store, counterActive: false),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<CartStore>('store', store))
          ..add(DiagnosticsProperty<StoreEtaModel>('eta', eta))
          ..add(EnumProperty<DeliveryType>('deliveryType', deliveryType)),
      );
}

/// The widget used to show a summary on [PaymentScreen].
@immutable
class PaymentSummary extends HookConsumerWidget {
  /// The widget used to show a summary on [PaymentScreen].
  const PaymentSummary(this.calculate, {super.key});

  /// The cart to show summary for.
  final OrderCalculateModel calculate;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);
    final String note = ref.watch(PaymentScreen.noteProvider);
    final SyncCallback syncCallback = useSyncCallback();
    return Material(
      clipBehavior: Clip.hardEdge,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// Note / Edit
            if (note.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    /// Note
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.shadow,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    /// Edit
                    const SizedBox(width: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: theme.textTheme.titleSmall,
                      ),
                      onPressed: () async => syncCallback(() async {
                        final StateController<bool> notifier = ref
                            .read(PaymentScreen.modalOpenedProvider.notifier)
                          ..state = true;
                        try {
                          await rootNavigator
                              .pushNamed(Routes.paymentNote.name);
                        } finally {
                          notifier.state = false;
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text($.payment.note.edit),
                      ),
                    ),
                  ],
                ),
              )
            else ...<Widget>[
              /// Note Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8),
                child: Text(
                  $.payment.note.promptTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.shadow,
                  ),
                ),
              ),

              /// Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextButton(
                  style: TextButton.styleFrom(
                    textStyle: theme.textTheme.titleMedium,
                    foregroundColor: theme.colorScheme.shadow,
                  ),
                  onPressed: () async => syncCallback(() async {
                    final StateController<bool> notifier = ref
                        .read(PaymentScreen.modalOpenedProvider.notifier)
                      ..state = true;
                    try {
                      await rootNavigator.pushNamed(Routes.paymentNote.name);
                    } finally {
                      notifier.state = false;
                    }
                  }),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text($.payment.note.prompt),
                  ),
                ),
              ),
            ],

            /// Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 1, color: theme.colorScheme.outline),
            ),

            /// Subtotal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    $.payment.summary.subtotal,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                  Text(
                    r'$' + ((calculate.subtotal ?? 0) / 100).toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                ],
              ),
            ),

            /// Delivery
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    $.payment.summary.deliveryTax,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                  Text(
                    r'$' +
                        ((calculate.deliveryCost ?? 0) / 100)
                            .toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                ],
              ),
            ),

            /// Tips
            if ((calculate.deliveryTip ?? 0) > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      $.payment.summary.tips,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                    ),
                    Text(
                      r'$' +
                          ((calculate.deliveryTip ?? 0) / 100)
                              .toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                    ),
                  ],
                ),
              ),

            /// Sales Tax
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    $.payment.summary.salesTax,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                  Text(
                    r'$' + ((calculate.tax ?? 0) / 100).toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                ],
              ),
            ),

            /// Discount
            if ((calculate.discount ?? 0) > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      $.payment.summary.discount,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                    ),
                    Text(
                      r'-$' +
                          ((calculate.discount ?? 0) / 100).toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                    ),
                  ],
                ),
              ),

            /// Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 1, color: theme.colorScheme.outline),
            ),

            /// Total
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    $.payment.summary.salesTax,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                  Text(
                    r'$' + ((calculate.total ?? 0) / 100).toStringAsFixed(2),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                  ),
                ],
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
          ..add(
            DiagnosticsProperty<OrderCalculateModel>('calculate', calculate),
          ),
      );
}

/// The callback with [UserProfileModel] value.
typedef ProfileCallback = FutureOr<void> Function(UserProfileModel customer);

/// The information about a customer on [PaymentScreen].
@immutable
class PaymentCustomerInformation extends HookConsumerWidget {
  /// The information about a customer on [PaymentScreen].
  const PaymentCustomerInformation(
    this.customer, {
    required this.authorize,
    this.focused,
    this.onPressed,
    super.key,
  });

  /// If the authorize prompt should be shown.
  final bool authorize;

  /// The user to show information for.
  final UserProfileModel? customer;

  /// The current focused state of this widget.
  final bool? focused;

  /// The callback on this widget.
  final ProfileCallback? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    final List<String> nameParts =
        this.customer?.name?.split(RegExp(r'\s+')) ?? const <String>[];
    final TextEditingController firstNameController = useTextEditingController(
      text: this.customer?.givenName ??
          (nameParts.isNotEmpty ? nameParts.first : null),
    );
    final TextEditingController lastNameController = useTextEditingController(
      text: this.customer?.familyName ??
          (nameParts.length > 1 ? nameParts.last : null),
    );
    final TextEditingController phoneController =
        useTextEditingController(text: this.customer?.phone);
    final TextEditingController emailController =
        useTextEditingController(text: this.customer?.email);
    final ValueNotifier<UserProfileModel?> customer = useState(this.customer);
    useMemoized(() {
      void listener() => customer.value = UserProfileModel(
            givenName: firstNameController.text,
            familyName: lastNameController.text,
            name: <String>[
              firstNameController.text.trim(),
              lastNameController.text.trim()
            ].where((final _) => _.isNotEmpty).join(' '),
            phone: phoneController.text,
            email: emailController.text,
          );
      firstNameController.addListener(listener);
      lastNameController.addListener(listener);
      phoneController.addListener(listener);
      emailController.addListener(listener);
    });
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceTint,
      ),
      onPressed: onPressed != null && !(focused ?? true)
          ? () async =>
              customer.value != null ? onPressed!(customer.value!) : null
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// Number / Title
          Padding(
            padding: const EdgeInsets.all(24)
                .copyWith(bottom: authorize ? 22 : null),
            child: Row(
              crossAxisAlignment: this.customer != null || authorize
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                /// Number
                Material(
                  type: MaterialType.circle,
                  color: theme.colorScheme.secondary,
                  child: Padding(
                    padding: !(focused ?? true)
                        ? const EdgeInsets.all(8)
                        : const EdgeInsets.fromLTRB(8, 6, 8, 10),
                    child: SizedBox.fromSize(
                      size: const Size.square(24),
                      child: Center(
                        child: Icon(
                          !(focused ?? true) ? icons.check : icons.numbers.$1,
                          color: theme.colorScheme.surface,
                          size: !(focused ?? true) ? 16 : 24,
                        ),
                      ),
                    ),
                  ),
                ),

                /// Customer Info
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          $.payment.customerInfo.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),

                      /// Unauthorized
                      if ((focused ?? false) && authorize) ...<Widget>[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            $.payment.customerInfo.unauthorizedTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.shadow,
                            ),
                          ),
                        ),

                        /// Log In
                        const SizedBox(height: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            textStyle: theme.textTheme.titleSmall,
                            foregroundColor: theme.colorScheme.shadow,
                          ),
                          onPressed: () async => syncCallback(() async {
                            if (await ref.read(authTokenProvider.future) !=
                                null) {
                              final Isar isar =
                                  await ref.read(isarProvider.future);
                              final Settings settings =
                                  await ref.read(settingsProvider.future)
                                    ..skippedAuthorization = false;
                              await isar
                                  .writeTxn(() => isar.settings.put(settings));
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child:
                                Text($.payment.customerInfo.unauthorizedLogIn),
                          ),
                        ),
                      ]

                      /// Summary Info
                      else if (focused == false) ...<Widget>[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              if (this.customer?.name?.isNotEmpty ??
                                  false) ...<Widget>[
                                /// Name
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    this.customer!.name!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.shadow,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ColoredBox(
                                  color: theme.colorScheme.shadow,
                                  child: SizedBox.fromSize(
                                    size: const Size.square(4),
                                  ),
                                ),
                              ],

                              /// Phone
                              if (this.customer?.phone?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    PhoneInputFormatter()
                                        .formatEditUpdate(
                                          TextEditingValue.empty,
                                          TextEditingValue(
                                            text: this.customer!.phone!,
                                          ),
                                        )
                                        .text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.shadow,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        /// Email
                        if (this.customer?.email?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              this.customer!.email!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.shadow,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (focused ?? false) ...<Widget>[
            /// Divider
            Divider(height: 1, color: theme.colorScheme.outline),

            /// Profile Edit
            Padding(
              padding: const EdgeInsets.all(24),
              child: ProfileEditForm(
                firstNameController: firstNameController,
                lastNameController: lastNameController,
                phoneController: phoneController,
                emailController: emailController,
              ),
            ),

            /// Divider
            Divider(height: 1, color: theme.colorScheme.outline),

            /// Create Account
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(0),
                ),
                onPressed: onPressed != null
                    ? () async => customer.value != null
                        ? onPressed!(customer.value!)
                        : null
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    authorize
                        ? $.payment.customerInfo.createAccount
                        : $.payment.customerInfo.authorized,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<bool>('authorize', authorize))
          ..add(DiagnosticsProperty<UserProfileModel?>('customer', customer))
          ..add(DiagnosticsProperty<bool?>('focused', focused))
          ..add(
            ObjectFlagProperty<ProfileCallback?>.has('onPressed', onPressed),
          ),
      );
}

/// The callback with [UserAddressesModel] value.
typedef AddressCallback = FutureOr<void> Function(
  DeliveryType deliveryType,
  UserAddressesModel? address,
);

/// The information about delivery/pickup on [PaymentScreen].
@immutable
class PaymentOrderDetails extends HookConsumerWidget {
  /// The information about delivery/pickup on [PaymentScreen].
  const PaymentOrderDetails(
    this.deliveryType,
    this.deliveryEta,
    this.pickupEta, {
    this.focused,
    this.onPressed,
    super.key,
  });

  /// The initial delivery type to display.
  final DeliveryType? deliveryType;

  /// The estimated time for [DeliveryType.delivery].
  final StoreEtaModel? deliveryEta;

  /// The estimated time for [DeliveryType.pickup].
  final StoreEtaModel? pickupEta;

  /// The current focused state of this widget.
  final bool? focused;

  /// The callback on this widget.
  final AddressCallback? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    assert(
      deliveryEta == null ||
          deliveryEta?.min != null && deliveryEta?.max != null,
      'Delivery eta properties must not be null.',
    );
    assert(
      pickupEta == null || pickupEta?.min != null && pickupEta?.max != null,
      'Pickup eta properties must not be null.',
    );
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final AsyncValue<UserAddressesModel?> currentAddress =
        ref.watch(currentAddressProvider);
    final UserAddressesModel? prevCurrentAddress =
        usePrevious<UserAddressesModel?>(currentAddress.valueOrNull);
    final UserAddressesModel? address = currentAddress.isLoading
        ? prevCurrentAddress
        : currentAddress.valueOrNull;

    final ValueNotifier<DeliveryType> deliveryType =
        useState(this.deliveryType ?? DeliveryType.delivery);
    final SyncCallback syncCallback = useSyncCallback();
    final PageController pageController =
        usePageController(initialPage: deliveryType.value.index);
    final ObjectRef<bool> manuallySet = useRef(false);
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
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceTint,
      ),
      onPressed: onPressed != null && !(focused ?? true)
          ? () async => onPressed!(deliveryType.value, address)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// Number / Title
          Padding(
            padding: const EdgeInsets.all(24)
                .copyWith(bottom: !(focused ?? true) ? 22 : null),
            child: Row(
              crossAxisAlignment: !(focused ?? true)
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                /// Number
                Material(
                  type: MaterialType.circle,
                  color: theme.colorScheme.secondary,
                  child: Padding(
                    padding: !(focused ?? true)
                        ? const EdgeInsets.all(8)
                        : const EdgeInsets.fromLTRB(8, 6, 8, 10),
                    child: SizedBox.fromSize(
                      size: const Size.square(24),
                      child: Center(
                        child: Icon(
                          !(focused ?? true) ? icons.check : icons.numbers.$2,
                          color: theme.colorScheme.surface,
                          size: !(focused ?? true) ? 16 : 24,
                        ),
                      ),
                    ),
                  ),
                ),

                /// Customer Info
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          $.payment.orderDetails.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),

                      if (focused == false) ...<Widget>[
                        const SizedBox(height: 4),

                        /// Address
                        if (address?.displayLong?.isNotEmpty ?? false)
                          Text(
                            $.payment.orderDetails
                                .deliveryAddress(address!.displayLong!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.shadow,
                            ),
                          ),

                        /// Instructions
                        if (true)
                          Text(
                            $.payment.orderDetails.deliveryInstructions(
                              address?.memo?.trim().isNotEmpty ?? false
                                  ? address!.memo!
                                  : $.profile.address.card.instructionsEmpty,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.shadow,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (focused ?? false) ...<Widget>[
            /// Divider
            Divider(height: 1, color: theme.colorScheme.outline),

            /// Delivery Type Switcher
            Padding(
              padding: const EdgeInsets.all(24).copyWith(bottom: 0),
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

            /// Delivery Type Pages
            ExpandablePageView(
              controller: pageController,
              children: <Widget>[
                /// Delivery
                Padding(
                  key: const ValueKey<DeliveryType>(DeliveryType.delivery),
                  padding: EdgeInsets.all(address != null ? 24 : 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// Selected Address
                      if (address != null) ...<Widget>[
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          child: ColoredBox(
                            color: theme.colorScheme.surface,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16).copyWith(right: 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: AddressCardInformation(address),
                                  ),

                                  /// Change
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                      textStyle: theme.textTheme.titleSmall,
                                    ),
                                    onPressed: () async =>
                                        syncCallback(() async {
                                      final StateController<bool> notifier =
                                          ref.read(
                                        PaymentScreen
                                            .modalOpenedProvider.notifier,
                                      )..state = true;
                                      try {
                                        await navigator.pushNamed(
                                          Routes.paymentAddress.name,
                                        );
                                      } finally {
                                        notifier.state = false;
                                      }
                                    }),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      child: Text($.addressForm.addressChange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// Icon / Estimated Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              icons.clock,
                              size: 24,
                              color: theme.colorScheme.shadow,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                deliveryEta == null
                                    ? $.payment.orderDetails.deliveryUnavailable
                                    : $.payment.orderDetails.deliveryTime(
                                        deliveryEta!.min!,
                                        deliveryEta!.max!,
                                      ),
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(color: theme.colorScheme.shadow),
                              ),
                            ),
                          ],
                        ),
                      ] else ...<Widget>[
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(0),
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: theme.textTheme.titleMedium,
                            alignment: Alignment.centerLeft,
                            backgroundColor: theme.colorScheme.surfaceTint,
                          ),
                          onPressed: () async => syncCallback(
                            () => navigator.pushNamed(Routes.map.name),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: <Widget>[
                                Icon(icons.plusCircle, size: 24),
                                const SizedBox(width: 16),
                                Text($.profile.address.addNew)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                /// Pickup
                Padding(
                  key: const ValueKey<DeliveryType>(DeliveryType.pickup),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        icons.clock,
                        size: 24,
                        color: theme.colorScheme.shadow,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pickupEta == null
                              ? $.payment.orderDetails.pickupUnavailable
                              : $.payment.orderDetails.pickupTime(
                                  pickupEta!.min!,
                                  pickupEta!.max!,
                                ),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: theme.colorScheme.shadow),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// Divider
            Divider(height: 1, color: theme.colorScheme.outline),

            /// Proceed
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(0),
                ),
                onPressed: onPressed != null
                    ? () async => onPressed!(deliveryType.value, address)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text($.payment.orderDetails.proceed),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(EnumProperty<DeliveryType>('deliveryType', deliveryType))
          ..add(DiagnosticsProperty<StoreEtaModel?>('deliveryEta', deliveryEta))
          ..add(DiagnosticsProperty<StoreEtaModel?>('pickupEta', pickupEta))
          ..add(DiagnosticsProperty<bool?>('focused', focused))
          ..add(
            ObjectFlagProperty<AddressCallback?>.has('onPressed', onPressed),
          ),
      );
}

/// The information about payment on [PaymentScreen].
@immutable
class PaymentPayment extends HookConsumerWidget {
  /// The information about payment on [PaymentScreen].
  const PaymentPayment(
    this.calculate, {
    this.focused,
    this.onPressed,
    super.key,
  });

  /// The cart to show summary for.
  final OrderCalculateModel calculate;

  /// The current focused state of this widget.
  final bool? focused;

  /// The callback on this widget.
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final String? discountCode = ref.watch(PaymentScreen.discountCodeProvider);
    final GlobalKey<State<StatefulWidget>> discountCodeKey =
        useMemoized(GlobalKey.new);
    final TextEditingController discountCodeController =
        useTextEditingController();
    final FocusNode discountCodeFocusNode = useFocusNode();
    final ValueNotifier<bool> discountCodeHasFocus =
        useState(discountCodeFocusNode.hasFocus);
    useMemoized(
      () => discountCodeFocusNode.addListener(
        () => discountCodeHasFocus.value = discountCodeFocusNode.hasFocus,
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

    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceTint,
      ),
      onPressed: onPressed != null && !(focused ?? true)
          ? () async => onPressed!()
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Number / Title
          Padding(
            padding: const EdgeInsets.all(24)
                .copyWith(bottom: !(focused ?? true) ? 22 : null),
            child: Row(
              crossAxisAlignment: !(focused ?? true)
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                /// Number
                Material(
                  type: MaterialType.circle,
                  color: theme.colorScheme.secondary,
                  child: Padding(
                    padding: !(focused ?? true)
                        ? const EdgeInsets.all(8)
                        : const EdgeInsets.fromLTRB(8, 6, 8, 10),
                    child: SizedBox.fromSize(
                      size: const Size.square(24),
                      child: Center(
                        child: Icon(
                          !(focused ?? true) ? icons.check : icons.numbers.$3,
                          color: theme.colorScheme.surface,
                          size: !(focused ?? true) ? 16 : 24,
                        ),
                      ),
                    ),
                  ),
                ),

                /// Title
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    $.payment.payment.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),

          if (focused ?? false) ...<Widget>[
            /// Divider
            Divider(height: 1, color: theme.colorScheme.outline),

            /// Add Tip
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                $.payment.payment.addTip,
                style: theme.textTheme.titleLarge,
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: PaymentTipForm(),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: PaymentMethodForm(),
            ),

            /// Divider
            const SizedBox(height: 18),
            Divider(height: 1, color: theme.colorScheme.outline),

            /// Discount
            if (discountCode == null) ...<Widget>[
              /// Discount Code Title
              Padding(
                padding: const EdgeInsets.all(24).copyWith(bottom: 2),
                child: Text(
                  $.payment.payment.discount.title,
                  style: theme.textTheme.titleSmall,
                ),
              ),

              /// Discount Apply
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.titleSmall,
                  ),
                  onPressed: () async {
                    (ref.read(PaymentScreen.discountCodeProvider.notifier))
                        .state = '';
                    discountCodeFocusNode.requestFocus();
                    await requestFocus(discountCodeKey);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text($.payment.payment.discount.apply),
                  ),
                ),
              )
            ] else if (discountCode.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24).copyWith(bottom: 0),
                child: TextField(
                  key: discountCodeKey,
                  controller: discountCodeController,
                  focusNode: discountCodeFocusNode,
                  onTap: () async => requestFocus(discountCodeKey),
                  onChanged: (final _) {},
                  onSubmitted: (final String value) => ref
                      .read(PaymentScreen.discountCodeProvider.notifier)
                      .state = value,
                  decoration: InputDecoration(
                    hintText: $.payment.payment.discount.hint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    suffixIcon: discountCodeHasFocus.value
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              /// Clear
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: IconButton(
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: Icon(icons.crossCircle, size: 24),
                                  ),
                                  onPressed: () {
                                    discountCodeController.value =
                                        TextEditingValue.empty;
                                    ref.invalidate(
                                      PaymentScreen.discountCodeProvider,
                                    );
                                  },
                                ),
                              ),

                              /// Confirm
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () => ref
                                    .read(
                                      PaymentScreen
                                          .discountCodeProvider.notifier,
                                    )
                                    .state = discountCodeController.text,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 12,
                                  ),
                                  child:
                                      Text($.payment.payment.discount.confirm),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(10)
                  ],
                  keyboardType: TextInputType.number,
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.all(24).copyWith(bottom: 0, right: 16),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(
                        icons.check,
                        size: 24,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        $.payment.payment.discount.applied(discountCode),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: theme.textTheme.titleSmall,
                      ),
                      onPressed: () async {
                        discountCodeController
                          ..text = discountCode
                          ..selection = TextSelection.collapsed(
                            offset: discountCode.length,
                          );
                        (ref.read(PaymentScreen.discountCodeProvider.notifier))
                            .state = '';
                        discountCodeFocusNode.requestFocus();
                        await requestFocus(discountCodeKey);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text($.payment.payment.discount.change),
                      ),
                    ),
                  ],
                ),
              ),

            /// Proceed
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(0),
                ),
                onPressed: onPressed != null ? () async => onPressed!() : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    $.payment.payment.proceed((calculate.total ?? 0) / 100),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(
            DiagnosticsProperty<OrderCalculateModel>('calculate', calculate),
          )
          ..add(DiagnosticsProperty<bool?>('focused', focused))
          ..add(
            ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed),
          ),
      );
}
