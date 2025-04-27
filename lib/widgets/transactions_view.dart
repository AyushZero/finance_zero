import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionsView extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Transaction> filteredTransactions;
  final List<String> availableCategories;
  final String? selectedTypeFilter;
  final String? selectedCategoryFilter;
  final bool isAnalyzing;
  final String? analysisError;
  final Function(int) onDeleteTransaction;
  final VoidCallback onResetFilters;
  final Function(String?) onTypeFilterSelected;
  final Function(String?) onCategoryFilterSelected;
  final VoidCallback onAddManualTransaction;  // New parameter

  const TransactionsView({
    super.key,
    required this.transactions,
    required this.filteredTransactions,
    required this.availableCategories,
    required this.selectedTypeFilter,
    required this.selectedCategoryFilter,
    required this.isAnalyzing,
    required this.analysisError,
    required this.onDeleteTransaction,
    required this.onResetFilters,
    required this.onTypeFilterSelected,
    required this.onCategoryFilterSelected,
    required this.onAddManualTransaction,  // New parameter
  });


  @override
  Widget build(BuildContext context) {
    if (isAnalyzing) {
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

    if (analysisError != null) {
      return Center(
        child: Text('Analysis Error: $analysisError', style: const TextStyle(color: Colors.red)),
      );
    }

    if (transactions.isEmpty) {
      return Stack(
        children: [
          const Center(
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
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: onAddManualTransaction,
              tooltip: 'Add Manual Transaction',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in transactions) {
      if (transaction.type == 'income' && transaction.amount != null) {
        totalIncome += transaction.amount!;
      } else if (transaction.type == 'expense' && transaction.amount != null) {
        totalExpense += transaction.amount!;
      }
    }

    double balance = totalIncome - totalExpense;

    return Stack(
      children: [
        Column(
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
                        selected: selectedTypeFilter == null && selectedCategoryFilter == null,
                        onSelected: (selected) {
                          if (selected) {
                            onResetFilters();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Income'),
                        selected: selectedTypeFilter == 'income',
                        onSelected: (selected) {
                          onTypeFilterSelected(selected ? 'income' : null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Expenses'),
                        selected: selectedTypeFilter == 'expense',
                        onSelected: (selected) {
                          onTypeFilterSelected(selected ? 'expense' : null);
                        },
                      ),
                      if (availableCategories.isNotEmpty)
                        PopupMenuButton<String>(
                          child: Chip(
                            label: Text(selectedCategoryFilter ?? 'Categories'),
                            deleteIcon: selectedCategoryFilter != null ? const Icon(Icons.close, size: 18) : null,
                            onDeleted: selectedCategoryFilter != null ? () {
                              onCategoryFilterSelected(null);
                            } : null,
                          ),
                          onSelected: onCategoryFilterSelected,
                          itemBuilder: (BuildContext context) {
                            return availableCategories.map((String category) {
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
                    'Showing ${filteredTransactions.length} of ${transactions.length} transactions',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (selectedTypeFilter != null || selectedCategoryFilter != null)
                    TextButton(
                      onPressed: onResetFilters,
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            ),

            // Transactions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80.0, left: 8.0, right: 8.0, top: 8.0),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final item = filteredTransactions[index];
                  final type = item.type ?? 'unclear';
                  final category = item.category ?? 'N/A';
                  final amount = item.amount;
                  final description = item.description ?? 'N/A';

                  Color typeColor = type == 'income' ? Colors.green : (type == 'expense' ? Colors.red : Colors.grey);
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
                    onDismissed: (_) => onDeleteTransaction(index),
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
                          onPressed: () => onDeleteTransaction(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 72,
          child: FloatingActionButton(
            onPressed: onAddManualTransaction,
            tooltip: 'Add Manual Transaction',
            child: const Icon(Icons.add),
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
}