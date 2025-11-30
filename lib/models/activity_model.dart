import 'dart:convert';
import 'dart:typed_data';

class Activity {
  final String id;
  final double latitude;
  final double longitude;
  final String imagePath;       // file path (optional)
  final Uint8List? imageBytes;  // image in memory
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    this.imageBytes,
    required this.timestamp,
  });

  /// Convert Activity to JSON (for offline storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create Activity from JSON (for offline storage)
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imagePath: json['imagePath'] ?? '',
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
