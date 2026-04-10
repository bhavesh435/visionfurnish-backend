import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

/// Handles uploading .glb 3D model files to the backend,
/// and AI-powered 2D image → 3D model generation via Meshy.ai.
class UploadService {
  UploadService._();

  // ── Upload .glb file ─────────────────────────────────────────

  /// Uploads a [file] to `POST /api/upload/model`.
  /// Returns the public URL string on success, or throws on failure.
  static Future<String> uploadGlbModel(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final uri      = Uri.parse(ApiConfig.uploadModel);
    final filename = file.path.split('/').last.split('\\').last;

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'model',
        file.path,
        filename: filename,
      ));

    try {
      final streamedResponse = await request.send();
      final response         = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url  = data['url'] as String?;
        if (url == null || url.isEmpty) throw Exception('Server returned empty URL.');
        return url;
      } else {
        String msg = 'Upload failed (${response.statusCode})';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          msg = body['message'] as String? ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }
    } on SocketException {
      throw Exception('Network error — cannot reach the server.');
    }
  }

  // ── AI 2D → 3D Generation ────────────────────────────────────

  /// Starts a 3D model assignment for [productId].
  /// Returns the full response map including taskId and optional glbUrl
  /// (when the result is immediate, glbUrl will be set right away).
  static Future<Map<String, dynamic>> startGenerate3D(int productId, String token) async {
    final uri = Uri.parse(ApiConfig.generate3dStart(productId));
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && data['success'] == true) {
        return data; // includes taskId, status, glbUrl (if immediate)
      }
      throw Exception(data['message'] ?? 'Failed to start 3D generation');
    } on SocketException {
      throw Exception('Network error — cannot reach the server.');
    }
  }

  /// Polls Meshy.ai task status for [productId] / [taskId].
  ///
  /// Returns a map with:
  /// - `status`: "PENDING" | "IN_PROGRESS" | "SUCCEEDED" | "FAILED"
  /// - `progress`: int 0–100
  /// - `glbUrl`: String? (only set when SUCCEEDED)
  static Future<Map<String, dynamic>> pollGenerate3D(
    int productId,
    String taskId,
    String token,
  ) async {
    final uri = Uri.parse(ApiConfig.generate3dStatus(productId, taskId));
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return data;
      throw Exception(data['message'] ?? 'Polling failed (${response.statusCode})');
    } on SocketException {
      throw Exception('Network error — cannot reach the server.');
    }
  }
}
