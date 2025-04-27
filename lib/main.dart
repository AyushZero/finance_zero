import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

const String entriesBoxName = 'financeEntries';
const String transactionsBoxName = 'transactions';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(entriesBoxName);
  await Hive.openBox<String>(transactionsBoxName);
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

class _TrackerHomePageState extends State<TrackerHomePage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  late Box<String> _entriesBox;
  late Box<String> _transactionsBox;
  List<String> _currentEntries = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
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
          return Map<String, dynamic>.from(jsonDecode(jsonStr));
        } catch (e) {
          print("Error decoding transaction: $e");
          return <String, dynamic>{
            'type': 'unclear',
            'category': 'Error',
            'amount': null,
            'description': 'Failed to load transaction',
            'original_entry': jsonStr,
          };
        }
      }).toList();

      // Extract all unique categories
      Set<String> categories = {};
      for (var transaction in _transactions) {
        if (transaction['category'] != null && transaction['category'].toString().isNotEmpty) {
          categories.add(transaction['category'].toString());
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
        if (_selectedTypeFilter != null &&
            transaction['type'] != _selectedTypeFilter) {
          return false;
        }

        // Apply category filter if selected
        if (_selectedCategoryFilter != null &&
            transaction['category'] != _selectedCategoryFilter) {
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

  void _deleteRawEntry(int index) {
    // The entries are displayed in reverse order, so we need to adjust the index
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
      // Find the actual index in the _transactionsBox based on the filtered index
      Map<String, dynamic> transactionToDelete = _filteredTransactions[index];
      int actualIndex = -1;

      for (int i = 0; i < _transactionsBox.length; i++) {
        try {
          Map<String, dynamic> storedTransaction =
          jsonDecode(_transactionsBox.getAt(i) as String);

          // Compare transactions (this is simplified, might need more robust comparison)
          if (storedTransaction['original_entry'] == transactionToDelete['original_entry'] &&
              storedTransaction['amount'] == transactionToDelete['amount'] &&
              storedTransaction['description'] == transactionToDelete['description']) {
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
        List<Map<String, dynamic>> structuredEntries = decodedList.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            throw const FormatException("Parsed item is not a Map<String, dynamic>");
          }
        }).toList();

        // Store the structured entries
        for (var entry in structuredEntries) {
          final jsonEntry = jsonEncode(entry);
          await _transactionsBox.add(jsonEntry);
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
                _buildTransactionsView(),
                _buildInsightsView(),
                _buildRawEntriesView(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildInputArea(),
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

  Widget _buildInsightsView() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transaction data yet.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Add entries and analyze them to see insights here.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _insightsTabController,
          tabs: const [
            Tab(text: 'Expense Categories'),
            Tab(text: 'Income vs Expense'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _insightsTabController,
            children: [
              _buildCategoryPieChart(),
              _buildIncomeExpenseChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart() {
    // Prepare data for expenses pie chart
    Map<String, double> categoryTotals = {};

    for (var transaction in _transactions) {
      // Only include expenses
      if (transaction['type'] == 'expense' && transaction['amount'] != null) {
        String category = transaction['category'] ?? 'Uncategorized';
        double amount = (transaction['amount'] as num).toDouble();

        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    // Sort by amount (descending)
    List<MapEntry<String, double>> sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Generate sections
    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.lightBlue,
      Colors.lime,
      Colors.brown,
    ];

    double totalSpent = categoryTotals.values.fold(0, (prev, amount) => prev + amount);

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = colors[i % colors.length];
      final percentage = (entry.value / totalSpent) * 100;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // If no expenses
    if (sections.isEmpty) {
      return const Center(
        child: Text('No expense data to display'),
      );
    }

    // Create the legend entries
    List<Widget> legendItems = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = colors[i % colors.length];

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.key, overflow: TextOverflow.ellipsis),
              ),
              Text('\$${entry.value.toStringAsFixed(2)}')
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Expense Breakdown by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Spent: \$${totalSpent.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16),
          ),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legendItems,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    // Prepare data for bar chart
    Map<String, Map<String, double>> monthlyData = {};

    // Define format for getting month from date
    final DateFormat monthFormat = DateFormat('MMM');
    final now = DateTime.now();

    // Initialize the last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthName = monthFormat.format(month);
      monthlyData[monthName] = {'income': 0, 'expense': 0};
    }

    // Assuming all transactions are from current month for simplicity
    // In a real app, you would use date information from transactions
    final currentMonth = monthFormat.format(now);

    for (var transaction in _transactions) {
      if (transaction['amount'] == null) continue;

      double amount = (transaction['amount'] as num).toDouble();
      String type = transaction['type'] ?? 'unclear';

      if (type == 'income') {
        monthlyData[currentMonth]?['income'] =
            (monthlyData[currentMonth]?['income'] ?? 0) + amount;
      } else if (type == 'expense') {
        monthlyData[currentMonth]?['expense'] =
            (monthlyData[currentMonth]?['expense'] ?? 0) + amount;
      }
    }

    // Convert to list for chart
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    monthlyData.forEach((month, data) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data['income'] ?? 0,
              color: Colors.green,
              borderRadius: BorderRadius.zero,
              width: 12,
            ),
            BarChartRodData(
              toY: data['expense'] ?? 0,
              color: Colors.red,
              borderRadius: BorderRadius.zero,
              width: 12,
            ),
          ],
        ),
      );
      index++;
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Income vs Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue(monthlyData) * 1.2,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        List<String> months = monthlyData.keys.toList();
                        return idx >= 0 && idx < months.length
                            ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(months[idx],
                              style: const TextStyle(fontSize: 12)),
                        )
                            : const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text('\$${value.toInt()}',
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  const Text('Income'),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  const Text('Expenses'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxValue(Map<String, Map<String, double>> data) {
    double maxValue = 0;
    data.forEach((_, values) {
      if ((values['income'] ?? 0) > maxValue) maxValue = values['income']!;
      if ((values['expense'] ?? 0) > maxValue) maxValue = values['expense']!;
    });
    return maxValue > 0 ? maxValue : 100;
  }

  Widget _buildTransactionsView() {
    if (_isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Analyzing entries...")
          ],
        ),
      );
    }

    if (_analysisError != null) {
      return Center(
        child: Text('Analysis Error: $_analysisError', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions yet.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Add entries and analyze them to see transactions here.'),
          ],
        ),
      );
    }

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in _transactions) {
      if (transaction['type'] == 'income' && transaction['amount'] != null) {
        totalIncome += (transaction['amount'] as num).toDouble();
      } else if (transaction['type'] == 'expense' && transaction['amount'] != null) {
        totalExpense += (transaction['amount'] as num).toDouble();
      }
    }

    double balance = totalIncome - totalExpense;

    return Column(
      children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Income', style: TextStyle(color: Colors.green)),
                          Text('\$${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Expenses', style: TextStyle(color: Colors.red)),
                          Text('\$${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Balance'),
                          Text('\$${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: balance >= 0 ? Colors.green : Colors.red
                              )),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedTypeFilter == null && _selectedCategoryFilter == null,
                    onSelected: (selected) {
                      if (selected) {
                        _resetFilters();
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('Income'),
                    selected: _selectedTypeFilter == 'income',
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypeFilter = 'income';
                        } else if (_selectedTypeFilter == 'income') {
                          _selectedTypeFilter = null;
                        }
                        _applyFilters();
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Expenses'),
                    selected: _selectedTypeFilter == 'expense',
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypeFilter = 'expense';
                        } else if (_selectedTypeFilter == 'expense') {
                          _selectedTypeFilter = null;
                        }
                        _applyFilters();
                      });
                    },
                  ),
                  if (_availableCategories.isNotEmpty)
                    PopupMenuButton<String>(
                      child: Chip(
                        label: Text(_selectedCategoryFilter ?? 'Categories'),
                        deleteIcon: _selectedCategoryFilter != null ? const Icon(Icons.close, size: 18) : null,
                        onDeleted: _selectedCategoryFilter != null ? () {
                          setState(() {
                            _selectedCategoryFilter = null;
                            _applyFilters();
                          });
                        } : null,
                      ),
                      onSelected: (String category) {
                        setState(() {
                          _selectedCategoryFilter = category;
                          _applyFilters();
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return _availableCategories.map((String category) {
                          return PopupMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),

        // Show filtered count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_filteredTransactions.length} of ${_transactions.length} transactions',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_selectedTypeFilter != null || _selectedCategoryFilter != null)
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _filteredTransactions.length,
            itemBuilder: (context, index) {
              final item = _filteredTransactions[index];
              final type = item['type']?.toString() ?? 'unclear';
              final category = item['category']?.toString() ?? 'N/A';
              final amount = item['amount'] != null ? (item['amount'] as num).toDouble() : null;
              final description = item['description']?.toString() ?? 'N/A';

              Color typeColor = type == 'income' ? Colors.green : (type == 'expense' ? Colors.red : Colors.grey);
              IconData typeIcon = type == 'income' ? Icons.arrow_downward : (type == 'expense' ? Icons.arrow_upward : Icons.help_outline);

              // Category icon mapping
              IconData categoryIcon = _getCategoryIcon(category);

              return Dismissible(
                key: Key('transaction_$index'),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteTransaction(index),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor.withOpacity(0.2),
                      child: Icon(categoryIcon, color: typeColor),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(description, style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (amount != null)
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('$category • ${_formatDate(DateTime.now())}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTransaction(index),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('food') || lowerCategory.contains('grocery') || lowerCategory.contains('restaurant')) {
      return Icons.restaurant;
    } else if (lowerCategory.contains('transport') || lowerCategory.contains('travel')) {
      return Icons.directions_car;
    } else if (lowerCategory.contains('shopping')) {
      return Icons.shopping_bag;
    } else if (lowerCategory.contains('utilities') || lowerCategory.contains('bill')) {
      return Icons.receipt_long;
    } else if (lowerCategory.contains('entertainment')) {
      return Icons.movie;
    } else if (lowerCategory.contains('rent') || lowerCategory.contains('housing')) {
      return Icons.home;
    } else if (lowerCategory.contains('salary') || lowerCategory.contains('income')) {
      return Icons.payments;
    } else if (lowerCategory.contains('health') || lowerCategory.contains('medical')) {
      return Icons.medical_services;
    } else if (lowerCategory.contains('education')) {
      return Icons.school;
    } else {
      return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRawEntriesView() {
    if (_currentEntries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No raw entries yet.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Add entries by typing or speaking below.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _currentEntries.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key('entry_$index'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteRawEntry(index),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ListTile(
              title: Text(_currentEntries[index]),
              leading: const Icon(Icons.note_alt),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteRawEntry(index),
              ),
            ),
          ),
        );
      },
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
                hintText: _isListening
                    ? 'Listening: $_lastWords'
                    : 'Enter details or tap mic...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _addEntry(_textController.text);
                    _textController.clear();
                  },
                )
                    : null,
              ),
              onSubmitted: (text) {
                _addEntry(text);
                _textController.clear();
              },
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _speechEnabled
                  ? (_isListening ? Colors.red : Theme.of(context).primaryColor)
                  : Colors.grey,
              size: 28,
            ),
            tooltip: _isListening ? 'Stop listening' : (_speechEnabled ? 'Tap to speak' : 'Speech not available'),
            onPressed: !_speechEnabled ? null : (_isListening ? _stopListening : _startListening),
          ),
        ],
      ),
    );
  }
}