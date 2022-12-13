import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../providers/api.dart';
import '../../routes.dart';
import '../navigation/tabs/home.dart';

/// The screen used to display stores from [allStoresProvider].
@immutable
class StoresScreen extends HookConsumerWidget {
  /// The screen used to display stores from [allStoresProvider].
  const StoresScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
    final AsyncValue<Iterable<StoreModel>?> stores =
        ref.watch(allStoresProvider);
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
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: theme.colorScheme.surface,
        ),
        child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: theme.colorScheme.surface,
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
                        Flexible(child: Text($.store.back))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: <Widget>[
              /// Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 24, top: 8),
                  child: Text(
                    $.storesAll.title,
                    style: theme.textTheme.displayMedium,
                  ),
                ),
              ),

              /// Stores
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (final _, final int index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                        .copyWith(bottom: 24),
                    child: StoreCard(stores.value!.elementAt(index)),
                  ),
                  childCount: stores.value!.length,
                ),
              ),

              SliverPadding(
                padding:
                    EdgeInsets.only(bottom: mediaQuery.padding.bottom + 69),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
