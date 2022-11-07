import 'package:catcher/catcher.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntp/ntp.dart';

import 'src/generated/i18n.g.dart';
import 'src/providers/misc.dart';
import 'src/routes.dart';
import 'src/styles.dart';
import 'src/utils/catcher.dart';

void main() {
  CatcherOptions config([final ProviderContainer? container]) => CatcherOptions(
        container != null ? RiverpodReportMode(container) : SilentReportMode(),
        <ReportHandler>[ConsoleHandler()],
        logger: ChangedCatcherLogger(),
      );
  Catcher(
    debugConfig: config(),
    profileConfig: config(),
    releaseConfig: config(),
    runAppFunction: () async {
      final WidgetsBinding widgetsBinding =
          WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final ProviderContainer container = ProviderContainer();
      Catcher.getInstance().updateConfig(
        debugConfig: config(container),
        profileConfig: config(container),
        releaseConfig: config(container),
      );

      try {
        container.read(serverTimeProvider.notifier).state = await NTP.now(
          timeout: const Duration(seconds: 1),
        );
      } on Exception catch (exception) {
        Catcher.reportCheckedError(exception, null);
      }

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: RootApp(await Routes.current(container)),
        ),
      );
      widgetsBinding
          .addPostFrameCallback((final _) => FlutterNativeSplash.remove());
    },
  );
}

/// The wrapper around [MaterialApp] to support hot reload.
class RootApp extends StatelessWidget {
  /// The wrapper around [MaterialApp] to support hot reload.
  const RootApp(this.route, {super.key});

  /// The current app's route.
  final Routes route;

  @override
  Widget build(final BuildContext context) => MaterialApp(
        title: 'Papaya',
        debugShowCheckedModeBanner: false,
        navigatorKey: Catcher.navigatorKey,
        locale: I18NLocale.enUS.locale,
        supportedLocales: I18NLocale.values.map((final _) => _.locale),
        localizationsDelegates: const <LocalizationsDelegate<Object?>>[
          I18NLocalizations.delegate,
        ],
        theme: ThemeData.from(
          useMaterial3: true,
          colorScheme: defaultColorScheme,
          textTheme: defaultTextTheme,
        ).custom,
        builder: (final BuildContext context, final Widget? child) {
          final ThemeData theme = Theme.of(context);
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaleFactor: 1),
            child: DefaultTextStyle(
              style: theme.textTheme.titleMedium ?? const TextStyle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              child: FlashTheme(
                flashBarTheme: FlashBarThemeData(
                  brightness: Brightness.light,
                  boxShadows: <BoxShadow>[boxShadow(Theme.of(context))],
                ),
                flashDialogTheme: FlashDialogThemeData(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  titleStyle: theme.textTheme.titleMedium,
                  contentStyle: theme.textTheme.bodyMedium,
                  backgroundColor: theme.colorScheme.surface,
                  constraints: BoxConstraints(
                    maxWidth: mediaQuery.size.width,
                    maxHeight: mediaQuery.size.height,
                  ),
                ),
                child: child!,
              ),
            ),
          );
        },
        useInheritedMediaQuery: true,
        initialRoute: route.name,
        onGenerateRoute: (final RouteSettings settings) =>
            settings.name != null ? Routes.from<void>(settings) : null,
      );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties..add(EnumProperty<Routes>('route', route)),
    );
  }
}
