import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../config/theme.dart';

/// Full-screen AR viewer for furniture products.
///
/// Uses Google's <model-viewer> under the hood:
///  • On Android → taps "AR" to open Scene Viewer (ARCore)
///  • On iOS     → taps "AR" to open AR Quick Look
///  • On Web     → uses WebXR if the browser supports it
///
/// Features:
///  • Live 3D model display with auto-rotate
///  • Color variant switcher — changes material color in real time via JS
///  • "View in Your Room" AR button
class ArViewScreen extends StatefulWidget {
  final Product product;
  const ArViewScreen({super.key, required this.product});

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // WebView controller for JS color injection
  dynamic _wvController;

  // Currently selected color hex
  String _selectedHex = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Apply color via JavaScript ──────────────────────────────
  void _applyColor(String hex) {
    setState(() => _selectedHex = hex);
    final cleanHex = hex.replaceAll('#', '');
    final js = '''
      (function() {
        try {
          const mv = document.querySelector('model-viewer');
          if (!mv || !mv.model) return;
          const r = parseInt('${cleanHex.substring(0, 2)}', 16) / 255;
          const g = parseInt('${cleanHex.substring(2, 4)}', 16) / 255;
          const b = parseInt('${cleanHex.substring(4, 6)}', 16) / 255;
          mv.model.materials.forEach(function(mat) {
            mat.pbrMetallicRoughness.setBaseColorFactor([r, g, b, 1.0]);
          });
        } catch(e) { console.log('Color change error: ' + e); }
      })();
    ''';
    try {
      _wvController?.runJavaScript(js);
    } catch (_) {}
  }

  // ── Parse hex safely ───────────────────────────────────────
  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return Colors.grey;
  }

  /// Fall-back: Open the .glb URL in Scene Viewer directly via intent
  Future<void> _openSceneViewer() async {
    final modelUrl = widget.product.arModel;
    if (modelUrl == null) return;

    final sceneViewerUrl = Uri.parse(
      'https://arvr.google.com/scene-viewer/1.0'
      '?file=${Uri.encodeComponent(modelUrl)}'
      '&mode=ar_preferred'
      '&title=${Uri.encodeComponent(widget.product.name)}'
      '&link=${Uri.encodeComponent(modelUrl)}',
    );

    if (await canLaunchUrl(sceneViewerUrl)) {
      await launchUrl(sceneViewerUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AR is not supported on this device'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p         = widget.product;
    final modelUrl  = p.arModel ?? '';
    final posterUrl = p.imageUrl ?? '';
    final colors    = p.colorVariants;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AR View',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text(p.name,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          if (!kIsWeb)
            IconButton(
              tooltip: 'Open in Scene Viewer',
              onPressed: _openSceneViewer,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.open_in_new_rounded,
                    color: AppTheme.accent, size: 18),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // ── Model Viewer (3D + AR) ──
          Positioned.fill(
            child: ModelViewer(
              backgroundColor: const Color(0xFF080808),
              src: modelUrl,
              alt: p.name,
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: true,
              cameraControls: true,
              shadowIntensity: 1.2,
              exposure: 0.9,
              poster: posterUrl.isNotEmpty ? posterUrl : null,
              loading: Loading.auto,
              autoPlay: true,
              disableZoom: false,
              onWebViewCreated: (controller) {
                _wvController = controller;
              },
              innerModelViewerHtml: '''
                <style>
                  button[slot="ar-button"] {
                    background: linear-gradient(135deg, #C9A96E 0%, #A88B4A 100%);
                    color: #0A0A0A;
                    border: none;
                    border-radius: 16px;
                    padding: 14px 28px;
                    font-size: 15px;
                    font-weight: 700;
                    font-family: 'Inter', sans-serif;
                    cursor: pointer;
                    position: absolute;
                    bottom: 120px;
                    left: 50%;
                    transform: translateX(-50%);
                    box-shadow: 0 8px 32px rgba(201, 169, 110, 0.4);
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    z-index: 10;
                  }
                  button[slot="ar-button"]:active {
                    transform: translateX(-50%) scale(0.96);
                  }
                </style>
                <button slot="ar-button">
                  📱 View in Your Room
                </button>
              ''',
            ),
          ),

          // ── Loading Overlay ──
          if (_loading)
            Container(
              color: const Color(0xFF080808),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accent.withValues(alpha: 0.25),
                              AppTheme.accent.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.view_in_ar_rounded,
                            color: AppTheme.accent, size: 40),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Loading 3D Model...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Preparing AR experience',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(
                        backgroundColor:
                            AppTheme.accent.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accent),
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom Info + Color Picker Card ──
          if (!_loading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Color Picker (only if product has color variants) ──
                    if (colors.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.palette_rounded,
                                    color: AppTheme.accent, size: 16),
                                const SizedBox(width: 8),
                                const Text('Change Color',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                if (_selectedHex.isNotEmpty)
                                  Text(
                                    colors
                                        .firstWhere(
                                          (c) => c.hex == _selectedHex,
                                          orElse: () => colors.first,
                                        )
                                        .name,
                                    style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: colors.map((cv) {
                                  final isSelected = _selectedHex == cv.hex;
                                  return GestureDetector(
                                    onTap: () => _applyColor(cv.hex),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 10),
                                      child: Column(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: isSelected ? 38 : 32,
                                            height: isSelected ? 38 : 32,
                                            decoration: BoxDecoration(
                                              color: _hexToColor(cv.hex),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppTheme.accent
                                                    : Colors.white24,
                                                width: isSelected ? 3 : 1.5,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: _hexToColor(cv.hex)
                                                            .withValues(alpha: 0.5),
                                                        blurRadius: 12,
                                                        spreadRadius: 2,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 16)
                                                : null,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cv.name,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                              fontSize: 10,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Instructions Card ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.touch_app_rounded,
                                color: AppTheme.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Interact with the 3D model',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text(
                                    'Pinch to zoom • Drag to rotate • Tap AR button to place in room',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
