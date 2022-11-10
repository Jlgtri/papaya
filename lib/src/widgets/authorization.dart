import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../hooks/sync_callback_hook.dart';
import '../models/settings.dart';
import '../providers/misc.dart';
import '../routes.dart';

/// The screen that greets the user.
@immutable
class AuthorizationScreen extends HookConsumerWidget {
  /// The screen that greets the user.
  const AuthorizationScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
    Future<void> authorize() async => syncCallback(() async {
          if (await ref.read(authTokenProvider.future) != null) {
            await navigator
                .pushReplacementNamed((await Routes.current(container)).name);
          }
        });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.colorScheme.onBackground,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.colorScheme.onBackground,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarColor: theme.colorScheme.onBackground,
          ),
          actions: <Widget>[
            Align(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.surface,
                  ),
                  onPressed: () async => syncCallback(() async {
                    final Settings settings =
                        await ref.read(settingsProvider.future);
                    if (!settings.skippedAuthorization) {
                      final Isar isar = await ref.read(isarProvider.future);
                      await isar.writeTxn(
                        () async => isar.settings
                            .put(settings..skippedAuthorization = true),
                      );
                      await Future<void>.delayed(
                        const Duration(milliseconds: 100),
                      );
                    }
                    await navigator.pushReplacementNamed(
                      (await Routes.current(container)).name,
                    );
                  }),
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
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 128),
              child: Image.asset(
                assets.authorizationBackground,
                fit: BoxFit.fitWidth,
              ),
            ),
            AutoSizeText(
              $.auth.title,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 106,
                height: 80 / 106,
                color: theme.colorScheme.surface,
              ),
              maxLines: 3,
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16)
              .copyWith(bottom: mediaQuery.padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(0),
                ),
                onPressed: authorize,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text($.auth.signUp),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(0),
                  foregroundColor: theme.colorScheme.surface,
                  backgroundColor: theme.colorScheme.onBackground,
                  side: BorderSide(color: theme.colorScheme.surface),
                ),
                onPressed: authorize,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text($.auth.signIn),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
