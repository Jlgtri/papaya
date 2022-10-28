import 'dart:developer';

import 'package:catcher/catcher.dart';
import 'package:catcher/model/platform_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../providers/misc_providers.dart';

/// The report mode that sends report to the [errorProvider].
class RiverpodReportMode extends ReportMode {
  /// The report mode that sends report to the [errorProvider].
  RiverpodReportMode(this.container);

  /// The container used to access [errorProvider].
  final ProviderContainer container;

  @override
  Future<void> requestAction(
    final Report report,
    final BuildContext? context,
  ) async {
    container.read(errorProvider.notifier).state = report;
    super.onActionConfirmed(report);
  }

  @override
  bool isContextRequired() => false;

  @override
  List<PlatformType> getSupportedPlatforms() => PlatformType.values;
}

/// The [Logger] adapter for the [CatcherLogger].
class ChangedCatcherLogger extends CatcherLogger {
  @override
  void setup() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(
      (final LogRecord rec) => log(
        rec.message,
        time: rec.time,
        sequenceNumber: rec.sequenceNumber,
        level: rec.level.value,
        name: rec.loggerName,
        zone: rec.zone,
        error: rec.error,
        stackTrace: rec.stackTrace,
      ),
    );
  }
}
