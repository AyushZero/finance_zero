class Transaction {
  final String? type;
  final String? category;
  final double? amount;
  final String? description;
  final String originalEntry;
  final DateTime date; // New field for transaction date

  Transaction({
    this.type,
    this.category,
    this.amount,
    this.description,
    required this.originalEntry,
    DateTime? date, // Optional date parameter
  }) : date = date ?? DateTime.now(); // Default to current date if not provided

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      type: json['type'],
      category: json['category'],
      amount: json['amount']?.toDouble(),
      description: json['description'],
      originalEntry: json['original_entry'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'original_entry': originalEntry,
      'date': date.toIso8601String(), // Store date as ISO string
    };
  }
}