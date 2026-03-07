import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'firebase/firebase_init.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness:            Brightness.dark,
      statusBarIconBrightness:        Brightness.light,
      systemNavigationBarColor:       Color(0xFF181C27),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase ───────────────────────────────────────────────────
  await initFirebase();

  runApp(
    const ProviderScope(child: LobbyApp()),
  );
}

class LobbyApp extends StatelessWidget {
  const LobbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuildChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Listens to the Firebase auth stream and routes accordingly:
///   - signed in  → AppShell (main app)
///   - signed out → LoginScreen
///   - loading    → splash screen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      // ── Loading / initialising ─────────────────────────────────
      loading: () => const _SplashScreen(),

      // ── Error (rare — Firebase init failure) ──────────────────
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Center(
          child: Text(
            'Failed to connect. Please restart the app.',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ),

      // ── Auth resolved ──────────────────────────────────────────
      data: (user) {
        if (user != null) {
          return const AppShell();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.accentHover],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('⚔️', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}