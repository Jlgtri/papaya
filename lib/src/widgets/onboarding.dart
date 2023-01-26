import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../hooks/sync_callback_hook.dart';
import '../models/settings.dart';
import '../providers/misc.dart';
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
@immutable
class OnboardingScreen extends HookConsumerWidget {
  /// The screen that greets the user.
  const OnboardingScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
    final PageController pageController = usePageController();
    final ValueNotifier<bool> showSkip = useState(true);

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
    useMemoized(() {
      pageController.addListener(() {
        if (pageController.page != null) {
          final bool $showSkip = pageController.page! < pages.length - 1.6;
          if (showSkip.value != $showSkip) {
            showSkip.value = $showSkip;
          }
        }
      });
    });
    Future<void> getStarted() async => syncCallback(() async {
          final Isar isar = await ref.read(isarProvider.future);
          final Settings settings = await ref.read(settingsProvider.future)
            ..onboarding = false;
          await isar.writeTxn(() => isar.settings.put(settings));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await navigator
              .pushReplacementNamed((await Routes.current(container)).name);
        });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.colorScheme.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: WillPopScope(
        onWillPop: () async {
          await pageController.previousPage(
            duration: const Duration(milliseconds: 373),
            curve: Curves.ease,
          );
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              if (showSkip.value)
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
                              child: Icon(icons.arrow.right, size: 14),
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
                  key: PageStorageKey<String>(page.source),
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
            padding: const EdgeInsets.symmetric(horizontal: 16)
                .copyWith(bottom: mediaQuery.padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  child: SmoothPageIndicator(
                    controller: pageController,
                    count: pages.length,
                    effect: ColorTransitionEffect(
                      spacing: 12,
                      radius: 8,
                      dotColor: theme.colorScheme.outline,
                      activeDotColor: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (showSkip.value)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(0),
                    ),
                    onPressed: () async => pageController.nextPage(
                      duration: const Duration(milliseconds: 373),
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
