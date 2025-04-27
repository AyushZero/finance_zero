import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/input_area.dart';
import '../widgets/transactions_view.dart';
import '../widgets/insights_view.dart';
import '../widgets/raw_entries_view.dart';
import '../models/transaction.dart';
import '../services/speech_service.dart';
import '../utils/analysis_service.dart';
import '../theme/theme_provider.dart';
import 'manual_entry_screen.dart';

class TrackerHomePage extends StatefulWidget {
  const TrackerHomePage({super.key});

  @override
  State<TrackerHomePage> createState() => _TrackerHomePageState();
}

class _TrackerHomePageState extends State<TrackerHomePage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  late Box<String> _entriesBox;
  late Box<String> _transactionsBox;
  List<String> _currentEntries = [];
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isAnalyzing = false;
  String? _analysisError;
  late TabController _tabController;

  // Filtering options
  String? _selectedTypeFilter;
  String? _selectedCategoryFilter;
  List<String> _availableCategories = [];

  // Charts view
  late TabController _insightsTabController;
  int _selectedChartTab = 0;

  final String? _apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadData();
    _tabController = TabController(length: 3, vsync: this);
    _insightsTabController = TabController(length: 2, vsync: this);
    _insightsTabController.addListener(() {
      setState(() {
        _selectedChartTab = _insightsTabController.index;
      });
    });
  }

  void _navigateToManualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
  }

  void _loadData() {
    _entriesBox = Hive.box<String>(entriesBoxName);
    _transactionsBox = Hive.box<String>(transactionsBoxName);

    _entriesBox.listenable().addListener(_updateEntriesFromBox);
    _transactionsBox.listenable().addListener(_updateTransactionsFromBox);

    _updateEntriesFromBox();
    _updateTransactionsFromBox();
  }

  void _updateEntriesFromBox() {
    setState(() {
      _currentEntries = _entriesBox.values.toList().reversed.toList();
    });
  }

  void _updateTransactionsFromBox() {
    setState(() {
      _transactions = _transactionsBox.values.map((jsonStr) {
        try {
          return Transaction.fromJson(jsonDecode(jsonStr));
        } catch (e) {
          print("Error decoding transaction: $e");
          return Transaction(
            type: 'unclear',
            category: 'Error',
            amount: null,
            description: 'Failed to load transaction',
            originalEntry: jsonStr,
          );
        }
      }).toList();

      // Extract all unique categories
      Set<String> categories = {};
      for (var transaction in _transactions) {
        if (transaction.category != null && transaction.category!.isNotEmpty) {
          categories.add(transaction.category!);
        }
      }
      _availableCategories = categories.toList()..sort();

      // Apply filters
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Apply type filter if selected
        if (_selectedTypeFilter != null && transaction.type != _selectedTypeFilter) {
          return false;
        }

        // Apply category filter if selected
        if (_selectedCategoryFilter != null && transaction.category != _selectedCategoryFilter) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedTypeFilter = null;
      _selectedCategoryFilter = null;
      _filteredTransactions = List.from(_transactions);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _entriesBox.listenable().removeListener(_updateEntriesFromBox);
    _transactionsBox.listenable().removeListener(_updateTransactionsFromBox);
    _tabController.dispose();
    _insightsTabController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechService.initialize();
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled || _isListening) return;
    _lastWords = '';

    setState(() => _isListening = true);
    _speechService.startListening(
      onResult: (result) => _onSpeechResult(result),
      onError: (error) {
        print("Speech recognition error: $error");
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopListening() async {
    if (!_isListening) return;
    await _speechService.stopListening();
    if (mounted) setState(() => _isListening = false);
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
      if (mounted) setState(() => _lastWords = recognized);
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving entry: $e')),
          );
        }
      }
    }
  }

  void _deleteRawEntry(int index) {
    final actualIndex = _entriesBox.length - 1 - index;
    try {
      _entriesBox.deleteAt(actualIndex);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
        );
      }
    } catch (e) {
      print("Error deleting entry: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }

  void _deleteTransaction(int index) {
    try {
      final transactionToDelete = _filteredTransactions[index];
      int actualIndex = -1;

      for (int i = 0; i < _transactionsBox.length; i++) {
        try {
          final storedTransaction = Transaction.fromJson(jsonDecode(_transactionsBox.getAt(i) as String));

          if (storedTransaction.originalEntry == transactionToDelete.originalEntry &&
              storedTransaction.amount == transactionToDelete.amount &&
              storedTransaction.description == transactionToDelete.description) {
            actualIndex = i;
            break;
          }
        } catch (e) {
          print("Error comparing transactions: $e");
        }
      }

      if (actualIndex >= 0) {
        _transactionsBox.deleteAt(actualIndex);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted')),
          );
        }
      } else {
        throw Exception("Transaction not found in storage");
      }
    } catch (e) {
      print("Error deleting transaction: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Zero'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          if (_currentEntries.isNotEmpty)
            IconButton(
              icon: _isAnalyzing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.analytics_outlined),
              tooltip: 'Analyze Entries with AI',
              onPressed: _isAnalyzing ? null : _analyzeEntriesWithGemini,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Insights', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Raw Entries', icon: Icon(Icons.note_alt)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TransactionsView(
                  transactions: _transactions,
                  filteredTransactions: _filteredTransactions,
                  availableCategories: _availableCategories,
                  selectedTypeFilter: _selectedTypeFilter,
                  selectedCategoryFilter: _selectedCategoryFilter,
                  isAnalyzing: _isAnalyzing,
                  analysisError: _analysisError,
                  onDeleteTransaction: _deleteTransaction,
                  onResetFilters: _resetFilters,
                  onTypeFilterSelected: (type) {
                    setState(() {
                      _selectedTypeFilter = type;
                      _applyFilters();
                    });
                  },
                  onCategoryFilterSelected: (category) {
                    setState(() {
                      _selectedCategoryFilter = category;
                      _applyFilters();
                    });
                  },
                  onAddManualTransaction: _navigateToManualEntry,
                ),
                InsightsView(
                  transactions: _transactions,
                  selectedChartTab: _selectedChartTab,
                  insightsTabController: _insightsTabController,
                ),
                RawEntriesView(
                  entries: _currentEntries,
                  onDeleteEntry: _deleteRawEntry,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: InputArea(
        controller: _textController,
        isListening: _isListening,
        speechEnabled: _speechEnabled,
        lastWords: _lastWords,
        onSubmitted: _addEntry,
        onStartListening: _startListening,
        onStopListening: _stopListening,
      ),
      floatingActionButton: _isListening
          ? FloatingActionButton(
        onPressed: _stopListening,
        tooltip: 'Stop listening',
        backgroundColor: Colors.red,
        child: const Icon(Icons.mic_off),
      )
          : null,
    );
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

    final entriesToAnalyze = _entriesBox.values.toList();
    if (entriesToAnalyze.isEmpty) {
      setState(() {
        _analysisError = "No entries to analyze.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries to analyze'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final analysisService = AnalysisService(apiKey: _apiKey!);
      final transactions = await analysisService.analyzeEntries(entriesToAnalyze);

      // Store the structured entries
      for (var transaction in transactions) {
        await _transactionsBox.add(jsonEncode(transaction.toJson()));
      }

      // Clear the raw entries since they've been processed
      await _entriesBox.clear();

      // Switch to the transactions tab to show results
      _tabController.animateTo(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entries processed and stored as transactions!'),
            backgroundColor: Colors.green,
          ),
        );
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
}