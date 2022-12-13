import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../hooks/sync_callback_hook.dart';
import '../routes.dart';

/// The screen that displays an error occured while connecting to the internet.
@immutable
class ErrorConnectionScreen extends HookConsumerWidget {
  /// The screen that displays an error occured while connecting to the
  /// internet.
  const ErrorConnectionScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
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
          statusBarColor: theme.colorScheme.onBackground,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor: theme.colorScheme.onBackground,
        ),
        child: Scaffold(
          backgroundColor: theme.colorScheme.onBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                /// Image / Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// Image
                      Icon(
                        icons.connection,
                        size: 110,
                        color: theme.colorScheme.primary,
                      ),

                      /// Subtitle
                      const SizedBox(height: 22),
                      Text(
                        $.errorConnection.subtitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    $.errorConnection.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 36,
                      height: 48 / 36,
                      color: theme.colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                /// Description
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    $.errorConnection.description,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16)
                .copyWith(bottom: mediaQuery.padding.bottom + 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(0),
              ),
              onPressed: navigator.maybePop,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text($.errorConnection.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen that displays an error occured while connecting to the server.
@immutable
class ErrorServerScreen extends HookConsumerWidget {
  /// The screen that displays an error occured while connecting to the server.
  const ErrorServerScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
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
          statusBarColor: theme.colorScheme.onBackground,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor: theme.colorScheme.onBackground,
        ),
        child: Scaffold(
          backgroundColor: theme.colorScheme.onBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                /// Image / Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// Image
                      Icon(
                        icons.server,
                        size: 110,
                        color: theme.colorScheme.primary,
                      ),

                      /// Subtitle
                      const SizedBox(height: 22),
                      Text(
                        $.errorServer.subtitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    $.errorServer.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 36,
                      height: 48 / 36,
                      color: theme.colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                /// Description
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    $.errorServer.description,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16)
                .copyWith(bottom: mediaQuery.padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                /// Try Again
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(0),
                  ),
                  onPressed: navigator.maybePop,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text($.errorServer.primary),
                  ),
                ),

                /// Open Settings
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(0),
                    foregroundColor: theme.colorScheme.surface,
                    backgroundColor: theme.colorScheme.onBackground,
                    side: BorderSide(color: theme.colorScheme.surface),
                  ),
                  onPressed: () async =>
                      launchUrlString('mailto:info@orderpapaya.com'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text($.errorServer.secondary),
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
