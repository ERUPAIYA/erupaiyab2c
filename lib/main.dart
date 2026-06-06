import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:upgrader/upgrader.dart';

// import 'package:no_screenshot/no_screenshot.dart';

import 'router.dart';
import 'services/app_lock_service.dart';
import 'services/location_service.dart';
import 'services/push_notification_service.dart';
import 'widgets/app_snackbar.dart';
import 'widgets/custom_upgrader_messages.dart';
import 'widgets/k_dialog.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  // NoScreenshot.instance.screenshotOff();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // Do not block first render on plugin/IO initialization; it can make the
  // native splash appear "stuck" on some devices (especially first install).
  Future.microtask(() async {
    try {
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: '.env');
      }
    } catch (_) {}
    try {
      await PushNotificationService.initialize(requestPermissions: false);
    } catch (_) {}
    try {
      await LocationService.initialize(requestPermission: false);
    } catch (_) {}
  });
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appLockService = ref.read(appLockServiceProvider);
    final upgrader = useMemoized(
      () => Upgrader(
        clientHeaders: const {
          // Helps Play Store HTML parsing on some networks/devices.
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        },
        // Show the dialog again immediately when a newer store version appears.
        // (No cooling-off window based on "Later" taps.)
        durationUntilAlertAgain: Duration.zero,
        debugLogging: kDebugMode,
        messages: CustomUpgraderMessages(),
        // Note: `debugDisplayAlways` makes the dialog show on every rebuild in
        // debug, which feels like a "loop" and can hide real force-update
        // behavior. Keep it disabled by default.
        debugDisplayAlways: false,
        willDisplayUpgrade: ({
          required bool display,
          String? installedVersion,
          UpgraderVersionInfo? versionInfo,
        }) {
          if (!kDebugMode) return;
          debugPrint(
            'upgrader: display=$display installed=$installedVersion store=${versionInfo?.appStoreVersion} min=${versionInfo?.minAppVersion}',
          );
        },
      ),
      const [],
    );
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
      return null;
    }, const []);
    useEffect(() {
      // Ensure upgrader is initialized once (some code paths throw if accessed
      // before initialize completes).
      Future.microtask(() {
        // ignore: discarded_futures
        upgrader.initialize();
      });
      return null;
    }, const []);
    useEffect(() {
      appLockService.init();
      // ScreenSecurityService.enableSecure();
      return appLockService.dispose;
    }, const []);
    useEffect(() {
      // Allows PushNotificationService to navigate after notification taps.
      PushNotificationService.markUiReady();
      return null;
    }, const []);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => appLockService.onUserActivity(),
            child: UpgradeAlert(
              upgrader: upgrader,
              showIgnore: false,
              // Force update when a newer Play Store/App Store version exists.
              showLater: false,
              barrierDismissible: false,
              navigatorKey: navigatorKey,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        title: 'eRupaiya',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.light().textTheme,
          ),
          primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.light().primaryTextTheme,
          ),
          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          extensions: const [
            SkeletonizerConfigData(),
          ],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.dark().textTheme,
          ),
          primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.dark().primaryTextTheme,
          ),
          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          extensions: const [
            SkeletonizerConfigData.dark(),
          ],
        ),
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
