import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../generated/models.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../models/address.dart';
import '../../../models/settings.dart';
import '../../../providers/api.dart';
import '../../../providers/misc.dart';
import '../../../routes.dart';
import '../map.dart';
import '../tabs/profile.dart';

/// The screen used to edit user address.
@immutable
class AddressScreen extends HookConsumerWidget {
  /// The screen used to edit user address.
  const AddressScreen(this.address, {super.key});

  /// The address being edited on this screen.
  final UserAddressesModel address;

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            address.addressId == null
                                ? $.map.addressTitle
                                : $.profile.address.edit.title,
                            style: theme.textTheme.displayMedium,
                          ),
                        ),
                      ),

                      /// Clear
                      if (address.addressId != null)
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
                            tooltip: $.profile.address.edit.removeTooltip,
                            onPressed: () async => syncCallback(
                              () => navigator.pushNamed(
                                Routes.addressRemove.name,
                                arguments: AddressRemoveScreen(address),
                              ),
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
                              child: AddressForm(address),
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserAddressesModel>('address', address)),
      );
}

/// The form used to edit an address on [AddressScreen].
@immutable
class AddressForm extends HookConsumerWidget {
  /// The form used to input a note on [AddressScreen].
  const AddressForm(this.address, {super.key});

  /// The address being edited in this form.
  final UserAddressesModel address;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();

    final ValueNotifier<UserAddressesModel> currentAddress = useState(address);
    final GlobalKey<State<StatefulWidget>> apartmentKey =
        useMemoized(GlobalKey.new);
    final TextEditingController apartmentController =
        useTextEditingController(text: address.internal);

    final GlobalKey<State<StatefulWidget>> notesKey =
        useMemoized(GlobalKey.new);
    final TextEditingController notesController =
        useTextEditingController(text: address.memo);
    final FocusNode notesFocusNode = useFocusNode();

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
        /// Address Title
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            $.addressForm.addressTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),

        /// Address / Edit
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              /// Address
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentAddress.value.displayLong ??
                      currentAddress.value.displayShort ??
                      '',
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              /// Edit
              if (currentAddress.value.addressId != null) ...<Widget>[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.titleSmall,
                  ),
                  onPressed: () async => syncCallback(
                    () async {
                      final Object? result = await navigator.pushNamed<Object?>(
                        Routes.map.name,
                        arguments:
                            MapScreen(initialAddress: currentAddress.value),
                      );
                      if (result is UserAddressesModel) {
                        currentAddress.value = result;
                      }
                    },
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text($.addressForm.addressChange),
                  ),
                ),
              ]
            ],
          ),
        ),

        /// Apartment Title
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            $.addressForm.apartmentTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),

        /// Apartment Field
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            key: apartmentKey,
            controller: apartmentController,
            onTap: () async => requestFocus(apartmentKey),
            keyboardType: TextInputType.text,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(32),
            ],
            textInputAction: TextInputAction.next,
            onEditingComplete: () async {
              notesFocusNode.requestFocus();
              await requestFocus(notesKey);
            },
            decoration: InputDecoration(
              hintText: $.addressForm.apartmentHint,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            ),
          ),
        ),

        /// Notes Title
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            $.addressForm.instructionsTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),

        /// Notes Field
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            minLines: 1,
            maxLines: 5,
            key: notesKey,
            controller: notesController,
            focusNode: notesFocusNode,
            onTap: () async => requestFocus(notesKey),
            keyboardType: TextInputType.multiline,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(180),
            ],
            decoration: InputDecoration(
              hintText: $.addressForm.instructionsHint,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text($.addressForm.deny),
                  ),
                ),
              ),

              /// Approve
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async => syncCallback(() async {
                    final UserAddressesModel address =
                        (currentAddress.value).copyWith(
                      internal: apartmentController.text.trim().isEmpty
                          ? null
                          : apartmentController.text.trim(),
                      memo: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                    if (await ref.read(skippedAuthorizationProvider.future)) {
                      final Isar isar = await ref.read(isarProvider.future);
                      await isar.writeTxn(
                        () async => isar.address.put(
                          address.convert()
                            ..defaultAddress = await isar.address.count() == 0,
                        ),
                      );
                    } else {
                      try {
                        final Iterable<UserAddressesModel>? addresses =
                            await ref.read(addressesProvider.future);
                        final int? userAddressId =
                            await ref.read(addressProvider(address).future);
                        if (userAddressId != null &&
                            (addresses?.isEmpty ?? true)) {
                          await ref.read(
                            defaultAddressProvider(userAddressId).future,
                          );
                        }
                      } on DioError catch (error, stackTrace) {
                        await navigator.pushNamed(
                          Routes.addressError.name,
                          arguments:
                              AddressErrorScreen(address, error, stackTrace),
                        );
                        return;
                      }
                    }
                    await navigator.maybePop();
                    await navigator.maybePop();
                  }),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text($.addressForm.approve),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserAddressesModel>('address', address)),
      );
}

/// The screen used to remove an [address] on [AddressScreen].
@immutable
class AddressRemoveScreen extends HookConsumerWidget {
  /// The screen used to remove an [address] on [AddressScreen].
  const AddressRemoveScreen(this.address, {super.key});

  /// The address to remove on this screen.
  final UserAddressesModel address;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();

    /// If not authorized, remove local address
    /// and set the first remaining address as default.
    ///
    /// If authorized, deactivate address on server
    /// and set the first remaining address as default.
    Future<void> removeAddress() async {
      if (await ref.read(skippedAuthorizationProvider.future)) {
        if (address.addressId != null) {
          final Isar isar = await ref.read(isarProvider.future);
          await isar.writeTxn(() async {
            await isar.address.delete(address.addressId!);
            final List<Address> addresses =
                await isar.address.where().findAll();
            await isar.address.putAll(<Address>[
              for (final Address address in addresses)
                address..defaultAddress = address.id == addresses.first.id
            ]);
          });
        }
      } else {
        final UserAddressesModel? newAddress =
            (await ref.read(addressesProvider.future))
                ?.firstWhereOrNull((final _) => _ != address);
        await ref.read(activeAddressProvider(address.userAddressId!).future);
        if (newAddress?.userAddressId != null) {
          await ref
              .read(defaultAddressProvider(newAddress!.userAddressId!).future);
        }
      }
      await navigator.maybePop();
      await navigator.maybePop();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
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
                              $.alert.addressRemove.title,
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
                          $.alert.addressRemove.body,
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
                                  child: Text($.alert.addressRemove.deny),
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
                                onPressed: () async =>
                                    syncCallback(removeAddress),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.addressRemove.approve),
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserAddressesModel>('address', address)),
      );
}

/// The screen that notifies about an error on [AddressScreen].
@immutable
class AddressErrorScreen extends HookConsumerWidget {
  /// The screen that notifies about an error on [AddressScreen].
  const AddressErrorScreen(
    this.address,
    this.error,
    this.stackTrace, {
    super.key,
  });

  /// The address to show this error screen for.
  final UserAddressesModel address;

  /// The error that caused this screen to appear.
  final Object error;

  /// The [StackTrace] of an [error] that caused this screen to appear.
  final StackTrace stackTrace;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
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
                              $.alert.addressError.title,
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
                          $.alert.addressError.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Approve
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.surface,
                            minimumSize: const Size.fromHeight(0),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
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
                            child: Text($.alert.addressError.approve),
                          ),
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserAddressesModel>('address', address))
          ..add(DiagnosticsProperty<Object>('error', error))
          ..add(DiagnosticsProperty<StackTrace>('stackTrace', stackTrace)),
      );
}

/// The screen that allows user to pick a delivery address for the order.
@immutable
class PaymentAddressScreen extends HookConsumerWidget {
  /// The screen that allows user to pick a delivery address for the order.
  const PaymentAddressScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final AsyncValue<Iterable<UserAddressesModel>?> addresses =
        ref.watch(currentAddressesProvider);
    final Iterable<UserAddressesModel>? prevAddresses =
        usePrevious<Iterable<UserAddressesModel>?>(addresses.valueOrNull);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.colorScheme.surface.withOpacity(1 / 2),
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
              child: SingleChildScrollView(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        $.payment.orderDetails.deliveryTitle,
                        style: theme.textTheme.displayMedium,
                      ),
                    ),

                    /// Add New Address
                    Padding(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                      child: TextButton(
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
                    ),

                    /// Address Cards
                    if (addresses.isLoading && prevAddresses == null)
                      Padding(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: const <Widget>[
                            Visibility(
                              visible: false,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: AddressCard(UserAddressesModel()),
                            ),
                            CircularProgressIndicator.adaptive()
                          ],
                        ),
                      )
                    else if (addresses.asData?.value != null ||
                        prevAddresses != null)
                      for (final UserAddressesModel address
                          in addresses.asData?.value ?? prevAddresses!)
                        Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16).copyWith(bottom: 0),
                            child: AddressCard(address),
                          ),
                        ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
