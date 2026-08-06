import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

/// Production crash reporting (SHIP-01).
///
/// Captures Flutter framework errors, platform dispatcher errors, and
/// uncaught async zone errors. Scrubs secrets and likely conversation
/// payloads before any report leaves the device.
///
/// Not part of HCOS. Does not inspect Conversation stage content.
class CrashReporting {
  CrashReporting._();

  static bool _ready = false;

  /// Install global handlers and optionally initialize Sentry.
  ///
  /// When [AppConfig.sentryDsn] is empty, handlers still sanitize/present
  /// errors locally but do not upload.
  static Future<void> bootstrap({
    required FutureOr<void> Function() appRunner,
  }) async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(recordFlutterError(details));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(recordError(error, stack, fatal: true));
      return true;
    };

    final dsn = AppConfig.sentryDsn;
    if (dsn.isEmpty) {
      _ready = false;
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.enablePrintBreadcrumbs = false;
        options.tracesSampleRate = 0;
        options.environment = kReleaseMode ? 'production' : 'debug';
        options.beforeSend = (event, hint) => _scrubEvent(event);
      },
      appRunner: () async {
        _ready = true;
        await appRunner();
      },
    );
  }

  /// Zone error handler for [runZonedGuarded].
  static void zoneErrorHandler(Object error, StackTrace stack) {
    unawaited(recordError(error, stack, fatal: true));
  }

  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await recordError(
      details.exceptionAsString(),
      details.stack ?? StackTrace.empty,
      fatal: true,
      context: details.context?.toString(),
    );
  }

  static Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? context,
  }) async {
    final sanitizedError = sanitizeForReporting(error.toString());
    final sanitizedStack = sanitizeForReporting(stack.toString());
    final sanitizedContext =
        context == null ? null : sanitizeForReporting(context);

    if (!_ready || AppConfig.sentryDsn.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'CrashReporting(local): $sanitizedError'
          '${sanitizedContext == null ? '' : ' | $sanitizedContext'}',
        );
      }
      return;
    }

    await Sentry.captureException(
      StateError(sanitizedError),
      stackTrace: StackTrace.fromString(sanitizedStack),
      withScope: (scope) {
        if (sanitizedContext != null && sanitizedContext.isNotEmpty) {
          scope.setTag('error_context', _truncate(sanitizedContext, 180));
        }
        scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
        // Never attach user chat payloads or raw request bodies.
        scope.clearBreadcrumbs();
      },
    );
  }

  /// Removes secrets and likely private chat content from outbound text.
  static String sanitizeForReporting(String input) {
    var out = input;

    if (AppConfig.hasOpenAiApiKey) {
      out = out.replaceAll(AppConfig.openAiApiKey, '[REDACTED]');
    }
    if (AppConfig.hasRevenueCatApiKey) {
      out = out.replaceAll(AppConfig.revenueCatApiKey, '[REDACTED]');
    }
    if (AppConfig.hasSentryDsn) {
      out = out.replaceAll(AppConfig.sentryDsn, '[REDACTED]');
    }

    out = out.replaceAll(
      RegExp(r'sk-[A-Za-z0-9_\-]{10,}'),
      '[REDACTED_KEY]',
    );
    out = out.replaceAll(
      RegExp(r'appl_[A-Za-z0-9]+'),
      '[REDACTED_KEY]',
    );
    out = out.replaceAll(
      RegExp(r'https://[a-z0-9]+\.ingest\.[^\s"]+', caseSensitive: false),
      '[REDACTED_DSN]',
    );
    out = out.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
      'Bearer [REDACTED]',
    );
    out = out.replaceAll(
      RegExp(r'"content"\s*:\s*".*?"', dotAll: true),
      '"content":"[REDACTED]"',
    );
    out = out.replaceAll(
      RegExp(r'"messages"\s*:\s*\[.*?\]', dotAll: true),
      '"messages":["[REDACTED]"]',
    );
    out = out.replaceAll(
      RegExp(r'Authorization:\s*[^\s]+', caseSensitive: false),
      'Authorization:[REDACTED]',
    );

    return _truncate(out, 4000);
  }

  static SentryEvent? _scrubEvent(SentryEvent event) {
    final message = event.message?.formatted;
    final scrubbedMessage = message == null
        ? null
        : SentryMessage(sanitizeForReporting(message));

    final scrubbedExceptions = event.exceptions
        ?.map(
          (item) => item.copyWith(
            value: item.value == null
                ? null
                : sanitizeForReporting(item.value!),
          ),
        )
        .toList();

    return event.copyWith(
      message: scrubbedMessage ?? event.message,
      exceptions: scrubbedExceptions ?? event.exceptions,
      user: null,
      breadcrumbs: const [],
    );
  }

  static String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }
}
