# 💰 Expense Tracker App (Advanced Version)

A **Flutter-based personal finance app** to manage income and expenses efficiently — featuring category-wise budgets, charts, SQLite persistence, and test coverage.  
It follows **clean architecture**, uses **Riverpod for state management**, and includes **unit & widget testing** for reliability.

---

## 🚀 Features

✅ Add, edit, delete, and restore transactions  
✅ Category-wise monthly budget tracking  
✅ Real-time expense chart visualization  
✅ SQLite local database (persistent storage)  
✅ CSV export & sharing support  
✅ Swipe-to-delete with Undo  
✅ Unit and widget tests for CRUD & Dashboard  
✅ Clean, modular, and scalable codebase  

---

## 🛠️ Setup Instructions

### 1. Clone the repository
```bash
git clone git@github.com:Ritesh-1310/Smart-Expense-Tracker-App.git
cd Smart-Expense-Tracker-App
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the app
```bash
flutter run
```

### 4. Run all tests
```bash
flutter test
```

---

## 🧱 Folder Structure & Architecture

```
lib/
├── main.dart                     # App entry point
│
├── models/
│   └── transaction_model.dart    # Data model for transactions
│
├── db/
│   └── db_helper.dart            # SQLite helper (CRUD, initialization)
│
├── providers/
│   └── transaction_provider.dart # Riverpod StateNotifier for state management
│
├── screens/
│   ├── dashboard_screen.dart     # Dashboard with charts & totals
│   ├── add_transaction_screen.dart # Form to add or edit a transaction
│   └── budget_screen.dart        # Set monthly budgets per category
│
├── widgets/
│   ├── transaction_tile.dart     # UI for displaying transaction list items
│   └── expense_chart.dart        # Category-wise expense chart using Syncfusion

```

---

## 🌀 State Management: Riverpod

The app uses **Riverpod’s `StateNotifierProvider`** for predictable, testable state updates.

### Example
```dart
final transactionProvider = 
  StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
    (ref) => TransactionNotifier(ref),
  );
```

Benefits:
- Reactive UI updates when data changes  
- Testable state without relying on BuildContext  
- Easy overrides for unit & widget testing  

---

## 💾 Database Layer (SQLite)

SQLite is used via `sqflite` package for storing and managing data locally.

**DB Helper (db_helper.dart):**
- Initializes and opens local database
- Defines CRUD operations for transactions
- Maps database rows to `TransactionModel`
- Supports category-wise aggregation for charts

---

## 📊 Analytics & Charts

- Built using `syncfusion_flutter_charts`
- Displays **expense distribution per category**
- Updates reactively as transactions change

---

## 📤 CSV Export & Share

- Uses `csv` package to generate CSV from transactions  
- Uses `share_plus` to share exported files easily  

---

## 🧩 Testing Strategy

### ✅ Unit Tests
Located in:
```
test/unit/
```

Tests:
- Transaction CRUD logic (add, update, delete, restore)
- Database helper 

Run:
```bash
flutter test test/unit/db_helper_test.dart
flutter test test/unit/transaction_notifier_test.dart
```

### ✅ Widget Tests
Located in:
```
test/widget/
```

Tests:
- Home screen transaction list rendering
- Swipe-to-delete and Undo
- Dashboard & chart visualization

Run:
```bash
flutter test test/widget/home_screen_test.dart
flutter test test/widget/add_transaction_screen_test.dart
```

---

## 🧪 Test Coverage Summary

| Test Type         | Description                                       | Status |
|-------------------|---------------------------------------------------|---------|
| **Unit Tests**    | Transaction CRUD & DB interactions                | ✅ Pass |
| **Widget Tests**  | UI integration for dashboard & lists              | ✅ Pass |


Generate HTML coverage report:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Then open:
```
coverage/html/index.html
```

---

## 📦 Tech Stack

| Category | Technology |
|-----------|-------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Local Storage | SQLite (`sqflite`) |
| CSV Export | `csv`, `share_plus` |
| Charts | `syncfusion_flutter_charts` |
| Testing | `flutter_test`, `mocktail` |

---

## 📱 Screens

- Dashboard(HomeScreen) with income, expense & balance  
- Add Transaction with category selector  
- Transaction List with swipe-to-delete & Undo  
- Category-wise Expense Pie Chart  
- Budget Setup Screen  

---

## 👨‍💻 Author

**Ritesh Ranjan**  
Software Development Engineer — Flutter | Node.js | MongoDB  
📧 [Email](mailto:ranjan.official1310@gmail.com) | 🧑‍💻 [GitHub](https://github.com/Ritesh-1310)

---

## 🏁 License

This project is open-source and available under the **MIT License**.
