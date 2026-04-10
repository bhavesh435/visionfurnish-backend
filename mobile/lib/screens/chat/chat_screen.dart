import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../product/product_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    context.read<ChatProvider>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded, size: 18, color: AppTheme.bgPrimary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VisionFurnish AI', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(chat.isLoading ? 'Typing...' : 'Online', style: GoogleFonts.inter(fontSize: 11, color: chat.isLoading ? AppTheme.accent : AppTheme.success)),
              ],
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.delete_sweep_rounded, size: 22), onPressed: () => chat.clearChat())],
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Messages
          Expanded(
            child: chat.messages.isEmpty
                ? _welcomeView()
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (chat.isLoading && i == 0) return _typing();
                      final msg = chat.messages[chat.isLoading ? i - 1 : i];
                      return _bubble(msg, fmt);
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            decoration: const BoxDecoration(color: AppTheme.bgCard, border: Border(top: BorderSide(color: AppTheme.divider))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(hintText: 'Ask about furniture...', border: InputBorder.none, filled: false, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                    maxLines: 2, minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: chat.isLoading ? null : _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.send_rounded, size: 20, color: AppTheme.bgPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _welcomeView() => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.smart_toy_rounded, size: 32, color: AppTheme.accent),
        ),
        const SizedBox(height: 20),
        Text('Hi! I\'m VisionFurnish AI 👋', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text('Ask me anything about furniture!', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _chip('🛋️ Sofas under ₹50K'),
          _chip('🪑 Modern chairs'),
          _chip('⭐ Best sellers'),
          _chip('🛏️ Wooden beds'),
        ]),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _chip(String label) => GestureDetector(
    onTap: () { _textCtrl.text = label.replaceAll(RegExp(r'[^\w\s₹]'), '').trim(); _send(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.divider)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
    ),
  );

  Widget _typing() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppTheme.accent)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Container(
          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
          width: 6, height: 6,
          decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3)),
        ))),
      ),
    ]),
  );

  Widget _bubble(ChatMessage msg, NumberFormat fmt) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppTheme.accent)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.accent : AppTheme.bgCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(msg.content, style: GoogleFonts.inter(fontSize: 14, color: isUser ? AppTheme.bgPrimary : AppTheme.textPrimary, height: 1.4)),
                ),
                // Product cards
                if (msg.products != null && msg.products!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: msg.products!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => _productMini(msg.products![i], fmt),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _productMini(Product p, NumberFormat fmt) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
    child: Container(
      width: 130,
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: p.imageUrl != null
                  ? CachedNetworkImage(imageUrl: p.imageUrl!, width: 130, fit: BoxFit.cover)
                  : Container(color: AppTheme.bgSurface, child: const Icon(Icons.image, color: AppTheme.textMuted)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(fmt.format(p.effectivePrice), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accent)),
            ]),
          ),
        ],
      ),
    ),
  );
}
