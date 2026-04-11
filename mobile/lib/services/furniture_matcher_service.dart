import 'dart:io';

/// A single entry in the local furniture 3D model catalogue.
class FurnitureMatch {
  final String category;
  final String label;
  final String glbUrl;
  final String emoji;

  const FurnitureMatch({
    required this.category,
    required this.label,
    required this.glbUrl,
    required this.emoji,
  });
}

/// Maps an uploaded image to the closest pre-stored 3D furniture model
/// by inspecting the filename for known furniture keywords.
///
/// GLB models are self-hosted on Render:
///   • chair.glb  — Accent chair (2.8 MB)
///   • sofa.glb   — 3-seater sofa (120 KB)
///   • table.glb  — Dining/coffee table (8.1 MB)
class FurnitureMatcher {
  FurnitureMatcher._();

  /// Base URL of the self-hosted GLB server on Render.
  static const String _base = 'https://visionfurnish-api.onrender.com/models';

  // ── GLB URLs ───────────────────────────────────────────────────────────────
  static const String _chairGlb    = '$_base/chair.glb';
  static const String _sofaGlb     = '$_base/sofa.glb';
  static const String _tableGlb    = '$_base/table.glb';
  static const String _lampGlb     = '$_base/lamp.glb';

  // ── Catalogue ──────────────────────────────────────────────────────────────
  // Each category maps to the most visually-appropriate available GLB model.
  static const List<FurnitureMatch> _catalogue = [
    // ── Chairs → chair.glb ─────────────────────────────────────────────────
    FurnitureMatch(
      category: 'chair',
      label:    'Office / Accent Chair',
      emoji:    '🪑',
      glbUrl:   _chairGlb,
    ),

    // ── Sofas → sofa.glb ───────────────────────────────────────────────────
    FurnitureMatch(
      category: 'sofa',
      label:    'Modern Sofa',
      emoji:    '🛋️',
      glbUrl:   _sofaGlb,
    ),

    // ── Tables → table.glb ─────────────────────────────────────────────────
    FurnitureMatch(
      category: 'table',
      label:    'Dining / Coffee Table',
      emoji:    '🪵',
      glbUrl:   _tableGlb,
    ),

    // ── Desks → table.glb (closest shape) ──────────────────────────────────
    FurnitureMatch(
      category: 'desk',
      label:    'Study / Standing Desk',
      emoji:    '🖥️',
      glbUrl:   _tableGlb,
    ),

    // ── Beds → chair.glb (placeholder until bed.glb is added) ──────────────
    FurnitureMatch(
      category: 'bed',
      label:    'King / Queen Bed',
      emoji:    '🛏️',
      glbUrl:   _chairGlb,
    ),

    // ── Wardrobes → sofa.glb (box-like shape, closest approximation) ───────
    FurnitureMatch(
      category: 'wardrobe',
      label:    'Wardrobe / Closet',
      emoji:    '🚪',
      glbUrl:   _sofaGlb,
    ),

    // ── Bookshelves → table.glb ────────────────────────────────────────────
    FurnitureMatch(
      category: 'shelf',
      label:    'Bookshelf',
      emoji:    '📚',
      glbUrl:   _tableGlb,
    ),

    // ── Lamps / Lighting → lamp.glb (real barn lamp) ────────────────────────
    FurnitureMatch(
      category: 'lamp',
      label:    'Barn Lamp',
      emoji:    '💡',
      glbUrl:   _lampGlb,
    ),

    // ── Outdoor → sofa.glb ─────────────────────────────────────────────────
    FurnitureMatch(
      category: 'outdoor',
      label:    'Garden / Patio Furniture',
      emoji:    '🌿',
      glbUrl:   _sofaGlb,
    ),

    // ── TV Units → table.glb ───────────────────────────────────────────────
    FurnitureMatch(
      category: 'tv',
      label:    'TV Unit / Console',
      emoji:    '📺',
      glbUrl:   _tableGlb,
    ),
  ];

  // ── Keyword map ───────────────────────────────────────────────────────────
  // Maps filename keywords → category strings above.
  static const Map<String, List<String>> _keywords = {
    'chair':    ['chair', 'seat', 'armchair', 'recliner', 'stool', 'rocker', 'throne', 'accent', 'ergonomic'],
    'sofa':     ['sofa', 'couch', 'settee', 'loveseat', 'sectional', 'divan', 'futon', 'chesterfield'],
    'table':    ['table', 'coffee', 'dining', 'counter', 'bench', 'ottoman', 'console', 'side', 'marble'],
    'desk':     ['desk', 'office', 'workstation', 'bureau', 'writing', 'study', 'standing'],
    'bed':      ['bed', 'mattress', 'cot', 'bunk', 'daybed', 'headboard', 'king', 'queen'],
    'wardrobe': ['wardrobe', 'closet', 'dresser', 'armoire', 'drawer', 'cupboard', 'almirah'],
    'shelf':    ['shelf', 'shelve', 'rack', 'bookcase', 'bookshelf', 'cabinet', 'book', 'storage', 'industrial'],
    'lamp':     ['lamp', 'light', 'bulb', 'chandelier', 'sconce', 'lantern', 'crystal', 'pendant'],
    'outdoor':  ['outdoor', 'garden', 'patio', 'balcony', 'rattan', 'bench', 'swing', 'lounger'],
    'tv':       ['tv', 'television', 'entertainment', 'media', 'console', 'stand'],
  };

  /// Match an image [File] to the best furniture category using filename analysis.
  /// Falls back to [fallback] category if no keyword match is found.
  static FurnitureMatch matchFromImage(File image, {String fallback = 'chair'}) {
    final name = image.path.toLowerCase();
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (name.contains(kw)) {
          return _getMatch(entry.key);
        }
      }
    }
    return _getMatch(fallback);
  }

  /// Match directly from a user-selected category label.
  static FurnitureMatch matchFromCategory(String category) {
    return _getMatch(category.toLowerCase());
  }

  static FurnitureMatch _getMatch(String category) {
    return _catalogue.firstWhere(
      (c) => c.category == category,
      orElse: () => _catalogue.first, // default: chair
    );
  }

  /// All available categories for UI display.
  static List<String> get categories => _catalogue.map((e) => e.category).toList();

  /// Full catalogue (for UI chips / grid).
  static List<FurnitureMatch> get catalogue => _catalogue;
}
