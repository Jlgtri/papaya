import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../models/settings.dart';
import '../routes.dart';

/// The screen that greets the user.
class AuthorizationScreen extends HookConsumerWidget {
  /// The screen that greets the user.
  const AuthorizationScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final IsMounted isMounted = useIsMounted();
    Future<void> authorize() async {
      if (isMounted() && await ref.read(authTokenProvider.future) != null) {
        await Routes.map.pushReplacement(navigator, ref);
      }
    }

    return Scaffold(
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
