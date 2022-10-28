import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../models/settings.dart';
import '../providers/misc_providers.dart';
import '../routes.dart';

/// The data for the [OnboardingScreen].
@immutable
class OnboardingPage {
  /// The data for the [OnboardingScreen].
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.source,
  })  : assert(title != '', 'Title can not be empty.'),
        assert(description != '', 'Description can not be empty.'),
        assert(source != '', 'Source can not be empty.');

  /// The title to show on [OnboardingScreen].
  final String title;

  /// The description to show on [OnboardingScreen].
  final String description;

  /// The image source to show on [OnboardingScreen].
  final String source;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is OnboardingPage &&
          other.title == title &&
          other.description == description &&
          other.source == source;

  @override
  int get hashCode => title.hashCode ^ description.hashCode ^ source.hashCode;

  @override
  String toString() =>
      'OnboardingPage(title: $title, description: $description, '
      'source: $source)';
}

/// The screen that greets the user.
class OnboardingScreen extends HookConsumerWidget {
  /// The screen that greets the user.
  const OnboardingScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final IsMounted isMounted = useIsMounted();
    final ValueNotifier<double> currentPage = useState(0);
    final Iterable<OnboardingPage> pages = <OnboardingPage>[
      OnboardingPage(
        title: $.onboarding.$1.title,
        description: $.onboarding.$1.description,
        source: assets.onboarding.$1,
      ),
      OnboardingPage(
        title: $.onboarding.$2.title,
        description: $.onboarding.$2.description,
        source: assets.onboarding.$2,
      ),
      OnboardingPage(
        title: $.onboarding.$3.title,
        description: $.onboarding.$3.description,
        source: assets.onboarding.$3,
      ),
    ];

    Future<void> getStarted() async {
      if (isMounted()) {
        final Isar isar = await ref.read(isarProvider.future);
        await isar.writeTxn(
          () async => isar.settings.put(
            await ref.read(settingsProvider.future)
              ..onboarding = false,
          ),
        );
      }

      await Routes.authorization.pushReplacement(navigator, ref);
    }

    final PageController pageController = usePageController();
    useMemoized(
      () => pageController.addListener(
        () => pageController.page != null
            ? currentPage.value = pageController.page!
            : null,
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: WillPopScope(
        onWillPop: () async {
          await pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              if (currentPage.value < pages.length - 1.6)
                Align(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton(
                      onPressed: getStarted,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(child: Text($.onboarding.skip)),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(icons.misc.arrowRight, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: PageView(
            controller: pageController,
            children: <Widget>[
              for (final OnboardingPage page in pages)
                Align(
                  child: SingleChildScrollView(
                    key: ValueKey<Orientation>(mediaQuery.orientation),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Image.asset(page.source, width: 160, height: 160),
                        const SizedBox(height: 32),
                        Align(
                          child: Text(
                            page.title,
                            style: theme.textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  child: DotsIndicator(
                    dotsCount: pages.length,
                    position: currentPage.value,
                    decorator: DotsDecorator(
                      size: const Size.square(16),
                      activeSize: const Size.square(16),
                      spacing: const EdgeInsets.symmetric(horizontal: 6),
                      color: theme.colorScheme.outline,
                      activeColor: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (currentPage.value < pages.length - 1.6)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(0),
                    ),
                    onPressed: () async => pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text($.onboarding.next),
                    ),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(0),
                    ),
                    onPressed: getStarted,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text($.onboarding.getStarted),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
