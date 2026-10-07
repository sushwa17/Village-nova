import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_card.dart';

class AskVillageNovaScreen extends StatefulWidget {
  const AskVillageNovaScreen({super.key});

  @override
  State<AskVillageNovaScreen> createState() => _AskVillageNovaScreenState();
}

class _AskVillageNovaScreenState extends State<AskVillageNovaScreen> {
  final TextEditingController inputController = TextEditingController();
  final List<Map<String, dynamic>> messages = [
    {
      'isUser': false,
      'text': 'Good morning Ravi! 👋 I am your VillageNova companion. What would you like guidance on today?',
      'actions': [],
    },
    {
      'isUser': true,
      'text': 'What should I do on my farm today?',
      'actions': [],
    },
    {
      'isUser': false,
      'text': 'Your Soybean crop is currently at Day 42 (Vegetative stage). Here are your recommended actions for today:',
      'actions': [
        {'id': '1', 'title': '💧 Check soil moisture before evening rain', 'type': 'irrigation'},
        {'id': '2', 'title': '🌱 Inspect leaves for yellow mosaic spots', 'type': 'crop_health'},
        {'id': '3', 'title': '📷 Record a crop observation photo', 'type': 'observation'},
      ],
      'why': 'Rain is forecasted in Ananthagiri at 6:00 PM (14 mm). Checking moisture now prevents root over-saturation.',
      'source': 'Open-Meteo & PJTSAU Agriculture Advisory • Today 11:30 AM',
    },
  ];

  void handleSend(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      messages.add({'isUser': true, 'text': query, 'actions': []});
      inputController.clear();
    });

    // Simulate smart structured AI response
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        messages.add({
          'isUser': false,
          'text': 'I checked your farm records and today\'s local mandi rates for Vikarabad:',
          'actions': [
            {'id': '4', 'title': '💰 Mandi rate for Soybean: ₹4,850 / Quintal (+₹70 today)', 'type': 'mandi'},
            {'id': '5', 'title': '🌾 View nearest mandi arrivals (14 km)', 'type': 'navigation'},
          ],
          'why': 'Soybean demand is stable across Telangana APMC markets.',
          'source': 'AGMARKNET Mandi Price Feed • Updated 2 hours ago',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: AppColors.secondaryGold, size: 22),
            SizedBox(width: 8),
            Text(
              'Ask VillageNova',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Quick Prompts Bar
          _buildQuickPromptsBar(),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                if (msg['isUser'] as bool) {
                  return _buildUserBubble(msg['text'] as String);
                } else {
                  return _buildAIStructuredCard(msg);
                }
              },
            ),
          ),

          // Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    final prompts = [
      'What should I do today?',
      'Check mandi prices',
      'Pest on soybean leaves',
      'PM-KISAN status',
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return ActionChip(
            label: Text(prompts[i]),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreenDark),
            onPressed: () => handleSend(prompts[i]),
          );
        },
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildAIStructuredCard(Map<String, dynamic> msg) {
    final actions = (msg['actions'] as List<dynamic>?) ?? [];
    final why = msg['why'] as String?;
    final source = msg['source'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 24),
      child: StitchCard(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header
            Row(
              children: const [
                Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 18),
                SizedBox(width: 6),
                Text('VillageNova Guidance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg['text'] as String,
              style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textPrimary),
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('ACTIONS TO TAKE:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              ...actions.map((act) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            act['title'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryGreen),
                      ],
                    ),
                  )),
            ],

            if (why != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text('💡 Why: $why', style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E))),
              ),
            ],

            if (source != null) ...[
              const SizedBox(height: 10),
              Text('Source: $source', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.mic, color: AppColors.primaryGreen),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  hintText: 'Ask VillageNova...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: handleSend,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryGreen),
              onPressed: () => handleSend(inputController.text),
            ),
          ],
        ),
      ),
    );
  }
}
