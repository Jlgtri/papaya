import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shimmer/shimmer.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/settings.dart';
import '../../providers/api_providers.dart';
import '../../providers/misc_providers.dart';
import '../../routes.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);
    final AsyncValue<Iterable<UserAddressesModel>> addresses =
        ref.watch(addressesProvider);
    final SyncCallback syncCallback = useSyncCallback();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Title
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32)
                  .copyWith(bottom: 24),
              child: Text(
                $.profile.title,
                style: theme.textTheme.displayMedium,
                maxLines: 1,
              ),
            ),
          ),

          /// Profile Info
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Name / Edit
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Jonathan Smith',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                height: 32 / 24,
                              ),
                            ),
                          ),
                        ),

                        /// Edit
                        IconButton(
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(32),
                            padding: const EdgeInsets.all(8),
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          onPressed: () {},
                          icon: Icon(icons.pencil, size: 16),
                        )
                      ],
                    ),
                  ),
                ),

                /// Phone Number
                Flexible(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '+1(212) 200 7898',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                /// Email
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'jonathansmith@example.com',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Delivery Address
          Flexible(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Title
                  Flexible(
                    child: Text(
                      $.profile.address.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),

                  /// Address Cards
                  if (addresses.isLoading)
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(),
                    )
                  else if (addresses is AsyncData &&
                      addresses.valueOrNull != null)
                    for (final UserAddressesModel address in addresses.value!)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: AddressCard(address),
                        ),
                      ),

                  /// Add New Address
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(0),
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: theme.textTheme.titleMedium,
                        alignment: Alignment.centerLeft,
                        backgroundColor: theme.colorScheme.surfaceTint,
                      ),
                      onPressed: () {},
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
                ],
              ),
            ),
          ),

          /// Payment Methods
          Flexible(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Title
                  Flexible(
                    child: Text(
                      $.profile.payment.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),

                  /// Add New Payment Method
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(0),
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: theme.textTheme.titleMedium,
                        alignment: Alignment.centerLeft,
                        backgroundColor: theme.colorScheme.surfaceTint,
                      ),
                      onPressed: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Icon(icons.plusCircle, size: 24),
                            const SizedBox(width: 16),
                            Text($.profile.payment.addNew)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 117),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff484850),
                side: const BorderSide(color: Color(0xff484850)),
              ),
              onPressed: () async => syncCallback(() async {
                final Isar isar = await ref.read(isarProvider.future);
                await isar.writeTxn(
                  () async => isar.settings.put(
                    (await ref.read(settingsProvider.future))
                      ..tokens = <Token>[],
                  ),
                );
                await (await Routes.current(container))
                    .pushReplacement(rootNavigator, container);
              }),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icons.exit, size: 24, color: const Color(0xff484850)),
                    const SizedBox(width: 8),
                    Flexible(child: Text($.profile.logout)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// The card used to display an [address].
class AddressCard extends HookConsumerWidget {
  /// The card used to display an [address].
  const AddressCard(this.address, {super.key});

  /// The address to display in this card.
  final UserAddressesModel address;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceTint,
        disabledBackgroundColor: theme.colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ).copyWith(
        side: MaterialStateProperty.resolveWith(
          (final Set<MaterialState> states) =>
              states.contains(MaterialState.pressed)
                  ? BorderSide(
                      color: theme.colorScheme.primary.withOpacity(1 / 4),
                      width: 2,
                    )
                  : address.defaultAddress ?? false
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
        ),
      ),
      onPressed: address.defaultAddress ?? false ? null : () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// Information
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// Title
                    Flexible(
                      child: Text(
                        $.profile.address.card.title,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 1,
                      ),
                    ),

                    /// Address Value
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        address.displayLong ?? '',
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                      ),
                    ),

                    /// Instructions Title
                    const SizedBox(height: 16),
                    Flexible(
                      child: Text(
                        $.profile.address.card.instructions,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 1,
                      ),
                    ),

                    /// Instructions Value
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        'Please call',
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Edit
            IconButton(
              style: IconButton.styleFrom(
                fixedSize: const Size.square(32),
                padding: const EdgeInsets.all(8),
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {},
              icon: Icon(icons.pencil, size: 16),
            )
          ],
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
