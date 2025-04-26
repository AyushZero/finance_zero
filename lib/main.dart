import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

void main() {
  runApp(const FinanceZeroApp());
}

class FinanceZeroApp extends StatelessWidget {
  const FinanceZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceZero',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading for 2 seconds and then go to Dashboard
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue, // You can change the color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your app's logo
            Text(
              'FinanceZero',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Your Personal Finance Tracker',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Sample data for demonstration
  double _totalIncome = 50000.0;
  double _totalExpenses = 30000.0;
  final List<Transaction> _transactions = [
    Transaction(
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: 'Food',
        amount: 500.0,
        description: 'Groceries'),
    Transaction(
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.income,
        category: 'Salary',
        amount: 20000.0,
        description: 'Monthly Salary'),
    Transaction(
        date: DateTime.now().subtract(const Duration(days: 7)),
        type: TransactionType.expense,
        category: 'Transport',
        amount: 1000.0,
        description: 'Fuel'),
    Transaction(
        date: DateTime.now(),
        type: TransactionType.expense,
        category: 'Food',
        amount: 100,
        description: "Lunch"),
  ];

  double get _netBalance => _totalIncome - _totalExpenses;

  // Date range selection
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Function to show date range picker
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        // Update data based on selected range
        _updateDashboardData();
      });
    }
  }

  //function to update dashboard
  void _updateDashboardData() {
    //in a real app, you would filter your transactions based on _selectedDateRange
    _totalIncome = _transactions
        .where((element) =>
    element.type == TransactionType.income &&
        element.date.isAfter(_selectedDateRange.start) &&
        element.date.isBefore(_selectedDateRange.end))
        .fold(0, (sum, item) => sum + item.amount);
    _totalExpenses = _transactions
        .where((element) =>
    element.type == TransactionType.expense &&
        element.date.isAfter(_selectedDateRange.start) &&
        element.date.isBefore(_selectedDateRange.end))
        .fold(0, (sum, item) => sum + item.amount);
  }

  // Get expense categories and amounts for the chart
  Map<String, double> get _expenseDataForChart {
    Map<String, double> data = {};
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        if (data.containsKey(transaction.category)) {
          data[transaction.category] =
              data[transaction.category]! + transaction.amount;
        } else {
          data[transaction.category] = transaction.amount;
        }
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Range Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date Range: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange.end)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Balance Summary
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_netBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Income',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${_totalIncome.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Expenses',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${_totalExpenses.toStringAsFixed(2)}',
                              style:
                              const TextStyle(fontSize: 20, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Spending Chart
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expense Distribution',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200, // Adjust as needed
                        child: PieChart(
                          PieChartData(
                            sections: _generatePieChartSections(_expenseDataForChart),
                            //  borderData: FlBorderData(show: false),
                            centerSpaceRadius: 40,
                            sectionsSpace: 0,
                          ),
                        ),
                      ),
                      //legend
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        children: _expenseDataForChart.keys
                            .map((e) => _buildLegendItem(
                            e,
                            _getCategoryColor(
                                _expenseDataForChart.keys.toList().indexOf(e))))
                            .toList(),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Trend Chart
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income and Expense Trend',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Placeholder for the line chart
                      SizedBox(
                        height: 200, // Adjust as needed
                        child: Center(
                          child: Text("Line Chart Placeholder"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const FinanceZeroBottomNavigationBar(
        currentIndex: 0,
      ),
    );
  }

  //pie chart section generator
  List<PieChartSectionData> _generatePieChartSections(
      Map<String, double> dataMap) {
    List<PieChartSectionData> sections = [];
    final List<String> keys = dataMap.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final String category = keys[i];
      final double value = dataMap[category] ?? 0;
      const double radius = 50;
      sections.add(PieChartSectionData(
        color: _getCategoryColor(i),
        value: value,
        title: '${value.toStringAsFixed(1)}',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    return sections;
  }

  //get category color
  Color _getCategoryColor(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  //build legend item
  Widget _buildLegendItem(String category, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(category),
      ],
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType _transactionType = TransactionType.expense;
  InputMethod _inputMethod = InputMethod.text;
  final TextEditingController _textInputController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<String> _people = []; // For split payments
  final List<double> _shares =
  []; //for split payments, should be the same length as _people

  //function to add new person in split payment
  void _addPerson() {
    setState(() {
      _people.add(''); // Add an empty string, to be filled later
      _shares.add(0.0);
    });
  }

  //function to remove person from split payment
  void _removePerson(int index) {
    setState(() {
      _people.removeAt(index);
      _shares.removeAt(index);
    });
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // This function will simulate sending data to a GPT model.
  // In a real application, you would use an API call.
  Future<Transaction?> _processTransaction(String input) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Here, you would replace this with your actual GPT API call.
    // The GPT model should return structured data (e.g., JSON).
    // For this example, we'll just parse the input string.
    // Example input: "Expense: Lunch at restaurant, 100 rupees, date 2024-07-24"

    //basic error handling
    if (input.isEmpty) {
      return null;
    }

    try {
      //very basic parsing, improve this
      String typeString = input.split(":")[0];
      String? category;
      String? description;
      double? amount;

      if (typeString.toLowerCase().contains("expense")) {
        final List<String> parts = input.split(",");
        if (parts.length > 1) {
          description = parts[0].split(":")[1].trim();
        }
        if (parts.length > 2) {
          amount = double.tryParse(parts[1].split(" ")[1].trim()) ?? 0;
        }
        if (parts.length > 3) {
          category = parts[2].trim();
        }

        return Transaction(
            date: _selectedDate, // Use the selected date
            type: TransactionType.expense,
            category: category ?? "Other",
            amount: amount ?? 0.0,
            description: description ?? "Expense");
      } else if (typeString.toLowerCase().contains("income")) {
        final List<String> parts = input.split(",");
        if (parts.length > 1) {
          description = parts[0].split(":")[1].trim();
        }
        if (parts.length > 2) {
          amount = double.tryParse(parts[1].split(" ")[1].trim()) ?? 0;
        }
        if (parts.length > 3) {
          category = parts[2].trim();
        }
        return Transaction(
            date: _selectedDate, // Use the selected date.
            type: TransactionType.income,
            category: category ?? "Other",
            amount: amount ?? 0.0,
            description: description ?? "Income");
      } else {
        return null; //error
      }
    } catch (e) {
      // Handle parsing errors
      print("Error parsing transaction input: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _textInputController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type
              const Text(
                'Transaction Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Radio<TransactionType>(
                    value: TransactionType.expense,
                    groupValue: _transactionType,
                    onChanged: (value) {
                      setState(() {
                        _transactionType = value!;
                      });
                    },
                  ),
                  const Text('Expense'),
                  Radio<TransactionType>(
                    value: TransactionType.income,
                    groupValue: _transactionType,
                    onChanged: (value) {
                      setState(() {
                        _transactionType = value!;
                      });
                    },
                  ),
                  const Text('Income'),
                ],
              ),
              const SizedBox(height: 16),
              // Input Method
              const Text(
                'Input Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Radio<InputMethod>(
                    value: InputMethod.text,
                    groupValue: _inputMethod,
                    onChanged: (value) {
                      setState(() {
                        _inputMethod = value!;
                      });
                    },
                  ),
                  const Text('Text'),
                  Radio<InputMethod>(
                    value: InputMethod.voice,
                    groupValue: _inputMethod,
                    onChanged: (value) {
                      setState(() {
                        _inputMethod = value!;
                      });
                    },
                  ),
                  const Text('Voice'),
                ],
              ),
              const SizedBox(height: 16),
              // Voice Input Mode
              if (_inputMethod == InputMethod.voice) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to speak your transaction details...',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Implement voice input logic here
                            // Use a speech-to-text package (e.g., speech_to_text)
                            // to convert speech to text and update the _textInputController.
                            // For this example, we'll just print a message.
                            print('Start recording voice input');
                            //show dialog
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Voice Input"),
                                    content: const Text(
                                        "Simulating voice input, please speak your transaction"),
                                    actions: [
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _textInputController.text =
                                            "Expense: Lunch at restaurant, 100 rupees, date ${_selectedDate.toIso8601String()}"; //simulated
                                            setState(() {});
                                          },
                                          child: const Text("OK"))
                                    ],
                                  );
                                });
                          },
                          child: const Text('Start Recording'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Text Input Mode
              if (_inputMethod == InputMethod.text) ...[
                TextField(
                  controller: _textInputController,
                  decoration: const InputDecoration(
                    labelText: 'Enter transaction details (e.g., Lunch at restaurant, 100 rupees)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Date:  ',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Split Payment
                const Text(
                  'Split Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Split this transaction?'),
                  value: _people.isNotEmpty, //active if there are people
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        _addPerson(); // Add the first person
                      } else {
                        _people.clear(); // Clear the list
                        _shares.clear();
                      }
                    });
                  },
                ),
                if (_people.isNotEmpty) ...[
                  Column(
                    children: [
                      for (var i = 0; i < _people.length; i++)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Person ${i + 1} Name',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _people[i] = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Share ${i + 1} (₹)',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _shares[i] =
                                        double.tryParse(value) ?? 0.0; //parse
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () => _removePerson(i),
                            ),
                          ],
                        ),
                      ElevatedButton(
                        onPressed: _addPerson,
                        child: const Text('Add Person'),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 32),
              // Save and Cancel Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Validate input
                      if (_inputMethod == InputMethod.text &&
                          _textInputController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter transaction details.'),
                          ),
                        );
                        return;
                      }
                      if (_amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter amount.'),
                          ),
                        );
                        return;
                      }
                      //split payment check
                      if (_people.isNotEmpty &&
                          _people.length != _shares.length) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please enter share for each person in split payment.'),
                          ),
                        );
                        return;
                      }
                      //save data
                      Transaction? newTransaction;
                      if (_inputMethod == InputMethod.text) {
                        newTransaction = await _processTransaction(
                            _textInputController.text);
                      } else {
                        newTransaction = await _processTransaction(
                            _textInputController.text); //simulated voice input
                      }

                      if (newTransaction != null) {
                        //add transaction
                        Navigator.pop(context, newTransaction); // Return the new transaction
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Failed to process transaction. Please check your input.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinanceZeroBottomNavigationBar extends StatefulWidget {
  const FinanceZeroBottomNavigationBar({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  _FinanceZeroBottomNavigationBarState createState() =>
      _FinanceZeroBottomNavigationBarState();
}

class _FinanceZeroBottomNavigationBarState
    extends State<FinanceZeroBottomNavigationBar> {
  int _currentIndex = 0; // Initialize with 0

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        // Handle navigation here
        if (index == 0) {
          // Already on dashboard
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Transactions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Sample transaction data
  final List<Transaction> _transactions = [
    Transaction(
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: 'Food',
        amount: 500.0,
        description: 'Groceries'),
    Transaction(
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.income,
        category: 'Salary',
        amount: 20000.0,
        description: 'Monthly Salary'),
    Transaction(
        date: DateTime.now().subtract(const Duration(days: 7)),
        type: TransactionType.expense,
        category: 'Transport',
        amount: 1000.0,
        description: 'Fuel'),
    Transaction(
        date: DateTime.now(),
        type: TransactionType.expense,
        category: 'Food',
        amount: 100,
        description: "Lunch"),
  ];

  //date range
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String? _selectedCategory;
  TransactionType? _selectedTransactionType;
  final TextEditingController _searchController = TextEditingController();

  // Function to show date range picker
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  //get categories
  List<String> get _categories {
    Set<String> categories = {};
    for (var transaction in _transactions) {
      categories.add(transaction.category);
    }
    return categories.toList();
  }

  //filtered transactions
  List<Transaction> get _filteredTransactions {
    List<Transaction> transactions = _transactions;

    // Date range filter
    transactions = transactions.where((transaction) {
      return transaction.date.isAfter(_selectedDateRange.start) &&
          transaction.date.isBefore(_selectedDateRange.end);
    }).toList();

    // Category filter
    if (_selectedCategory != null) {
      transactions = transactions.where((transaction) {
        return transaction.category == _selectedCategory;
      }).toList();
    }

    // Transaction type filter
    if (_selectedTransactionType != null) {
      transactions = transactions.where((transaction) {
        return transaction.type == _selectedTransactionType;
      }).toList();
    }

    // Search filter
    final String searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      transactions = transactions.where((transaction) {
        return transaction.description.toLowerCase().contains(searchTerm);
      }).toList();
    }
    return transactions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //search
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Transactions',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  // Trigger filtering
                });
              },
            ),
            const SizedBox(height: 16),
            //filter row
            Row(
              children: [
                //category filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("All Categories"),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ],
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                const SizedBox(width: 10),
                //transaction type filter
                Expanded(
                  child: DropdownButtonFormField<TransactionType>(
                    value: _selectedTransactionType,
                    onChanged: (value) {
                      setState(() {
                        _selectedTransactionType = value;
                      });
                    },
                    items: [
                      const DropdownMenuItem<TransactionType>(
                        value: null,
                        child: Text("All Types"),
                      ),
                      ...TransactionType.values.map((type) {
                        return DropdownMenuItem<TransactionType>(
                          value: type,
                          child: Text(type == TransactionType.expense
                              ? "Expense"
                              : "Income"),
                        );
                      }).toList(),
                    ],
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Transaction List
            Expanded(
              child: _filteredTransactions.isEmpty? const Center(child: Text("No transactions found"),):
              ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Date: ${DateFormat('MMM dd, yyyy – kk:mm').format(transaction.date)}', // Added time
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Category: ${transaction.category}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Text(
                            '${transaction.type == TransactionType.expense ? "-" : "+"}₹${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              color: transaction.type == TransactionType.expense
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddTransactionScreen()),
          ).then((value) {
            if (value is Transaction) {
              // Handle the new transaction
              setState(() {
                _transactions.add(value);
              });
              //show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction added successfully'),
                ),
              );
            }
          });
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const FinanceZeroBottomNavigationBar(
        currentIndex: 1,
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'INR'; // Default currency
  DateFormat _dateFormat = DateFormat('MMM dd, yyyy'); // Default date format
  InputMethod _defaultInputMethod =
      InputMethod.text; // Default input method

  //show dialog for currency selection
  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('INR (₹)'),
                    value: 'INR',
                    groupValue: _selectedCurrency,
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('USD'),
                    value: 'USD',
                    groupValue: _selectedCurrency,
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                  // Add more currencies as needed
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  //save
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Currency saved'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  //show date format dialog
  void _showDateFormatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Date Format'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<DateFormat>(
                    title: const Text('MMM dd, yyyy'),
                    value: DateFormat('MMM dd, yyyy'),
                    groupValue: _dateFormat,
                    onChanged: (value) {
                      setState(() {
                        _dateFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<DateFormat>(
                    title: const Text('dd/MM/yyyy'),
                    value: DateFormat('dd/MM/yyyy'),
                    groupValue: DateFormat('dd/MM/yyyy'),
                    onChanged: (value) {
                      setState(() {
                        _dateFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<DateFormat>(
                    title: const Text('yyyy-MM-dd'),
                    value: DateFormat('yyyy-MM-dd'),
                    groupValue: DateFormat('yyyy-MM-dd'),
                    onChanged: (value) {
                      setState(() {
                        _dateFormat = value!;
                      });
                    },
                  ),
                  // Add more date formats
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  //save
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Date format saved'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  //show input method dialog
  void _showInputMethodDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Default Input Method'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<InputMethod>(
                    title: const Text('Text'),
                    value: InputMethod.text,
                    groupValue: _defaultInputMethod,
                    onChanged: (value) {
                      setState(() {
                        _defaultInputMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<InputMethod>(
                    title: const Text('Voice'),
                    value: InputMethod.voice,
                    groupValue: _defaultInputMethod,
                    onChanged: (value) {
                      setState(() {
                        _defaultInputMethod = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  //save
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Input method saved'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Currency Selection
            ListTile(
              title: const Text('Currency'),
              subtitle: Text(_selectedCurrency),
              onTap: _showCurrencyDialog,
            ),
            const Divider(),
            // Date Format
            ListTile(
              title: const Text('Date Format'),
              subtitle: Text('Date Format'),
              onTap: _showDateFormatDialog,
            ),
            const Divider(),
            // Default Input Method
            ListTile(
              title: const Text('Default Input Method'),
              subtitle:
              Text(_defaultInputMethod == InputMethod.text ? 'Text' : 'Voice'),
              onTap: _showInputMethodDialog,
            ),
            const Divider(),
            // Data Management
            ListTile(
              title: const Text('Backup Data'),
              onTap: () {
                // Implement backup logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data backed up successfully!'),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Restore Data'),
              onTap: () {
                // Implement restore logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data restored successfully!'),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Clear All Data'),
              onTap: () {
                // Implement clear data logic
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Clear Data"),
                      content: const Text(
                          "Are you sure you want to clear all data? This action cannot be undone."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancel")),
                        ElevatedButton(
                            onPressed: () {
                              //clear data
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text('All data cleared successfully!'),
                                ),
                              );
                            },
                            child: const Text("Clear"))
                      ],
                    ));
              },
            ),
            const Divider(),
            // About
            ListTile(
              title: const Text('About'),
              onTap: () {
                // Show about dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("About FinanceZero"),
                    content: const Text(
                        "FinanceZero is a personal finance tracking application. \n\nVersion: 1.0.0\n\nContact: support@financezero.com"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"),
                      )
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              onTap: () {
                // Open privacy policy
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text("Privacy Policy"),
                    content: Text("Privacy Policy Content"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FinanceZeroBottomNavigationBar(
        currentIndex: 2,
      ),
    );
  }
}

//data models
enum TransactionType { expense, income }

enum InputMethod { text, voice }

class Transaction {
  Transaction({
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
  });
  DateTime date;
  TransactionType type;
  String category;
  double amount;
  String description;
}
