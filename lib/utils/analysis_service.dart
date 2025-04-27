import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';

class AnalysisService {
  final String apiKey;

  AnalysisService({required this.apiKey});

  Future<List<Transaction>> analyzeEntries(List<String> entries) async {
    final entriesString = entries.map((e) => "- $e").join("\n");
    final prompt = """
Analyze the following list of personal finance entries. For each entry, determine if it's an 'income' or 'expense', assign a relevant category (e.g., 'Food', 'Salary', 'Transport', 'Shopping', 'Utilities', 'Entertainment', 'Rent', 'Other Income', 'Other Expense'), estimate the monetary amount (as a number without currency symbols), extract a brief description, and infer a date if possible (in ISO 8601 format: YYYY-MM-DD).

If an entry contains date information, use it. If no date is specified, assume the current date. If an entry is unclear or lacks detail for categorization or amount extraction, use 'Uncategorized' for category and null for amount.

Provide the output STRICTLY as a JSON list of objects. Each object must have these keys: 'original_entry' (string), 'type' (string: 'income', 'expense', or 'unclear'), 'category' (string), 'amount' (number or null), 'description' (string), 'date' (string in YYYY-MM-DD format).

Entries:
$entriesString

JSON Output:
""";

    print("Sending prompt to Gemini:\n$prompt");

    final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
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
      return decodedList.map((item) {
        if (item is Map<String, dynamic>) {
          return Transaction.fromJson(item);
        } else {
          throw const FormatException("Parsed item is not a Map<String, dynamic>");
        }
      }).toList();
    } on FormatException catch (e) {
      print("JSON Parsing Error: $e");
      print("Cleaned JSON String was: $cleanedJson");
      throw Exception("Failed to parse Gemini response as valid JSON list. Response was:\n${response.text}");
    }
  }
}