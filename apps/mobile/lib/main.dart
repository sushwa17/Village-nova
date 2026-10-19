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

void main() async {
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
              child: WelcomeScreen(
                onGetStarted: () => setState(() => _currentScreen = 'phone_auth'),
              ),
            ),
          if (_currentScreen == 'phone_auth')
            MaterialPage(
              child: PhoneAuthScreen(
                onAuthSuccess: () => setState(() => _currentScreen = 'onboarding'),
              ),
            ),
          if (_currentScreen == 'onboarding')
            MaterialPage(
              child: OnboardingScreen(
                onOnboardingComplete: () => setState(() => _currentScreen = 'home'),
              ),
            ),
          if (_currentScreen == 'home')
            MaterialPage(
              child: HomeScreen(
                onOpenAskAI: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AskVillageNovaScreen()),
                  );
                },
                onOpenMySpace: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MySpaceScreen()),
                  );
                },
                onOpenVillage: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyVillageScreen()),
                  );
                },
                onOpenSchemes: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schemes: PM-KISAN and PMFBY matches')),
                  );
                },
              ),
            ),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) return false;
          if (_currentScreen == 'phone_auth') {
            setState(() => _currentScreen = 'welcome');
          } else if (_currentScreen == 'onboarding') {
            setState(() => _currentScreen = 'phone_auth');
          }
          return true;
        },
      ),
    );
  }
}
