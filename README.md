# DoneToday

**(WIP)**

A beautiful, local-first logging or journaling that matters most application built with Flutter.

<img width="1309" height="848" alt="dashboard" src="https://github.com/user-attachments/assets/c8fd92ec-f780-4628-8df4-3a2e120603d6" />

DoneToday is designed for high-intent users who want to track their daily progress, build lasting habits through challenges, and maintain a private digital sanctuary for their thoughts.

## 🚀 Key Features

- **Daily Journaling:** Capture your thoughts with Markdown support, interactive checkboxes, and mood tracking.
- **Challenges:** Start goal-oriented challenges (e.g., 30 days of coding, 100 days of fitness) and track your daily consistency.
- **Deep Analytics:** Visualize your momentum, streaks, word counts, and mood patterns through beautiful, interactive charts.
- **Privacy First:** 100% local storage. Your data never leaves your device unless you choose to export a backup.
- **Dynamic Theming:** Supports Light, Dark, and "True Black" modes with custom seed colors and responsive layouts.
- **Data Portability:** Easy JSON-based export and import for local backups.

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Universal UI)
- **State Management:** [Riverpod](https://riverpod.dev) (Functional & Type-safe)
- **Local Database:** [Hive](https://pub.dev/packages/hive) (High-performance NoSQL)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing)
- **Charts:** [FL Chart](https://pub.dev/packages/fl_chart)
- **Markdown:** [GPT Markdown](https://pub.dev/packages/gpt_markdown) (with custom interactive components)

## 📦 Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Dart SDK

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/donetoday-app.git
   cd donetoday-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📂 Project Structure

- `lib/providers/`: State management notifiers (Auth, Logs, Challenges, Settings).
- `lib/storage/`: Hive models and persistence logic.
- `lib/ui/`: All screens and reusable widgets, organized by feature.
- `lib/services/`: Core logic for analytics, backups, and updates.
- `lib/theme/`: Custom design system and constants.

## 🤝 Contributing

This project is now open-source. Contributions are welcome! Whether it's a bug fix, a new feature, or improving documentation, feel free to open an issue or submit a pull request.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
