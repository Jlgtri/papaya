import 'package:catcher/catcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/routes.dart';
import 'src/utils/catcher.dart';

CatcherOptions _config([final ProviderContainer? container]) => CatcherOptions(
      container != null ? RiverpodReportMode(container) : SilentReportMode(),
      <ReportHandler>[ConsoleHandler()],
      logger: ChangedCatcherLogger(),
    );

void main() => Catcher(
      debugConfig: _config(),
      profileConfig: _config(),
      releaseConfig: _config(),
      runAppFunction: () async {
        final WidgetsBinding widgetsBinding =
            WidgetsFlutterBinding.ensureInitialized();
        FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
        final ProviderContainer container = ProviderContainer();
        Catcher.getInstance().updateConfig(
          debugConfig: _config(container),
          profileConfig: _config(container),
          releaseConfig: _config(container),
        );
        try {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        } on Exception catch (error, stackTrace) {
          Catcher.reportCheckedError(error, stackTrace);
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
