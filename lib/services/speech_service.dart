import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  Future<bool> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (errorNotification) => print('Speech initialization error: $errorNotification'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _speechEnabled;
    } catch (e) {
      print("Error initializing speech recognition: $e");
      return false;
    }
  }

  void startListening({
    required Function(SpeechRecognitionResult) onResult,
    required Function(String) onError,
  }) async {
    if (!_speechEnabled) return;
    try {
      await _speechToText.listen(
        onResult: onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: "en_US",
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      onError("Error starting listening: $e");
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      print("Error stopping listening: $e");
    }
  }
}