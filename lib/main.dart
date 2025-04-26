import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

const String entriesBoxName = 'financeEntries';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(entriesBoxName);
  runApp(const FinanceZeroApp());
}

class FinanceZeroApp extends StatelessWidget {
  const FinanceZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Zero',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
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
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  late Box<String> _entriesBox;
  List<String> _currentEntries = [];
  List<Map<String, dynamic>> _structuredEntries = [];
  bool _isAnalyzing = false;
  String? _analysisError;

  final String? _apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadEntries();
  }

  void _loadEntries() {
    _entriesBox = Hive.box<String>(entriesBoxName);
    _entriesBox.listenable().addListener(_updateEntriesFromBox);
    _updateEntriesFromBox();
  }

  void _updateEntriesFromBox() {
    setState(() {
      _currentEntries = _entriesBox.values.toList().reversed.toList();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _entriesBox.listenable().removeListener(_updateEntriesFromBox);
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (errorNotification) => print('Speech initialization error: $errorNotification'),
        onStatus: (status) => print('Speech status: $status'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing speech recognition: $e");
      _speechEnabled = false;
      if (mounted) setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechEnabled || _isListening) return;
    _lastWords = '';
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: "en_US",
        cancelOnError: true,
        partialResults: true,
      );
      if(mounted) setState(() => _isListening = true);
    } catch (e) {
      print("Error starting listening: $e");
      if(mounted) setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    if (!_isListening) return;
    try {
      await _speechToText.stop();
    } catch (e) {
      print("Error stopping listening: $e");
    } finally {
      if(mounted) setState(() => _isListening = false);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    if (result.finalResult && recognized.trim().isNotEmpty) {
      print("Final speech result: $recognized");
      _addEntry(recognized.trim());
      if (mounted) {
        setState(() {
          _lastWords = '';
          _isListening = false;
        });
      }
    } else if (!_isListening && recognized.trim().isNotEmpty) {
      print("Delayed final speech result: $recognized");
      _addEntry(recognized.trim());
      if (mounted) {
        setState(() {
          _lastWords = '';
          _isListening = false;
        });
      }
    } else {
      if(mounted) setState(() => _lastWords = recognized);
    }
  }

  Future<void> _addEntry(String entry) async {
    final String trimmedEntry = entry.trim();
    if (trimmedEntry.isNotEmpty) {
      try {
        await _entriesBox.add(trimmedEntry);
        if (_textController.text == entry) {
          _textController.clear();
        }
        FocusScope.of(context).unfocus();
      } catch (e) {
        print("Error adding entry to Hive: $e");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    }
  }

  Future<void> _analyzeEntriesWithGemini() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _analysisError = "API Key not configured. Use --dart-define=GEMINI_API_KEY=YOUR_KEY";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_analysisError!), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _structuredEntries = [];
    });

    final entriesToAnalyze = _entriesBox.values.toList();
    if (entriesToAnalyze.isEmpty) {
      setState(() {
        _analysisError = "No entries to analyze.";
        _isAnalyzing = false;
      });
      return;
    }

    final entriesString = entriesToAnalyze.map((e) => "- $e").join("\n");
    final prompt = """
Analyze the following list of personal finance entries. For each entry, determine if it's an 'income' or 'expense', assign a relevant category (e.g., 'Food', 'Salary', 'Transport', 'Shopping', 'Utilities', 'Entertainment', 'Rent', 'Other Income', 'Other Expense'), estimate the monetary amount (as a number without currency symbols), and extract a brief description.

If an entry is unclear or lacks detail for categorization or amount extraction, use 'Uncategorized' for category and null for amount.

Provide the output STRICTLY as a JSON list of objects. Each object must have these keys: 'original_entry' (string), 'type' (string: 'income', 'expense', or 'unclear'), 'category' (string), 'amount' (number or null), 'description' (string).

Entries:
$entriesString

JSON Output:
""";

    print("Sending prompt to Gemini:\n$prompt");

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey!);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      print("Gemini Raw Response: ${response.text}");

      if (response.text == null || response.text!.isEmpty) {
        throw Exception("Received empty response from Gemini.");
      }

      String cleanedJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final List<dynamic> decodedList = jsonDecode(cleanedJson);
        _structuredEntries = decodedList.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            throw const FormatException("Parsed item is not a Map<String, dynamic>");
          }
        }).toList();

      } on FormatException catch (e) {
        print("JSON Parsing Error: $e");
        print("Cleaned JSON String was: $cleanedJson");
        throw Exception("Failed to parse Gemini response as valid JSON list. Response was:\n${response.text}");
      }

    } catch (e) {
      print("Error analyzing with Gemini: $e");
      if (mounted) {
        setState(() {
          _analysisError = "Error during analysis: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Zero'),
        actions: [
          IconButton(
            icon: _isAnalyzing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.analytics_outlined),
            tooltip: 'Analyze Entries with AI',
            onPressed: _isAnalyzing ? null : _analyzeEntriesWithGemini,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildStructuredEntriesView(),
          const Divider(height: 1.0),
          _buildRawEntriesView(),
          const Divider(height: 1.0),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStructuredEntriesView() {
    if (_isAnalyzing) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Analyzing entries...")
          ],
        )),
      );
    }

    if (_analysisError != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Analysis Error: $_analysisError', style: const TextStyle(color: Colors.red))),
      );
    }

    if (_structuredEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Tap the analyze button (📈) to process entries.')),
      );
    }

    return Expanded(
      flex: 2,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _structuredEntries.length,
        itemBuilder: (context, index) {
          final item = _structuredEntries[index];
          final type = item['type']?.toString() ?? 'unclear';
          final category = item['category']?.toString() ?? 'N/A';
          final amount = item['amount']?.toString() ?? '-';
          final description = item['description']?.toString() ?? 'N/A';
          final original = item['original_entry']?.toString() ?? 'Original entry missing';

          Color typeColor = type == 'income' ? Colors.green : (type == 'expense' ? Colors.red : Colors.grey);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: Icon(
                type == 'income' ? Icons.arrow_downward : (type == 'expense' ? Icons.arrow_upward : Icons.help_outline),
                color: typeColor,
              ),
              title: Text("$category: $description"),
              subtitle: Text("Amount: $amount\nOriginal: $original"),
              isThreeLine: true,
              trailing: Text(type, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRawEntriesView() {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Raw Input History:", style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: _currentEntries.isEmpty
                ? const Center(child: Text('No raw entries yet.'))
                : ListView.builder(
              itemCount: _currentEntries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(_currentEntries[index]),
                  leading: const Icon(Icons.notes),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter details or tap mic...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              ),
              onSubmitted: _addEntry,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: _speechEnabled ? Theme.of(context).primaryColor : Colors.grey,
            ),
            tooltip: _isListening ? 'Stop listening' : (_speechEnabled ? 'Tap to speak' : 'Speech not available'),
            onPressed: !_speechEnabled ? null : (_isListening ? _stopListening : _startListening),
          ),
        ],
      ),
    );
  }
}