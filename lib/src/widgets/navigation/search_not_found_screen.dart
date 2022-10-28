import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../navigation_screen.dart';

class SearchNotFoundScreen extends HookConsumerWidget {
  const SearchNotFoundScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData rootMediaQuery =
        MediaQuery.of(Navigator.of(context, rootNavigator: true).context);
    final I18N $ = I18NLocalizations.of(context);
    return Scrollable(
      physics: const ClampingScrollPhysics(),
      viewportBuilder: (final _, final ViewportOffset offset) => Viewport(
        offset: offset,
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox(
              height: rootMediaQuery.size.height -
                  NavigationScreen.searchAppBarHeight -
                  NavigationScreen.navBarHeight -
                  rootMediaQuery.padding.vertical,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  ColoredBox(
                    color: theme.colorScheme.onBackground,
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    right: -69,
                    child: Image.asset(assets.waitingList1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            $.home.searchNotFound.title,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: theme.colorScheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Flexible(
                          child: Text(
                            $.home.searchNotFound.description,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              height: 32 / 24,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.surface,
                            ),
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
                            child: Text(
                                $.home.searchNotFound.changeDeliveryAdress),
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 0),
                            foregroundColor: theme.colorScheme.surface,
                            backgroundColor: theme.colorScheme.onBackground,
                            side: BorderSide(color: theme.colorScheme.surface),
                          ),
                          onPressed: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text($.home.searchNotFound.switchToPickup),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Stack(
              alignment: Alignment.topRight,
              children: <Widget>[
                ColoredBox(
                  color: theme.colorScheme.secondary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 72,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 60),
                        Flexible(
                          child: Text(
                            $.home.searchNotFound.joinWaitingListTitle,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: theme.colorScheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: Text(
                            $.home.searchNotFound.joinWaitingListDescription,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              height: 32 / 24,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Text($.home.searchNotFound.joinWaitingList),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -69,
                  child: Image.asset(assets.waitingList2),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
