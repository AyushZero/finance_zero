import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';

class InsightsView extends StatelessWidget {
  final List<Transaction> transactions;
  final int selectedChartTab;
  final TabController insightsTabController;

  const InsightsView({
    super.key,
    required this.transactions,
    required this.selectedChartTab,
    required this.insightsTabController,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
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
          controller: insightsTabController,
          tabs: const [
            Tab(text: 'Expense Categories'),
            Tab(text: 'Income vs Expense'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: insightsTabController,
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

    for (var transaction in transactions) {
      // Only include expenses
      if (transaction.type == 'expense' && transaction.amount != null) {
        String category = transaction.category ?? 'Uncategorized';
        double amount = transaction.amount!;

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
    final now = DateTime.now();

    // Initialize the last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthName = _getMonthName(month);
      monthlyData[monthName] = {'income': 0, 'expense': 0};
    }

    // Assuming all transactions are from current month for simplicity
    // In a real app, you would use date information from transactions
    final currentMonth = _getMonthName(now);

    for (var transaction in transactions) {
      if (transaction.amount == null) continue;

      double amount = transaction.amount!;
      String type = transaction.type ?? 'unclear';

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

  String _getMonthName(DateTime date) {
    switch (date.month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }
}