import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    context.read<ChatProvider>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final currFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      width: 400,
      height: 560,
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.gold, AppTheme.goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: AppTheme.bgDark, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VisionFurnish AI',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.bgDark)),
                        Text('Furniture Assistant',
                          style: TextStyle(fontSize: 11, color: Color(0x99000000))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: AppTheme.bgDark),
                    onPressed: () => chat.clearChat(),
                    tooltip: 'Clear chat',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Messages ──
            Expanded(
              child: chat.messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        // Typing indicator at top (index 0 when reversed)
                        if (chat.isLoading && i == 0) return _buildTypingIndicator();
                        final msg = chat.messages[chat.isLoading ? i - 1 : i];
                        return _buildMessage(msg, currFmt);
                      },
                    ),
            ),

            // ── Input ──
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(top: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Ask about furniture...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: chat.isLoading ? null : _send,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: chat.isLoading ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.bgDark,
                        ),
                      ),
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

  // ── Welcome screen ──
  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppTheme.gold, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Hi! I\'m VisionFurnish AI 👋',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Ask me anything about furniture!',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _quickAction('🛋️ Sofas under ₹50K'),
                _quickAction('🪑 Modern chairs'),
                _quickAction('⭐ Featured picks'),
                _quickAction('🛏️ Wooden beds'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label) {
    return InkWell(
      onTap: () {
        _textCtrl.text = label.replaceAll(RegExp(r'[^\w\s₹]'), '').trim();
        _send();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ),
    );
  }

  // ── Typing indicator ──
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppTheme.gold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0), const SizedBox(width: 4),
                _dot(1), const SizedBox(width: 4),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (ctx, val, child) {
        return Opacity(
          opacity: 0.3 + 0.7 * val,
          child: Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }

  // ── Message bubble ──
  Widget _buildMessage(ChatMessage msg, NumberFormat currFmt) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppTheme.gold),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.gold : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isUser ? 14 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 14),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUser ? AppTheme.bgDark : AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                // Product cards
                if (msg.products != null && msg.products!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: msg.products!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => _buildProductCard(msg.products![i], currFmt),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── Product card ──
  Widget _buildProductCard(ChatProduct p, NumberFormat currFmt) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            child: p.image != null && p.image!.isNotEmpty
                ? Image.network(p.image!, height: 70, width: 180, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 70, width: 180, color: AppTheme.surfaceDark,
                      child: const Icon(Icons.image_rounded, color: AppTheme.textSecondary, size: 24),
                    ))
                : Container(
                    height: 70, width: 180, color: AppTheme.surfaceDark,
                    child: const Icon(Icons.image_rounded, color: AppTheme.textSecondary, size: 24),
                  ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(currFmt.format(p.discountPrice ?? p.price),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.gold)),
                    if (p.discountPrice != null) ...[
                      const SizedBox(width: 4),
                      Text(currFmt.format(p.price),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary,
                          decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
