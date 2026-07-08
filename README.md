

# 🎵 Sollu

Sollu is a Flutter application designed to fetch and download lyrics for the song you are currently listening to. Built with a strong focus on the Indian music ecosystem, it seamlessly supports regional languages alongside English, wrapped in a beautifully customized typographic experience.

---

## 📱 Screenshots

| Home Screen | Lyrics View | Search |
| :---: | :---: | :---: |
| ![Home Screen](https://placehold.co/250x500/1DB954/FFFFFF?text=PLace+Holder) | ![Lyrics View](https://placehold.co/250x500/282828/FFFFFF?text=PLace+Holder) | ![Search Screen](https://placehold.co/250x500/121212/FFFFFF?text=PLace+Holder) |

---

## ✨ Key Features

* **Real-Time Lyrics:** Automatically retrieves lyrics for the song you're currently playing.
* **Regional Support (IN):** Tailored for the Indian audience, supporting lyrics in Tamil, Hindi, Telugu, Malayalam, and other regional languages with perfect UTF-8 rendering.
* **Customized Typography:** Beautiful, hand-picked fonts using `google_fonts` to ensure lyrics are displayed elegantly, including native, highly-readable scripts for Indian languages.
* **Offline Access:** Save your favorite lyrics locally using SQLite for uninterrupted reading without an internet connection.
* **Seamless Navigation:** Smooth routing and deep-linking powered by `go_router`.

---

## 🛠️ Tech Stack

This project is built using modern Flutter packages to provide a scalable and maintainable architecture.

- **State Management:** `flutter_riverpod`
- **Networking:** `http`
- **Local Database:** `sqflite`
- **Routing:** `go_router`
- **Custom Fonts:** `google_fonts`
- **Storage & Caching:** `shared_preferences`, `cached_network_image`
- **Utilities:** `path_provider`, `permission_handler`

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- Flutter SDK (3.0.0 or later)
- Dart SDK
- Android Studio, VS Code, or Xcode
- A physical device or emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/LeoAj2005/sollu.git
   cd sollu
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**

   ```bash
   flutter run
   ```

### Build the App (Optional)

Build a release version for your preferred platform:

**Android APK**
```bash
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

---

## 📂 Project Structure

```text
lib/
├── core/
├── features/
├── models/
├── providers/
├── services/
├── widgets/
└── main.dart
```

---

## 📦 Dependencies

Install or update dependencies at any time with:

```bash
flutter pub get
```

To upgrade packages:

```bash
flutter pub upgrade
```
    

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1.  Fork it
    
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
    
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
    
4.  Push to the branch (`git push origin feature/AmazingFeature`)
    
5.  Open a Pull Request
    

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.