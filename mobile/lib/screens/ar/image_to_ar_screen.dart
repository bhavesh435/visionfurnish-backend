import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../services/furniture_matcher_service.dart';

/// 3-step screen: Image Input → Processing → AR View
///
/// Step 1: User picks image from gallery or camera
/// Step 2: Processing animation (~2s) while we keyword-match the image
/// Step 3: Full ModelViewer with AR support + Screenshot FAB
class ImageToArScreen extends StatefulWidget {
  const ImageToArScreen({super.key});

  @override
  State<ImageToArScreen> createState() => _ImageToArScreenState();
}

enum _ArStep { pick, processing, view }

class _ImageToArScreenState extends State<ImageToArScreen>
    with TickerProviderStateMixin {
  _ArStep _step = _ArStep.pick;
  File? _pickedImage;
  FurnitureMatch? _match;
  final _picker = ImagePicker();
  final _screenshotCtrl = ScreenshotController();
  bool _modelLoading = true;
  bool _savingScreenshot = false;

  // Processing step animation
  int _processingStep = 0;
  static const _processingLabels = [
    'Analyzing image…',
    'Matching 3D model…',
    'Preparing AR scene…',
  ];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // Category selector
  String _selectedCategory = 'chair';

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile != null) _startProcessing(File(xFile.path));
  }

  Future<void> _pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (xFile != null) _startProcessing(File(xFile.path));
  }

  // ── Processing ───────────────────────────────────────────────────────────

  Future<void> _startProcessing(File image) async {
    setState(() {
      _pickedImage = image;
      _step = _ArStep.processing;
      _processingStep = 0;
    });

    // Animate through processing steps
    for (int i = 0; i < _processingLabels.length; i++) {
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() => _processingStep = i);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Match from filename keywords, fallback to selected category
    final match = FurnitureMatcher.matchFromImage(
      image,
      fallback: _selectedCategory,
    );

    setState(() {
      _match = match;
      _step = _ArStep.view;
      _modelLoading = true;
    });

    // Hide model-loading indicator after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _modelLoading = false);
    });
  }

  // ── Screenshot ───────────────────────────────────────────────────────────

  Future<void> _takeScreenshot() async {
    setState(() => _savingScreenshot = true);
    try {
      final bytes = await _screenshotCtrl.capture(pixelRatio: 2.0);
      if (bytes == null) throw Exception('Capture returned null');

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/ar_preview_$ts.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AR preview saved to app folder',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot failed: $e',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingScreenshot = false);
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void _reset() {
    setState(() {
      _step = _ArStep.pick;
      _pickedImage = null;
      _match = null;
      _modelLoading = true;
    });
    _fadeCtrl.forward(from: 0);
    _slideCtrl.forward(from: 0);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
            Text('Scan to AR',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            Text(_stepSubtitle,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        actions: [
          if (_step == _ArStep.view)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _reset,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded,
                        color: AppTheme.accent, size: 14),
                    const SizedBox(width: 4),
                    Text('Retry',
                        style: GoogleFonts.inter(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: switch (_step) {
          _ArStep.pick => _buildPickStep(),
          _ArStep.processing => _buildProcessingStep(),
          _ArStep.view => _buildArViewStep(),
        },
      ),
    );
  }

  String get _stepSubtitle => switch (_step) {
        _ArStep.pick => 'Step 1 of 3 — Upload furniture image',
        _ArStep.processing => 'Step 2 of 3 — Matching 3D model',
        _ArStep.view => 'Step 3 of 3 — View in AR',
      };

  // ── Step 1: Image Picker ─────────────────────────────────────────────────

  Widget _buildPickStep() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step progress
              _StepProgressBar(current: 0),
              const SizedBox(height: 24),

              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.12),
                      AppTheme.accentDark.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.25)),
                ),
                child: Column(children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accent.withValues(alpha: 0.3),
                            AppTheme.accentDark.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.view_in_ar_rounded,
                          color: AppTheme.accent, size: 44),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Upload Furniture Image',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or select from gallery.\nWe\'ll match it to a 3D model for AR viewing.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Category hint
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.category_rounded,
                            color: AppTheme.accent, size: 16),
                        const SizedBox(width: 8),
                        Text('Select furniture type (optional)',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FurnitureMatcher.catalogue.map((item) {
                          final selected = _selectedCategory == item.category;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedCategory = item.category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.accent.withValues(alpha: 0.2)
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.accent
                                      : Colors.white12,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                '${item.emoji} ${item.label}',
                                style: GoogleFonts.inter(
                                  color:
                                      selected ? AppTheme.accent : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(children: [
                Expanded(
                  child: _PickButton(
                    icon: Icons.photo_library_rounded,
                    label: 'From Gallery',
                    subtitle: 'Choose existing photo',
                    onTap: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    subtitle: 'Take a new photo',
                    onTap: _pickFromCamera,
                    isPrimary: true,
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        Text('Tips for best results',
                            style: GoogleFonts.inter(
                                color: Colors.blueAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      for (final tip in [
                        'Include furniture name in the filename (e.g., "sofa_living.jpg")',
                        'Good lighting helps — use a well-lit photo',
                        'Select the correct category above for better matching',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 13)),
                                Expanded(
                                  child: Text(tip,
                                      style: GoogleFonts.inter(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          height: 1.4)),
                                ),
                              ]),
                        ),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: Processing ───────────────────────────────────────────────────

  Widget _buildProcessingStep() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          if (_pickedImage != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      blurRadius: 24),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(_pickedImage!, fit: BoxFit.cover),
              ),
            ),

          const SizedBox(height: 32),

          // Pulsing AR icon
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.accent.withValues(alpha: 0.3),
                  AppTheme.accentDark.withValues(alpha: 0.15),
                ]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.threed_rotation_rounded,
                  color: AppTheme.accent, size: 38),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            _processingLabels[_processingStep.clamp(
                0, _processingLabels.length - 1)],
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          Text(
            'Finding the perfect 3D model for you',
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 32),

          // Step dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children:
                List.generate(_processingLabels.length, (i) {
              final active = i <= _processingStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppTheme.accent : Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              minHeight: 3,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: AR View ──────────────────────────────────────────────────────

  Widget _buildArViewStep() {
    final match = _match!;

    return Stack(
      children: [
        // Screenshot wrapper around ModelViewer
        Screenshot(
          controller: _screenshotCtrl,
          child: Positioned.fill(
            child: ModelViewer(
              backgroundColor: const Color(0xFF080808),
              src: match.glbUrl,
              alt: match.label,
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: true,
              cameraControls: true,
              shadowIntensity: 1.2,
              exposure: 0.9,
              loading: Loading.auto,
              disableZoom: false,
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
                    bottom: 140px;
                    left: 50%;
                    transform: translateX(-50%);
                    box-shadow: 0 8px 32px rgba(201, 169, 110, 0.4);
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
        ),

        // Loading overlay
        if (_modelLoading)
          Container(
            color: const Color(0xFF080808),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.accent.withValues(alpha: 0.25),
                        AppTheme.accent.withValues(alpha: 0.08),
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.view_in_ar_rounded,
                        color: AppTheme.accent, size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Loading 3D Model…',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('${match.emoji} ${match.label}',
                    style: GoogleFonts.inter(
                        color: AppTheme.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
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
              ]),
            ),
          ),

        // Bottom info card
        if (!_modelLoading)
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
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.97),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Match badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(children: [
                    Text(match.emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(match.label,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text(
                                'Pinch to zoom • Drag to rotate • Tap AR to place',
                                style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ]),
                    ),
                    GestureDetector(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),

        // Screenshot FAB
        if (!_modelLoading)
          Positioned(
            right: 16,
            bottom: 110,
            child: GestureDetector(
              onTap: _savingScreenshot ? null : _takeScreenshot,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _savingScreenshot
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black),
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded,
                        color: Colors.black, size: 22),
              ),
            ),
          ),

        // Image thumbnail (top-right corner when in view step)
        if (!_modelLoading && _pickedImage != null)
          Positioned(
            right: 16,
            top: 0,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(_pickedImage!, fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int current; // 0, 1, or 2
  const _StepProgressBar({required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = ['Upload', 'Process', 'AR View'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final idx = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: idx < current ? AppTheme.accent : Colors.white12,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx < current;
        final active = idx == current;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? AppTheme.accent
                  : active
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(
                color: active || done ? AppTheme.accent : Colors.white12,
                width: 1.5,
              ),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.black, size: 14)
                  : Text('${idx + 1}',
                      style: TextStyle(
                          color: active ? AppTheme.accent : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 4),
          Text(steps[idx],
              style: TextStyle(
                  color: active || done
                      ? AppTheme.accent
                      : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400)),
        ]);
      }),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.white12,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Column(children: [
          Icon(icon,
              color: isPrimary ? Colors.black : AppTheme.accent, size: 30),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  color: isPrimary ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: isPrimary
                      ? Colors.black.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                  fontSize: 11)),
        ]),
      ),
    );
  }
}
