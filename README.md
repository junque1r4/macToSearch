# macToSearch

**Open-Source AI-Powered Visual Search for macOS** - A native application that transforms anything on your screen into an intelligent search, similar to Google's Circle to Search.

## 🚀 Overview

<img width="992" height="689" alt="image" src="https://github.com/user-attachments/assets/1de4bcb3-7817-4d70-adbd-fd62d29e1814" />

macToSearch is an open-source visual search tool that combines advanced screen capture, high-precision OCR, and generative AI (Google Gemini) to let you instantly search anything visible on your screen. With an elegant glassmorphic interface and intuitive keyboard shortcuts, it makes finding information faster and more natural than ever.

## ✨ Key Features

### 🎯 Intelligent Visual Capture
- **Circle to Search**: Press `Cmd+Shift+Space` to instantly activate capture mode
- **Flexible Selection**: Draw circles, rectangles, or freely select any area
- **Automatic Element Detection**: Intelligently identifies UI elements, text blocks, and images
- **High-Precision OCR**: Extracts text with 99.7% accuracy using native Vision framework

### 💬 Modern Floating Chat Interface
- **Minimalist Search Bar**: Compact interface that doesn't disrupt your workflow
- **Smart Expansion**: Automatically expands when you start typing
- **Contextual Conversation History**: Maintains context across multiple questions for more relevant answers
- **Multi-Image Support**: Attach and analyze multiple images simultaneously with drag & drop

### 🎨 Cutting-Edge Glassmorphic Design
- **Native Visual Effects**: Transparency and blur that integrate seamlessly with macOS
- **Animated Neon Gradient Borders**: Dynamic visuals with smooth animations
- **Automatic Dark Mode**: Instantly adapts to system theme
- **Spring Physics Animations**: Natural and responsive transitions between states

### ⚡ Performance & System Integration
- **Google Gemini AI Integration**: Ultra-fast contextual responses with latest generation models
- **Hybrid Local Processing**: OCR executed locally for maximum privacy
- **Global Hotkeys via Carbon API**: Works from any application, even in fullscreen
- **Menu Bar Integration**: Quick access via native menu bar icon
- **Clipboard Monitoring**: Automatically detects and processes copied content

## 🛠 Installation & Setup

### System Requirements
- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Xcode 15.0+ (for building from source)
- Internet connection for AI features

### Getting Started

#### Option 1: Build from Source (Recommended)

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/macToSearch.git
cd macToSearch
```

2. **Open in Xcode**
```bash
open macToSearch.xcodeproj
```

3. **Build and Run**
   - Press `Cmd+R` to build and run
   - Or use `Product > Archive` to create a release build

4. **Initial Setup**
   - On first launch, you'll be guided through a setup wizard
   - You'll need to provide your own Google Gemini API key
   - Get a free API key at [Google AI Studio](https://makersuite.google.com/app/apikey)
   - The key is stored securely in macOS Keychain

#### Option 2: Download Pre-built Release
- Check the [Releases](https://github.com/yourusername/macToSearch/releases) page for pre-built binaries
- Download, unzip, and drag to Applications folder
- Run and follow the setup wizard

### Required Permissions

On first run, macOS will request:
- **Screen Recording**: To capture screen content
- **Accessibility**: For global hotkeys to work
- Configure in: `System Settings > Privacy & Security`

### Security Note: Keychain Access

- **Why Keychain?** macToSearch stores your API key in the macOS Keychain for maximum security
- **Password Prompt**: When saving or accessing your API key, macOS will ask for your password
- **This is Normal**: The prompt ensures your API key is encrypted and protected by the system
- **Tip**: Click "Always Allow" to avoid repeated prompts for macToSearch

## 🎯 How to Use

### Quick Visual Search (Circle to Search)

1. **Activate Capture Mode**
   - Press `Cmd+Shift+Space` from anywhere
   - Or click the camera icon in the floating bar

2. **Select Area of Interest**
   - **Draw**: Circle or create rectangles around content
   - **Smart Click**: Automatically select UI elements
   - **Free Selection**: Draw any shape for precise capture
   - **ESC**: Cancel selection at any time

3. **Get Instant Results**
   - OCR automatically extracts text
   - AI analyzes context and provides relevant information
   - Continue the conversation to dive deeper into the topic

### Contextual AI Chat

1. **Open Chat Interface**
   - Press `Cmd+Shift+O` to open/focus
   - Or click the floating search bar

2. **Interact Naturally**
   - Type questions in natural language
   - Drag images directly for analysis
   - Use `Cmd+V` to paste images from clipboard
   - History maintains context between questions

### Clipboard Search

1. **Copy Any Content**
   - Text, images, or combinations

2. **Activate Search**
   - App automatically detects new content
   - Or click "Search Clipboard"

### ⌨️ Keyboard Shortcuts

| Shortcut | Action | Context |
|----------|--------|---------|
| `Cmd+Shift+Space` | Activate Circle to Search | Global |
| `Cmd+Shift+O` | Open/Focus Chat | Global |
| `ESC` | Close overlay or chat | During capture/chat |
| `Return` | Send message | In chat |
| `Cmd+V` | Paste image | In chat |
| `Cmd+Shift+S` | Open Settings | Global |

## 🤖 AI Models & Configuration

### Setting Up Your API Key

1. **Get a Free API Key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Click "Create API Key"
   - Copy the generated key

2. **Configure in macToSearch**
   - The setup wizard will appear on first launch
   - Paste your API key when prompted
   - The key is validated and stored securely in Keychain
   - You can change it later in Settings

### Available Models

| Model | Speed | Capability | Best For |
|-------|-------|------------|----------|
| **gemini-2.0-flash-exp** | ⚡⚡⚡⚡⚡ | Latest generation with reasoning | Complex analyses |
| **gemini-1.5-flash** | ⚡⚡⚡⚡ | Balanced | General use (recommended) |
| **gemini-1.5-flash-8b** | ⚡⚡⚡⚡⚡ | Lightweight | Simple responses |
| **gemini-1.5-pro** | ⚡⚡ | Maximum precision | Complex tasks |

### API Limits (Free Tier)
- **1,500 requests/day**: Sufficient for intensive personal use
- **No cost**: Free input/output tokens
- **Rate limit**: 15 RPM (requests per minute)
- **Context**: Up to 1M tokens per conversation

## 🏗 Architecture & Technologies

### Technology Stack

#### Language & Frameworks
- **Swift 5.9+**: Primary language with async/await and actors
- **SwiftUI**: Declarative UI with @Observable and property wrappers
- **AppKit**: System integration for custom windows

#### System APIs
- **ScreenCaptureKit**: Modern and efficient screen capture
- **Vision Framework**: OCR with 99.7% accuracy via VNRecognizeTextRequest
- **Carbon Events API**: Global hotkeys that work in any context
- **CoreGraphics**: Image manipulation and element detection
- **Security Framework**: Keychain integration for secure storage

#### Persistence & State
- **SwiftData**: Declarative modeling for history
- **@Observable**: Reactive state with automatic observation
- **Keychain**: Secure API key storage

### Project Structure

```
macToSearch/
├── 🎯 Core/
│   ├── macToSearchApp.swift      # Entry point with @main
│   ├── AppDelegate.swift         # Window and event coordinator
│   └── Models/
│       ├── AppState.swift        # Observable global state
│       └── DrawingPath.swift     # Selection geometry
│
├── 🪟 Windows/
│   ├── OverlayWindow.swift       # Fullscreen capture window
│   ├── FloatingSearchWindow.swift # Glassmorphic floating bar
│   └── SetupWindow.swift         # Initial setup wizard
│
├── 🎨 Views/
│   ├── DrawingOverlayView.swift  # Interactive selection canvas
│   ├── MinimalChatBubble.swift   # Chat components
│   ├── ImagePreviewBar.swift     # Attached images gallery
│   └── MarkdownTextView.swift    # Rich text rendering
│
├── 🔧 Managers/
│   ├── ScreenCaptureManager.swift # Capture strategies
│   ├── OCRManager.swift          # Text extraction pipeline
│   ├── HotkeyManager.swift       # Global shortcut registration
│   ├── KeychainManager.swift     # Secure credential storage
│   └── ElementDetector.swift     # Smart UI detection
│
└── 🌐 Services/
    ├── GeminiService.swift       # API client with retry and cache
    └── APIKeyValidator.swift     # Key validation and testing
```

### Architecture Patterns

- **MVVM with Coordinators**: Declarative Views + Observable ViewModels
- **Repository Pattern**: Isolated and testable services
- **State Management**: Single source of truth with AppState
- **Protocol-Oriented**: Abstractions for flexibility

## 🎨 Design System

### Glassmorphism Implementation

```swift
// Native macOS material effects
.background(.ultraThinMaterial)
.background(Color.gray.opacity(0.3))
.blur(radius: 20)
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .stroke(
            AngularGradient(
                colors: [.blue, .purple, .pink, .orange],
                center: .center
            ),
            lineWidth: 2
        )
)
```

### Design Principles

1. **Clarity through Transparency**: Context always visible
2. **Visual Hierarchy**: Progressive blur for depth
3. **Natural Movement**: Spring animations with realistic damping
4. **Vibrant Colors**: Animated gradients for visual feedback
5. **Functional Minimalism**: Every element has a clear purpose

## 🔒 Privacy & Security

### Privacy Principles

- **Local Processing First**: OCR and detection executed on device
- **No Telemetry**: No usage data is collected
- **Minimal Communication**: Only AI queries are sent to Gemini
- **Secure Storage**: API keys stored in Keychain, never in plaintext
- **Explicit Permissions**: User controls all access

### Data Transmitted

| Type | Local | Remote | Notes |
|------|-------|--------|-------|
| Screenshots | ✅ Yes | ❌ No | Processed and discarded |
| OCR Text | ✅ Yes | ⚠️ Optional | Only if sent to AI |
| History | ✅ Yes | ❌ No | SwiftData local |
| API Keys | ✅ Yes | ❌ No | Keychain encryption |
| AI Queries | ❌ No | ✅ Yes | HTTPS to Gemini |

## ⚠️ Known Issues & Solutions

### Screen Capture

**Issue**: Only wallpaper captured, no applications
- **Cause**: Incomplete Screen Recording permissions
- **Solution**:
  1. Open `Settings > Privacy > Screen Recording`
  2. Remove and re-add macToSearch
  3. Restart the app

**Issue**: macOS Sequoia requires monthly re-approval
- **Cause**: New Apple security policy
- **Solution**: Accept the monthly prompt or build locally

### Performance

**Issue**: Delay on first capture
- **Cause**: ScreenCaptureKit initialization
- **Solution**: Framework is pre-loaded after first use

**Issue**: Slow OCR on large images
- **Cause**: Synchronous high-resolution processing
- **Solution**: Automatic resizing implemented

### Compatibility

**Issue**: Hotkeys don't work in some apps
- **Cause**: Apps with exclusive keyboard capture
- **Solution**: Use menu bar icon as alternative

## 🚀 Development Roadmap

### v1.1 - Multi-Monitor & Cloud
- [ ] Full multi-monitor support
- [ ] iCloud history sync
- [ ] Inline automatic translation
- [ ] Export to Markdown/PDF

### v1.2 - AI Models & Offline
- [ ] Integration with GPT-4, Claude 3.5
- [ ] Offline mode with Llama 3.2
- [ ] App-specific plugins (Xcode, Figma)
- [ ] Third-party extension API

### v2.0 - Intelligence Platform
- [ ] Autonomous task agents
- [ ] RAG with local documents
- [ ] Apple Intelligence integration
- [ ] Team collaboration mode

## 🤝 Contributing

We welcome contributions! Here's how to get involved:

### Development Setup

```bash
# Clone and configure
git clone https://github.com/yourusername/macToSearch.git
cd macToSearch

# Install SwiftLint (optional but recommended)
brew install swiftlint

# Open in Xcode
open macToSearch.xcodeproj
```

### Contribution Process

1. **Fork** the project
2. **Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** with descriptive messages
4. **Push** to your branch
5. **Pull Request** with detailed description

### Code Standards

- Use idiomatic Swift and modern SwiftUI
- Maintain test coverage > 70%
- Document public APIs
- Follow existing design system
- Ensure API keys are never committed

### Ways to Contribute

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📝 Improve documentation
- 🌐 Add translations
- 🎨 Enhance UI/UX
- 🧪 Write tests
- 🔧 Optimize performance

## 📚 Resources & Documentation

### Useful Links
- [Gemini API Documentation](https://ai.google.dev/docs)
- [ScreenCaptureKit Guide](https://developer.apple.com/documentation/screencapturekit)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)

### Related Projects
- [Circle to Search (Google)](https://blog.google/products/search/circle-to-search-android/)
- [Screenshot to Code](https://github.com/abi/screenshot-to-code)
- [Codeshot](https://github.com/PolybrainAI/codeshot)

## 📄 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) for details.

```
MIT License
Copyright (c) 2025 macToSearch Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 Acknowledgments

- **Google** for the Gemini API and Circle to Search inspiration
- **Apple** for powerful native macOS APIs
- **Swift Community** for support and feedback
- **Contributors** for making this project better
- **You** for using and supporting the project!

---

<div align="center">

**Built with SwiftUI and AI** 🚀

Transforming how you search for information on macOS

[Report Bug](https://github.com/yourusername/macToSearch/issues) •
[Request Feature](https://github.com/yourusername/macToSearch/issues) •
[Discussions](https://github.com/yourusername/macToSearch/discussions)

</div>
