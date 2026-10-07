import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_button.dart';

class PhoneAuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const PhoneAuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isOtpSent = false;
  bool isLoading = false;

  void handleSendOtp() async {
    if (phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => isLoading = true);
    // Simulate / Trigger Supabase Phone OTP send
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      isLoading = false;
      isOtpSent = true;
    });
  }

  void handleVerifyOtp() async {
    if (otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP received via SMS')),
      );
      return;
    }

    setState(() => isLoading = true);
    // Simulate / Verify Supabase OTP
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => isLoading = false);
    widget.onAuthSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Resident Sign In'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                isOtpSent ? 'Enter OTP Code' : 'Enter Mobile Number',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOtpSent
                    ? 'We sent an SMS verification code to +91 ${phoneController.text}'
                    : 'We will send you a one-time OTP to log in securely.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              if (!isOtpSent) ...[
                // Phone Number Input
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixText: '+91  ',
                    prefixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    hintText: '9876543210',
                    counterText: '',
                    labelText: 'Mobile Number',
                  ),
                ),
                const SizedBox(height: 24),
                StitchButton(
                  text: 'Send OTP SMS',
                  isLoading: isLoading,
                  onPressed: handleSendOtp,
                ),
              ] else ...[
                // OTP Input
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                    labelText: '6-digit OTP',
                  ),
                ),
                const SizedBox(height: 24),
                StitchButton(
                  text: 'Verify & Continue',
                  isLoading: isLoading,
                  onPressed: handleVerifyOtp,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isOtpSent = false;
                        otpController.clear();
                      });
                    },
                    child: const Text('Change Mobile Number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
