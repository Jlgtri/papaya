import 'dart:async';

import 'package:catcher/catcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:ntp/ntp.dart';

import 'src/providers/misc.dart';
import 'src/routes.dart';
import 'src/utils/catcher.dart';

CatcherOptions _config([final ProviderContainer? container]) => CatcherOptions(
      container != null ? RiverpodReportMode(container) : SilentReportMode(),
      <ReportHandler>[ConsoleHandler()],
      logger: ChangedCatcherLogger(),
    );
Future<DateTime?> get _serverTime async {
  try {
    return await NTP.now(timeout: const Duration(seconds: 1));
  } on Exception catch (exception) {
    Catcher.reportCheckedError(exception, null);
  }
  return null;
}

void main() => Catcher(
      debugConfig: _config(),
      profileConfig: _config(),
      releaseConfig: _config(),
      runAppFunction: () async {
        final WidgetsBinding widgetsBinding =
            WidgetsFlutterBinding.ensureInitialized();
        FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        DateTime? serverTime = await _serverTime;
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            serverTimeProvider.overrideWith(
              (final _) => serverTime != null
                  ? ServerTimeNotifier(serverTime!)
                  : throw Exception(),
            ),
          ],
        );

        Catcher.getInstance().updateConfig(
          debugConfig: _config(container),
          profileConfig: _config(container),
          releaseConfig: _config(container),
        );

        if (serverTime == null) {
          late final StreamSubscription<InternetConnectionStatus> subscription;
          subscription = InternetConnectionChecker()
              .onStatusChange
              .listen((final InternetConnectionStatus status) async {
            if (status == InternetConnectionStatus.connected) {
              if ((serverTime = await _serverTime) != null) {
                container.updateOverrides(<Override>[
                  serverTimeProvider.overrideWith(
                    (final _) => ServerTimeNotifier(serverTime!),
                  ),
                ]);
                await subscription.cancel();
              }
            }
          });
        }

        runApp(
          UncontrolledProviderScope(
            container: container,
            child: RoutesApp(await Routes.current(container)),
          ),
        );
        widgetsBinding
            .addPostFrameCallback((final _) => FlutterNativeSplash.remove());
      },
    );
