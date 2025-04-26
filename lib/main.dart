import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance Zero',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TrackerHomePage(),
    );
  }
}

class TrackerHomePage extends StatefulWidget {
  const TrackerHomePage({super.key});

  @override
  State<TrackerHomePage> createState() => _TrackerHomePageState();
}

class _TrackerHomePageState extends State<TrackerHomePage> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _entries = []; // List to hold text and voice entries
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = ''; // To hold words recognized during listening

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _textController.dispose(); // Dispose the controller when widget is removed
    super.dispose();
  }

  /// Initialize speech recognition
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (errorNotification) => print('Speech initialization error: $errorNotification'),
        onStatus: (status) => print('Speech status: $status'),
      );
      if (!_speechEnabled) {
        print("The user has denied the use of speech recognition.");
        // Optionally show a dialog or message to the user
      }
      setState(() {}); // Update UI based on speech availability
    } catch (e) {
      print("Error initializing speech recognition: $e");
      _speechEnabled = false; // Ensure it's false on error
      setState(() {});
    }
  }

  /// Start listening for speech
  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available or permission denied.')),
      );
      return;
    }
    if (_isListening) return; // Already listening

    // Reset last words before starting a new session
    _lastWords = '';

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30), // Max duration to listen
      pauseFor: const Duration(seconds: 3),   // Time after speech stops before ending
      localeId: "en_US", // Example locale, adjust as needed
      cancelOnError: true,
      partialResults: true, // Get intermediate results
    );
    setState(() {
      _isListening = true;
    });
  }

  /// Stop listening for speech
  void _stopListening() async {
    if (!_isListening) return; // Not listening

    await _speechToText.stop();
    setState(() {
      _isListening = false;
      // Note: The final result might arrive slightly after stop is called,
      // handled by onResult checking speechToText.isNotListening
    });
  }

  /// Callback for speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords; // Update with the latest recognized words
    });

    // Check if recognition is final (listening has stopped)
    if (result.finalResult) {
      print("Final result: $_lastWords");
      if (_lastWords.isNotEmpty) {
        _addEntry(_lastWords); // Add the final recognized text
      }
      setState(() {
        _isListening = false; // Ensure listening state is updated
        _lastWords = ''; // Clear last words after adding
      });
    }
  }

  /// Add an entry (from text or voice) to the list and update UI
  void _addEntry(String entry) {
    final String trimmedEntry = entry.trim();
    if (trimmedEntry.isNotEmpty) {
      setState(() {
        _entries.insert(0, trimmedEntry); // Add to the beginning of the list
      });
      // Clear the text field only if the entry came from it
      if (_textController.text == entry) {
        _textController.clear();
      }
      // Hide keyboard if it's open
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Zero'),
      ),
      body: Column(
        children: <Widget>[
          // Area to display the entries
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No entries yet.'))
                : ListView.builder(
              reverse: false, // Show newest entries at the top if inserted at 0
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_entries[index]),
                  leading: const Icon(Icons.receipt_long), // Example icon
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          // Input area at the bottom
          _buildInputArea(),
        ],
      ),
    );
  }

  // Builds the input row with text field and buttons
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor, // Use card color for background
      child: Row(
        children: <Widget>[
          // Text input field
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter expense/income details...',
                filled: true, // Add a background fill
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none, // No border line
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              ),
              onSubmitted: _addEntry, // Add entry when keyboard submit is pressed
              textInputAction: TextInputAction.send, // Show send button on keyboard
            ),
          ),
          const SizedBox(width: 8.0), // Spacing
          // Voice input button
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: _speechEnabled ? Theme.of(context).primaryColor : Colors.grey,
            ),
            tooltip: _isListening ? 'Stop listening' : (_speechEnabled ? 'Tap to speak' : 'Speech not available'),
            onPressed: !_speechEnabled ? null : (_isListening ? _stopListening : _startListening),
          ),
          // Optional: Send button for text field if you prefer explicit send
          // IconButton(
          //   icon: const Icon(Icons.send),
          //   onPressed: () => _addEntry(_textController.text),
          // ),
        ],
      ),
    );
  }
}