# Holloway Browser

A modern, lightweight web browser built with Flutter and Rust, designed to support alternative web protocols like Gemini, Gopher, and Finger. Holloway provides a clean, responsive interface that works seamlessly across desktop and mobile platforms.

## 🌟 Features

### **Multi-Protocol Support**
- **Gemini Protocol**: Secure, modern alternative to HTTP with built-in TLS encryption
- **Gopher Protocol**: Classic hierarchical information system
- **Finger Protocol**: User information lookup service
- **Automatic Protocol Detection**: Smart fallback system for URLs without schemes

### **User Interface**
- **Responsive Design**: Adapts seamlessly between desktop and mobile layouts
- **Modern Material Design**: Built with Flutter's Material 3 components
- **Tab Management**: Multiple tabs with independent browsing sessions
- **Search Integration**: Built-in search bar with intelligent URL handling

### **Smart URL Handling**
- **Automatic Scheme Detection**: Automatically adds `gemini://` prefix for URLs without schemes
- **URL Normalization**: Ensures proper formatting for protocol compatibility
- **Fallback Search**: Integrates with search services when direct connections fail
- **Error Recovery**: Graceful handling of connection failures with alternative options

## 🏗️ Architecture

### **Frontend (Flutter)**
- **Cross-Platform**: Single codebase for Linux, macOS, Windows, Android, and iOS
- **Responsive Layout**: Automatic switching between desktop and mobile interfaces
- **State Management**: Provider pattern for efficient state management
- **Component-Based**: Modular UI components for maintainability

### **Backend (Rust)**
- **High Performance**: Rust backend for fast, memory-safe operations
- **Protocol Implementations**: Native implementations of Gemini, Gopher, and Finger
- **Flutter Rust Bridge**: Seamless integration between Flutter and Rust
- **Modular Design**: Clean separation of concerns with dedicated protocol modules

### **Protocol Modules**
```
rust/src/api/
├── exposed_functions.rs    # Main API functions exposed to Flutter
├── functions/
│   └── navigate_internal.rs # Core navigation logic with fallback system
└── protocols/
    ├── gemini/             # Gemini protocol implementation
    ├── gopher/             # Gopher protocol implementation
    └── finger/             # Finger protocol implementation
```

## 🚀 Getting Started

### **Prerequisites**
- **Flutter SDK**: Version 3.0 or higher
- **Rust Toolchain**: Latest stable version
- **Development Tools**: Git, Cargo, Flutter CLI

### **Installation**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/holloway.git
   cd holloway
   ```

2. **Install Dependencies**
   ```bash
   # Install Flutter dependencies
   flutter pub get
   
   # Install Rust dependencies
   cd rust
   cargo build
   cd ..
   ```

3. **Generate Bindings**
   ```bash
   # Generate Flutter Rust Bridge bindings
   flutter_rust_bridge_codegen generate
   ```

4. **Run the Application**
   ```bash
   # For desktop (Linux/macOS/Windows)
   flutter run -d linux
   
   # For mobile
   flutter run -d android
   flutter run -d ios
   ```

### **Development Setup**

1. **Rust Development**
   ```bash
   cd rust
   cargo check          # Check for compilation errors
   cargo test           # Run tests
   cargo clippy         # Lint code
   ```

2. **Flutter Development**
   ```bash
   flutter analyze      # Analyze Dart code
   flutter test         # Run Flutter tests
   flutter build        # Build for production
   ```

## 🔧 Configuration

### **Protocol Settings**
- **Gemini**: Default port 1965, automatic TLS handling
- **Gopher**: Default port 70, text-based protocol
- **Finger**: Default port 79, user information lookup

### **Fallback Configuration**
- **Primary Fallback**: `gemini://kennedy.gemi.dev/search?`
- **URL Normalization**: Automatic trailing slash addition for root paths
- **Error Handling**: Graceful degradation with search integration

## 📱 Usage

### **Basic Navigation**
1. **Direct URL Entry**: Type any URL with or without protocol scheme
2. **Automatic Detection**: Holloway automatically detects and applies appropriate protocols
3. **Smart Fallbacks**: If direct connection fails, falls back to search services

### **Supported URL Formats**
- `tilde.town` → Automatically becomes `gemini://tilde.town/`
- `gemini://tilde.town` → Direct Gemini connection
- `gemini://tilde.town/` → Root path with trailing slash
- `gopher://gopher.floodgap.com` → Direct Gopher connection
- `finger://example.com/user` → Finger user lookup

### **Tab Management**
- **New Tab**: Automatically loads start page
- **Multiple Tabs**: Independent browsing sessions
- **Tab Switching**: Seamless navigation between tabs

## 🧪 Testing

### **Rust Testing**
```bash
cd rust
cargo test                    # Run all tests
cargo test --lib             # Run library tests only
cargo test --bins            # Run binary tests only
```

### **Flutter Testing**
```bash
flutter test                 # Run all tests
flutter test test/           # Run specific test directory
flutter test --coverage      # Generate coverage report
```

### **Integration Testing**
```bash
flutter drive --target=test_driver/integration_test.dart
```

## 🚀 Building for Production

### **Desktop Builds**
```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

### **Mobile Builds**
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### **Web Build**
```bash
flutter build web --release
```

## 🤝 Contributing

### **Development Guidelines**
1. **Code Style**: Follow Rust and Dart formatting standards
2. **Testing**: Write tests for new features and bug fixes
3. **Documentation**: Update documentation for API changes
4. **Protocol Support**: Ensure new protocols follow existing patterns

### **Adding New Protocols**
1. Create new module in `rust/src/api/protocols/`
2. Implement `connect_and_fetch_*` function
3. Add protocol handling in `navigate_internal.rs`
4. Update module declarations in `mod.rs`
5. Regenerate bindings with `flutter_rust_bridge_codegen`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the excellent cross-platform framework
- **Rust Community**: For the safe, fast systems programming language
- **Gemini Protocol**: For the modern alternative web protocol
- **Gopher Community**: For preserving the classic protocol

## 📞 Support

- **Issues**: Report bugs and feature requests on GitHub
- **Discussions**: Join community discussions
- **Documentation**: Check the wiki for detailed guides
- **Contributing**: See CONTRIBUTING.md for development guidelines

---

**Holloway Browser** - Bridging the past and future of the web, one protocol at a time.
