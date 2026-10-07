import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_button.dart';
import 'package:villagenova/widgets/stitch_card.dart';
import 'package:villagenova/widgets/stitch_chip.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({
    super.key,
    required this.onOnboardingComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 1;

  // Step 1: Resident Info & Location
  final TextEditingController nameController = TextEditingController(text: 'Ravi Kumar');
  String selectedVillage = 'Ananthagiri (Vikarabad)';

  // Step 2: Roles (Multi-select)
  final Set<String> selectedRoles = {'farmer'};

  // Step 3: Farmer Profile (if farmer selected)
  final TextEditingController landController = TextEditingController(text: '2.5');
  String selectedSoil = 'black';
  String selectedWater = 'borewell';
  String selectedCrop = 'Soybean';

  final List<Map<String, String>> availableRoles = [
    {'id': 'farmer', 'label': 'Farmer', 'emoji': '🌾'},
    {'id': 'cattle_owner', 'label': 'Cattle Owner', 'emoji': '🐄'},
    {'id': 'student', 'label': 'Student', 'emoji': '🎓'},
    {'id': 'job_seeker', 'label': 'Job Seeker', 'emoji': '💼'},
    {'id': 'business_owner', 'label': 'Small Business', 'emoji': '🏪'},
    {'id': 'shg_livelihood', 'label': 'SHG / Livelihood', 'emoji': '👩'},
    {'id': 'resident_family', 'label': 'Resident', 'emoji': '👨‍👩‍👧'},
  ];

  final List<Map<String, String>> soilTypes = [
    {'id': 'black', 'label': 'Black Soil'},
    {'id': 'red', 'label': 'Red Soil'},
    {'id': 'loamy', 'label': 'Loamy Soil'},
    {'id': 'clay', 'label': 'Clay Soil'},
    {'id': 'sandy', 'label': 'Sandy Soil'},
    {'id': 'unknown', 'label': "I don't know"},
  ];

  final List<String> waterSources = ['Borewell', 'Canal', 'Rainfed', 'Tank', 'Other'];
  final List<String> commonCrops = ['Soybean', 'Cotton', 'Paddy / Rice', 'Wheat', 'Maize', 'Chili', 'Gram'];

  void nextStep() {
    if (currentStep == 1) {
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name')),
        );
        return;
      }
      setState(() => currentStep = 2);
    } else if (currentStep == 2) {
      if (selectedRoles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one role that describes you')),
        );
        return;
      }
      if (selectedRoles.contains('farmer')) {
        setState(() => currentStep = 3);
      } else {
        widget.onOnboardingComplete();
      }
    } else if (currentStep == 3) {
      widget.onOnboardingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Step $currentStep of ${selectedRoles.contains('farmer') ? 3 : 2}'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: currentStep > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: currentStep / (selectedRoles.contains('farmer') ? 3.0 : 2.0),
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                borderRadius: BorderRadius.circular(6),
                minHeight: 6,
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStepView(),
                ),
              ),

              const SizedBox(height: 16),
              StitchButton(
                text: currentStep == 3 || (!selectedRoles.contains('farmer') && currentStep == 2)
                    ? 'Complete & Open VillageNova →'
                    : 'Next Step →',
                onPressed: nextStep,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    if (currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where do you live?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'We personalize recommendations based on your local village climate and panchayat.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Your Full Name'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedVillage,
            decoration: const InputDecoration(labelText: 'Select Village'),
            items: [
              'Ananthagiri (Vikarabad)',
              'Kondurg (Shadnagar)',
              'Pardi (Wardha)',
              'Other Village',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedVillage = val);
            },
          ),
        ],
      );
    } else if (currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What describes you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select all that apply. Your dashboard changes based on who you are.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableRoles.map((role) {
              final isSelected = selectedRoles.contains(role['id']);
              return StitchSelectableChip(
                label: role['label']!,
                emoji: role['emoji'],
                isSelected: isSelected,
                onSelected: () {
                  setState(() {
                    if (isSelected) {
                      selectedRoles.remove(role['id']);
                    } else {
                      selectedRoles.add(role['id']!);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      );
    } else {
      // Step 3: Farmer Setup
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your farm',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'VillageNova uses this to predict crop stages, irrigation needs, and fertilizer schedules.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: landController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Farm Land (Acres)',
              suffixText: 'Acres',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'What soil do you have?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: soilTypes.map((soil) {
              final isSelected = selectedSoil == soil['id'];
              return StitchSelectableChip(
                label: soil['label']!,
                isSelected: isSelected,
                onSelected: () => setState(() => selectedSoil = soil['id']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedWater,
            decoration: const InputDecoration(labelText: 'Primary Water Source'),
            items: waterSources
                .map((w) => DropdownMenuItem(value: w.toLowerCase(), child: Text(w)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedWater = val);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCrop,
            decoration: const InputDecoration(labelText: 'Current Main Crop'),
            items: commonCrops
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedCrop = val);
            },
          ),
          const SizedBox(height: 16),
          StitchCard(
            backgroundColor: const Color(0xFFF1F8E9),
            borderColor: AppColors.primaryGreenLight,
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ready! Sowing date will default to the current active season for $selectedCrop.',
                    style: const TextStyle(fontSize: 13, color: AppColors.primaryGreenDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
