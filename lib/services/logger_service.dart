import 'dart:io';

class LoggerService {
  // Saving explicitly to your Documents folder to avoid Flutter dev permission errors
  static String logFilePath = r'C:\Users\KAAN\Documents\iot_signals.txt';

  static Future<void> init() async {
    // No-op for compatibility
  }

  static Future<void> log(String message) async {
    // 1. Print to console EVERY time
    print(message);

    // 2. Write to the text file asynchronously
    try {
      final file = File(logFilePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsString('$message\n', mode: FileMode.append, flush: true);
    } catch (e) {
      print('Failed to save to $logFilePath: $e');
    }
  }
}
