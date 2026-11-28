import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';
import 'package:villagenova/widgets/stitch_card.dart';
import 'package:villagenova/widgets/stitch_action_card.dart';
import 'package:villagenova/widgets/stitch_citation_card.dart';
import 'package:villagenova/widgets/stitch_badge.dart';
import 'package:villagenova/providers/ask_provider.dart';

class AskVillageNovaScreen extends ConsumerStatefulWidget {
  const AskVillageNovaScreen({super.key});

  @override
  ConsumerState<AskVillageNovaScreen> createState() => _AskVillageNovaScreenState();
}

class _AskVillageNovaScreenState extends ConsumerState<AskVillageNovaScreen> {
  final TextEditingController inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void handleSend(String query) {
    if (query.trim().isEmpty) return;
    inputController.clear();
    ref.read(askProvider.notifier).sendQuery(query);
  }

  void _showDocumentDetailsModal(BuildContext context, Map<String, dynamic> source) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StitchBadge(
                  label: 'Verified Knowledge Source ✓',
                  variant: StitchBadgeVariant.verified,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              source['title'] as String? ?? 'Official Document',
              style: StitchTokens.title,
            ),
            const SizedBox(height: 6),
            Text(
              'Authority: ${source['source_type'] ?? "Official Government / University Portal"}',
              style: StitchTokens.bodyMedium.copyWith(color: StitchTokens.green700),
            ),
            if (source['timestamp'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Published / Verified: ${source['timestamp']}',
                style: StitchTokens.caption,
              ),
            ],
            if (source['url'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StitchTokens.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StitchTokens.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: StitchTokens.slate600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source['url'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back to Conversation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final askState = ref.watch(askProvider);
    final messages = askState.messages;
    final isLoading = askState.isLoading;
    final isOffline = askState.isOffline;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.secondaryGold, size: 22),
            SizedBox(width: 8),
            Text(
              'Ask VillageNova',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Network Offline Toggle
          IconButton(
            tooltip: isOffline ? 'Switch to Online' : 'Simulate Offline',
            icon: Icon(
              isOffline ? Icons.wifi_off : Icons.wifi,
              color: isOffline ? Colors.amberAccent : Colors.white70,
              size: 20,
            ),
            onPressed: () {
              ref.read(askProvider.notifier).toggleOfflineMode(!isOffline);
            },
          ),
          // Clear Conversation
          IconButton(
            tooltip: 'Clear Chat History',
            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
            onPressed: () {
              ref.read(askProvider.notifier).clearConversation();
            },
          ),
        ],
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Offline Banner Indicator
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: StitchTokens.gold100,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: StitchTokens.gold900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Working in Offline Mode. Messages will be queued and sent when connected.',
                      style: StitchTokens.caption.copyWith(color: StitchTokens.gold900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Quick Prompts Bar
          _buildQuickPromptsBar(),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16, right: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'VillageNova is thinking...',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final msg = messages[index];
                if (msg.isUser) {
                  return _buildUserBubble(msg);
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
    const prompts = [
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

  Widget _buildUserBubble(ChatMessageItem msg) {
    final isPending = msg.status == MessageStatus.pending;
    final isFailed = msg.status == MessageStatus.failed;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isPending ? Colors.grey.shade600 : AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4)),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 4),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 12, color: StitchTokens.gold600),
                  SizedBox(width: 4),
                  Text('Queued (Offline)', style: TextStyle(fontSize: 10, color: StitchTokens.gold600, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            if (isFailed) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => ref.read(askProvider.notifier).retryMessage(msg.id),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 12, color: StitchTokens.rose700),
                    SizedBox(width: 4),
                    Text('Failed • Tap to Retry', style: TextStyle(fontSize: 10, color: StitchTokens.rose700, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIStructuredCard(ChatMessageItem msg) {
    final actions = msg.actions;
    final why = msg.whyAdvisory;
    final sources = msg.sources;
    final fallbackSource = msg.sourceCitation;
    final latency = msg.latencyMs;
    final isCached = msg.cached;

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 24),
      child: StitchCard(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header & Performance Telemetry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 18),
                    SizedBox(width: 6),
                    Text('VillageNova Guidance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                  ],
                ),
                if (isCached)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: StitchTokens.green50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: StitchTokens.green200),
                    ),
                    child: Text('⚡ ${latency ?? 35}ms (Cached)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: StitchTokens.green800)),
                  )
                else if (latency != null)
                  Text('⏱️ ${latency}ms', style: const TextStyle(fontSize: 10, color: StitchTokens.slate400, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textPrimary),
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'ACTIONS TO TAKE:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: StitchTokens.slate500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              ...actions.map((act) => StitchActionCard(
                    title: act['title'] as String? ?? 'Action',
                    badgeLabel: act['type'] as String? ?? act['action_type'] as String?,
                    badgeVariant: StitchBadgeVariant.agriculture,
                    onTap: () => ref.read(askProvider.notifier).executeAction(act),
                  )),
            ],

            if (why != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StitchTokens.gold50,
                  borderRadius: BorderRadius.circular(StitchTokens.radiusSm),
                  border: Border.all(color: StitchTokens.gold200),
                ),
                child: Text(
                  '💡 Why: $why',
                  style: StitchTokens.body.copyWith(
                    fontSize: 12.5,
                    color: StitchTokens.gold900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            if (sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'OFFICIAL VERIFIED SOURCES:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: StitchTokens.slate500,
                  letterSpacing: 0.4,
                ),
              ),
              ...sources.map((s) => StitchCitationCard(
                    title: s['title'] as String? ?? 'Official Advisory',
                    sourceType: s['source_type'] as String? ?? 'Agricultural Advisory',
                    timestamp: s['timestamp'] as String? ?? 'Kharif 2026',
                    url: s['url'] as String?,
                    onTap: () => _showDocumentDetailsModal(context, s),
                  )),
            ] else if (fallbackSource != null) ...[
              const SizedBox(height: 10),
              StitchCitationCard(
                title: fallbackSource,
                sourceType: 'PJTSAU / Official Registry',
                timestamp: 'Kharif 2026',
              ),
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
