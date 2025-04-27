# FinanceZero - Your Personal Finance Tracker

## Overview

**FinanceZero** is a Flutter mobile application designed to help you effortlessly track your personal finances. It allows you to record income and expenses using either voice or text input, and it intelligently processes this information to provide you with a clear overview of your financial activity.

## Features

* **Intuitive Input:**
    * **Voice Input:** Record expenses and income hands-free using your voice
    * **Text Input:** Manually enter transactions using a simple text field

* **Automated Data Processing:**
    * The app uses Google's Gemini language model to automatically categorize your expenses and identify income sources
    * Raw entries are analyzed and converted into structured transaction data

* **Clear Financial Overview:**
    * Summary cards display your total income, expenses, and current balance
    * Visualizations help you understand your spending habits through intuitive charts

* **Comprehensive Insights:**
    * Expense breakdown by category with pie charts
    * Monthly income vs expense comparison
    * Filtering options to view specific transaction types or categories

* **Data Management:**
    * Store transaction data locally using Hive database
    * View, edit, and delete past transactions
    * Raw entries are stored separately from processed transactions

## How It Works

1. **Recording Transactions:**
    * Enter financial information via text or voice input
    * The app captures the details as raw entries
    * All entries are stored locally on your device using Hive

2. **AI-Powered Processing:**
    * Click the analysis button to process your raw entries
    * Gemini AI analyzes the data, categorizes transactions, and extracts amounts and descriptions
    * The processed data is stored back in your device as structured transactions

3. **Viewing Your Finances:**
    * The Transactions tab displays your financial summary and detailed transaction list
    * The Insights tab provides visual representations of your financial data
    * Filter transactions by type (income/expense) or category for detailed analysis

## Technical Details

* **Framework:** Flutter
* **Speech-to-Text:** speech_to_text package
* **Language Model:** Google Gemini API (gemini-1.5-flash-latest)
* **Data Storage:** Hive Flutter (local NoSQL database)
* **Charts:** fl_chart package
* **Date Formatting:** intl package

## Implementation Details

* **Tab-Based Interface:**
    * Transactions view with summary cards and detailed transaction list
    * Insights view with category pie chart and income vs expense comparison
    * Raw entries view for unprocessed data

* **Voice Recognition:**
    * Uses the speech_to_text package for voice input
    * Converts spoken words to text for financial entry

* **AI Analysis:**
    * Sends raw entries to Gemini API for processing
    * Extracts transaction type, category, amount, and description

* **Data Visualization:**
    * Pie charts for expense categories
    * Bar charts for monthly income vs expense comparison

## Setup Instructions

1. Clone the repository
2. Ensure Flutter is installed and set up on your development environment
3. Run `flutter pub get` to install dependencies
4. Set up your Gemini API key using the environment variable:
   ```
   flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
   ```

## Future Enhancements

* Budgeting features
* Customizable categories
* Date-based transaction filtering
* Export functionality for reports
* Recurring transaction support
* Multi-currency support

## Dependencies

* flutter_material
* hive_flutter
* speech_to_text
* google_generative_ai
* fl_chart
* intl

## Disclaimer

FinanceZero is a personal project aimed at simplifying personal finance tracking. It stores all data locally on your device. The app requires an active internet connection only for voice recognition and AI analysis features.
