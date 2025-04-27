class Transaction {
  final String? type;
  final String? category;
  final double? amount;
  final String? description;
  final String originalEntry;

  Transaction({
    this.type,
    this.category,
    this.amount,
    this.description,
    required this.originalEntry,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      type: json['type'],
      category: json['category'],
      amount: json['amount']?.toDouble(),
      description: json['description'],
      originalEntry: json['original_entry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'original_entry': originalEntry,
    };
  }
}