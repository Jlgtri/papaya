import 'package:cached_network_image/cached_network_image.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../providers/api_providers.dart';
import '../../routes.dart';
import '../navigation_screen.dart';
import '../store_screen.dart';
import 'search_not_found_screen.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (ref.watch(
          SearchField.provider.select((final _) => _?.isNotEmpty ?? false),
        ) &&
        ref.watch(
          filteredStoresProvider
              .select((final _) => _.valueOrNull?.isEmpty ?? false),
        )) {
      return const SearchNotFoundScreen();
    }

    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery =
        MediaQuery.of(Navigator.of(context, rootNavigator: true).context);

    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
    final PageController pageController = usePageController();
    final ValueNotifier<int> pageIndex = useState(0);

    final AsyncValue<Iterable<StoreModel>> stores =
        ref.watch(filteredStoresProvider);
    final bool showAllStores = ref.watch(
      storesProvider.select(
        (final _) =>
            (_ is AsyncData && _.valueOrNull != null) &&
            (stores is AsyncData && stores.valueOrNull != null) &&
            _.value!.length != stores.value!.length,
      ),
    );
    return CustomScrollView(
      slivers: <Widget>[
        /// Carousel with indicator
        SliverToBoxAdapter(
          child: SizedBox(
            height: mediaQuery.size.height -
                NavigationScreen.appBarHeight -
                NavigationScreen.navBarHeight -
                mediaQuery.padding.vertical,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                /// Carousel
                PageView(
                  controller: pageController,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onBackground,
                        image: false
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(''),
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 64,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                'BKLYN Wild - Time Out Market',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: theme.colorScheme.surface,
                                ),
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Flexible(
                              child: Text(
                                'Short promotion description goes here',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.surface,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 48),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 0),
                              ),
                              onPressed: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text($.home.viewDetail),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),

                /// Indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: DotsIndicator(
                    dotsCount: 1,
                    position: 0,
                    decorator: DotsDecorator(
                      size: const Size.square(16),
                      activeSize: const Size.square(16),
                      spacing: const EdgeInsets.symmetric(horizontal: 6),
                      color: theme.colorScheme.surface,
                      activeColor: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (stores is AsyncData && stores.valueOrNull != null) ...<Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40)
                  .copyWith(right: 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      showAllStores ? $.home.storesNearby : $.home.storesAll,
                      style: theme.textTheme.displayMedium?.copyWith(height: 1),
                    ),
                  ),
                  if (showAllStores)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          textStyle: theme.textTheme.titleMedium,
                        ),
                        onPressed: () async => syncCallback(
                          () => Routes.stores.push(rootNavigator, container),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(icons.misc.arrowRight, size: 14),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text($.home.storesViewAll),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 69)),
        ]
      ],
    );
  }
}
