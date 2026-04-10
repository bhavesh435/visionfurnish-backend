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
/// All GLB models are from KhronosGroup/glTF-Sample-Models and
/// Google model-viewer shared assets — MIT / Apache 2.0 licensed.
/// Delivered via jsDelivr CDN for reliability worldwide.
class FurnitureMatcher {
  FurnitureMatcher._();

  // ── Self-hosted on Render — works with Android Scene Viewer ────────────────
  static const String _base = 'https://visionfurnish-api.onrender.com/models';

  static const List<FurnitureMatch> _catalogue = [
    FurnitureMatch(
      category: 'chair',
      label: 'Accent Chair',
      emoji: '🪑',
      glbUrl: '$_base/chair.glb',
    ),
    FurnitureMatch(
      category: 'sofa',
      label: 'Modern Sofa',
      emoji: '🛋️',
      glbUrl: '$_base/chair.glb',
    ),
    FurnitureMatch(
      category: 'table',
      label: 'Coffee Table',
      emoji: '🪵',
      glbUrl: '$_base/sofa.glb',
    ),
    FurnitureMatch(
      category: 'bed',
      label: 'King Bed',
      emoji: '🛏️',
      glbUrl: '$_base/chair.glb',
    ),
    FurnitureMatch(
      category: 'lamp',
      label: 'Floor Lamp',
      emoji: '💡',
      glbUrl: '$_base/sofa.glb',
    ),
    FurnitureMatch(
      category: 'shelf',
      label: 'Bookshelf',
      emoji: '📚',
      glbUrl: '$_base/sofa.glb',
    ),
    FurnitureMatch(
      category: 'wardrobe',
      label: 'Wardrobe / Dresser',
      emoji: '🚪',
      glbUrl: '$_base/sofa.glb',
    ),
    FurnitureMatch(
      category: 'desk',
      label: 'Study Desk',
      emoji: '🖥️',
      glbUrl: '$_base/sofa.glb',
    ),
  ];


  // ── Keyword map ────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _keywords = {
    'chair':    ['chair', 'seat', 'armchair', 'recliner', 'stool', 'rocker', 'throne', 'accent'],
    'sofa':     ['sofa', 'couch', 'settee', 'loveseat', 'sectional', 'divan', 'futon'],
    'table':    ['table', 'coffee', 'dining', 'counter', 'bench', 'ottoman', 'console', 'side'],
    'bed':      ['bed', 'mattress', 'cot', 'bunk', 'daybed', 'headboard'],
    'lamp':     ['lamp', 'light', 'bulb', 'chandelier', 'sconce', 'lantern', 'floor lamp'],
    'shelf':    ['shelf', 'shelve', 'rack', 'bookcase', 'bookshelf', 'cabinet', 'book', 'storage'],
    'wardrobe': ['wardrobe', 'closet', 'dresser', 'armoire', 'drawer', 'cupboard'],
    'desk':     ['desk', 'office', 'workstation', 'bureau', 'writing', 'study'],
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

  /// Match from a user-selected category label.
  static FurnitureMatch matchFromCategory(String category) {
    return _getMatch(category.toLowerCase());
  }

  static FurnitureMatch _getMatch(String category) {
    return _catalogue.firstWhere(
      (c) => c.category == category,
      orElse: () => _catalogue.first,
    );
  }

  /// All available categories (for manual selection UI).
  static List<String> get categories => _catalogue.map((e) => e.category).toList();

  static List<FurnitureMatch> get catalogue => _catalogue;
}
