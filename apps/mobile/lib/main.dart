import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/core/theme/app_theme.dart';
import 'package:villagenova/features/auth/presentation/screens/welcome_screen.dart';
import 'package:villagenova/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:villagenova/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:villagenova/features/home/presentation/screens/home_screen.dart';
import 'package:villagenova/features/ask/presentation/screens/ask_screen.dart';
import 'package:villagenova/features/space/presentation/screens/my_space_screen.dart';
import 'package:villagenova/features/village/presentation/screens/my_village_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: VillageNovaApp(),
    ),
  );
}

class VillageNovaApp extends StatefulWidget {
  const VillageNovaApp({super.key});

  @override
  State<VillageNovaApp> createState() => _VillageNovaAppState();
}

class _VillageNovaAppState extends State<VillageNovaApp> {
  // Navigation State for Prototype
  String _currentScreen = 'welcome'; // welcome -> phone_auth -> onboarding -> home

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VillageNova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Navigator(
        pages: [
          if (_currentScreen == 'welcome')
            MaterialPage(
              key: const ValueKey('welcome'),
              child: WelcomeScreen(
                onGetStarted: () => setState(() => _currentScreen = 'phone_auth'),
              ),
            ),
          if (_currentScreen == 'phone_auth')
            MaterialPage(
              key: const ValueKey('phone_auth'),
              child: PhoneAuthScreen(
                onAuthSuccess: () => setState(() => _currentScreen = 'onboarding'),
              ),
            ),
          if (_currentScreen == 'onboarding')
            MaterialPage(
              key: const ValueKey('onboarding'),
              child: OnboardingScreen(
                onOnboardingComplete: () => setState(() => _currentScreen = 'home'),
              ),
            ),
          if (_currentScreen == 'home')
            MaterialPage(
              key: const ValueKey('home'),
              child: Builder(
                builder: (homeContext) => HomeScreen(
                  onOpenAskAI: () => Navigator.of(homeContext).push(
                    MaterialPageRoute(builder: (_) => const AskVillageNovaScreen()),
                  ),
                  onOpenMySpace: () => Navigator.of(homeContext).push(
                    MaterialPageRoute(builder: (_) => const MySpaceScreen()),
                  ),
                  onOpenVillage: () => Navigator.of(homeContext).push(
                    MaterialPageRoute(builder: (_) => const MyVillageScreen()),
                  ),
                  onOpenSchemes: () {
                    ScaffoldMessenger.of(homeContext).showSnackBar(
                      const SnackBar(content: Text('Schemes: PM-KISAN and PMFBY matches')),
                    );
                  },
                ),
              ),
            ),
        ],
        onDidRemovePage: (page) {
          if (page.key == const ValueKey('phone_auth') &&
              _currentScreen == 'phone_auth') {
            setState(() => _currentScreen = 'welcome');
          } else if (page.key == const ValueKey('onboarding') &&
              _currentScreen == 'onboarding') {
            setState(() => _currentScreen = 'phone_auth');
          }
        },
      ),
    );
  }
}
