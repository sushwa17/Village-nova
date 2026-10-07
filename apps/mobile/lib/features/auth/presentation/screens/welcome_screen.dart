import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_button.dart';
import 'package:villagenova/widgets/stitch_chip.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String selectedLanguage = 'te'; // Default Telugu (or English/Hindi)

  final List<Map<String, String>> languages = [
    {'code': 'en', 'label': 'English', 'native': 'English'},
    {'code': 'hi', 'label': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'te', 'label': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'kn', 'label': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'mr', 'label': 'Marathi', 'native': 'मराठी'},
    {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // App Brand Header
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primaryGreenLight, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: 54,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VillageNova',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your personalized companion for your farm, village, education, and public services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),

              // Language Selector Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Language / భాషను ఎంచుకోండి',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Language Grid / Wrap
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: languages.map((lang) {
                  final isSelected = selectedLanguage == lang['code'];
                  return StitchSelectableChip(
                    label: '${lang['native']} (${lang['label']})',
                    isSelected: isSelected,
                    onSelected: () {
                      setState(() {
                        selectedLanguage = lang['code']!;
                      });
                    },
                  );
                }).toList(),
              ),

              const Spacer(),

              // Get Started Action
              StitchButton(
                text: 'Get Started →',
                onPressed: widget.onGetStarted,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
