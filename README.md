# FinanceZero - Your Personal Finance Tracker

## Overview

**FinanceZero** is a mobile application designed to help you effortlessly track your personal finances. It allows you to record income and expenses using either voice or text input, and it intelligently processes this information to provide you with a clear overview of your financial activity.

## Features

* **Intuitive Input:**

    * **Voice Input:** Record expenses and income hands-free using your voice.

    * **Text Input:** Manually enter transactions using a simple text field.

* **Automated Data Processing:**

    * The app uses a language model (Gemini) to automatically categorize your expenses, identify income sources, and handle split payments.

* **Clear Financial Overview:**

    * The dashboard provides a summary of your daily, monthly, and yearly income and expenses.

    * Visualizations help you understand your spending habits and identify trends.

* **Split Payment Tracking:**

    * Easily record expenses shared with others. The app calculates individual shares and tracks who owes you money.

* **Data Management:**

    * Store transaction data locally.

    * View, edit, and delete past transactions.

    * Data backup and restore functionality.

## How It Works

1.  **Recording Transactions:**

    * Use the "Add" button to record an expense or income.

    * Choose voice or text input.

    * The app captures the date and time automatically.

    * All entries are temporarily stored locally on your device.

2.  **End-of-Day Processing:**

    * At the end of the day, the app sends all your recorded entries to a language model.

    * The language model analyzes the data, categorizes transactions, and extracts relevant information.

    * The processed data is sent back to the app in a structured format.

3.  **Viewing Your Finances:**

    * The dashboard displays your financial summary based on the processed data.

    * Use visualizations to gain insights into your spending habits.

## Target Audience

FinanceZero is for anyone who wants a simple and effective way to track their personal finances without the hassle of manual categorization and calculations. It's particularly useful for:

* People who want to track their spending on the go.

* Users who share expenses with others.

* Anyone who wants a clear overview of their financial situation.

## Technical Details

* **Speech-to-Text:** [Name of Speech-to-Text Service, e.g., Google Cloud Speech-to-Text]

* **Language Model:** Google Gemini API

* **Data Storage:** [Name of Local Database, e.g., SQLite, Realm]

* **Programming Language:** [e.g., React Native, Flutter, Swift, Kotlin]

* **UI Framework:** [e.g.,  Native, Jetpack Compose, SwiftUI]

## Future Enhancements

* Budgeting features.

* Integration with bank accounts.

* Recurring transaction support.

* Customizable categories.

* Cross-platform synchronization.

## Disclaimer

FinanceZero is a personal project.