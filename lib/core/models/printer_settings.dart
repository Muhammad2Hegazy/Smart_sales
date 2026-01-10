class PrinterSettings {
  final String printerName;
  final String paperSize;
  final String paperSource;
  final bool isPortrait;
  final double width; // in mm
  final double height; // in mm (or infinity for continuous)

  const PrinterSettings({
    required this.printerName,
    required this.paperSize,
    required this.paperSource,
    required this.isPortrait,
    required this.width,
    required this.height,
  });

  // Default settings based on the user's printer
  factory PrinterSettings.defaultSettings() {
    return const PrinterSettings(
      printerName: 'XP-80C (copy 6)',
      paperSize: '82(80) x 3276 mm',
      paperSource: 'Automatically Select',
      isPortrait: true,
      width: 80.0, // 80mm width
      height: double.infinity, // Continuous paper
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'printerName': printerName,
      'paperSize': paperSize,
      'paperSource': paperSource,
      'isPortrait': isPortrait,
      'width': width,
      'height': height == double.infinity ? 'infinity' : height,
    };
  }

  // Create from JSON
  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      printerName: json['printerName'] as String? ?? 'XP-80C (copy 6)',
      paperSize: json['paperSize'] as String? ?? '82(80) x 3276 mm',
      paperSource: json['paperSource'] as String? ?? 'Automatically Select',
      isPortrait: json['isPortrait'] as bool? ?? true,
      width: (json['width'] as num?)?.toDouble() ?? 80.0,
      height: json['height'] == 'infinity' 
          ? double.infinity 
          : (json['height'] as num?)?.toDouble() ?? double.infinity,
    );
  }

  // Copy with method for updates
  PrinterSettings copyWith({
    String? printerName,
    String? paperSize,
    String? paperSource,
    bool? isPortrait,
    double? width,
    double? height,
  }) {
    return PrinterSettings(
      printerName: printerName ?? this.printerName,
      paperSize: paperSize ?? this.paperSize,
      paperSource: paperSource ?? this.paperSource,
      isPortrait: isPortrait ?? this.isPortrait,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

