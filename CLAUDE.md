# CLAUDE.md - macToSearch Development Guide

## 🎯 Project Context

macToSearch is a **premium macOS application** that implements Google's Circle to Search functionality with advanced AI capabilities. This is a **SwiftUI-first** project targeting **macOS 14.0+** with a focus on **glassmorphic design**, **native performance**, and **exceptional user experience**.

## 🏗 Architecture Principles

### MANDATORY Requirements
- **BP-1 (MUST)**: ALWAYS use SwiftUI with @Observable pattern for state management
- **BP-2 (MUST)**: NEVER use UIKit/AppKit unless absolutely necessary for system integration
- **BP-3 (MUST)**: ALWAYS implement proper error handling with Result types or async throws
- **BP-4 (MUST)**: NEVER commit API keys or sensitive data - use environment variables
- **BP-5 (MUST)**: ALWAYS maintain 99%+ Swift code (no Objective-C unless required by system APIs)

### Design System Requirements
- **DS-1 (MUST)**: ALWAYS use glassmorphic design with `.ultraThinMaterial` or `.regularMaterial`
- **DS-2 (MUST)**: IMPLEMENT animated gradients for borders and highlights:
  ```swift
  AngularGradient(
      colors: [.blue, .purple, .pink, .orange, .yellow, .green, .blue],
      center: .center,
      angle: .degrees(rotation)
  )
  ```
- **DS-3 (MUST)**: USE spring animations with natural physics:
  ```swift
  .animation(.spring(response: 0.5, dampingFraction: 0.8), value: state)
  ```
- **DS-4 (MUST)**: MAINTAIN consistent corner radius: 20pt for cards, 28pt for main elements
- **DS-5 (MUST)**: SUPPORT Dark Mode automatically using semantic colors

## 💻 Swift & SwiftUI Standards

### Code Style Guidelines

```swift
// CORRECT: Modern Swift with explicit types where helpful
@Observable
final class ScreenCaptureManager {
    private(set) var isCapturing = false
    private let captureQueue = DispatchQueue(label: "capture", qos: .userInitiated)
    
    func captureScreen() async throws -> NSImage {
        // Implementation
    }
}

// WRONG: Old patterns
class ScreenCaptureManager: ObservableObject {
    @Published var isCapturing: Bool = false // Don't use @Published with @Observable
}
```

### SwiftUI Best Practices

```swift
// CORRECT: Extracted views with clear responsibilities
struct FloatingSearchBar: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    
    var body: some View {
        // Focused implementation
    }
}

// WRONG: Massive single views
struct ContentView: View {
    // 500+ lines of nested views
}
```

### Async/Await Pattern

```swift
// CORRECT: Modern concurrency
func processImage(_ image: NSImage) async throws -> ProcessedResult {
    async let ocrResult = extractText(from: image)
    async let analysisResult = analyzeContent(of: image)
    
    let (text, analysis) = try await (ocrResult, analysisResult)
    return ProcessedResult(text: text, analysis: analysis)
}

// WRONG: Callback hell or completion handlers
```

## 🎨 Glassmorphism Implementation

### Required Visual Effects

```swift
// Standard glass background for all floating elements
.background {
    ZStack {
        Color.clear
            .background(.ultraThinMaterial)
            .blur(radius: 20)
        
        Color(NSColor.controlBackgroundColor)
            .opacity(0.3)
    }
}
.clipShape(RoundedRectangle(cornerRadius: 20))
.overlay {
    RoundedRectangle(cornerRadius: 20)
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.3), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
}
```

### Neon Border Animation

```swift
// Required for primary interactive elements
@State private var gradientRotation = 0.0

.overlay {
    RoundedRectangle(cornerRadius: 28)
        .stroke(
            AngularGradient(
                colors: [.blue, .purple, .pink, .orange, .yellow, .green, .blue],
                center: .center,
                angle: .degrees(gradientRotation)
            ),
            lineWidth: 2
        )
        .shadow(color: .blue.opacity(0.6), radius: 10)
        .shadow(color: .purple.opacity(0.4), radius: 15)
}
.onAppear {
    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
        gradientRotation = 360
    }
}
```

## 🔧 Project-Specific Commands

### Build & Test
```bash
# Development build with verbose output
xcodebuild -project macToSearch.xcodeproj -scheme macToSearch -configuration Debug build

# Run all tests
xcodebuild test -project macToSearch.xcodeproj -scheme macToSearch

# Create release archive
xcodebuild archive -project macToSearch.xcodeproj -scheme macToSearch -archivePath ./build/macToSearch.xcarchive

# Export for distribution
xcodebuild -exportArchive -archivePath ./build/macToSearch.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
```

### Code Quality
```bash
# Run SwiftLint (must be installed)
swiftlint

# Auto-fix SwiftLint issues
swiftlint --fix

# Check for unused code
periphery scan
```

## 🏛 File Organization

### MANDATORY Structure
```
Feature/
├── Models/          # Data models and state
├── Views/           # SwiftUI views only
├── ViewModels/      # @Observable view models
├── Services/        # External integrations
└── Utilities/       # Helpers and extensions
```

### Naming Conventions
- **Views**: `[Feature]View.swift` (e.g., `DrawingOverlayView.swift`)
- **View Models**: `[Feature]ViewModel.swift` or `[Feature]State.swift`
- **Services**: `[Feature]Service.swift` (e.g., `GeminiService.swift`)
- **Models**: Singular nouns (e.g., `SearchHistory.swift`, not `SearchHistories.swift`)

## 🚀 Performance Requirements

### Optimization Checklist
- [ ] Views are extracted when > 50 lines
- [ ] Heavy computations use `Task.detached`
- [ ] Images are cached after processing
- [ ] Animations use `.animation` modifier, not `withAnimation` where possible
- [ ] List/ScrollView uses `LazyVStack` for large datasets
- [ ] @Observable properties are `private(set)` when possible

### Memory Management
```swift
// CORRECT: Weak self in closures
Task { [weak self] in
    guard let self else { return }
    await self.processData()
}

// CORRECT: Proper cleanup
.onDisappear {
    captureTask?.cancel()
    captureTask = nil
}
```

## 🔒 Security & Privacy

### API Key Management
```swift
// NEVER hardcode keys
private let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""

// Store in Keychain for production
KeychainWrapper.standard.set(apiKey, forKey: "gemini_api_key")
```

### Permission Handling
```swift
// ALWAYS check permissions before accessing
func requestScreenRecordingPermission() async -> Bool {
    guard !CGPreflightScreenCaptureAccess() else { return true }
    
    return await withCheckedContinuation { continuation in
        CGRequestScreenCaptureAccess { granted in
            continuation.resume(returning: granted)
        }
    }
}
```

## 🐛 Error Handling

### Standard Error Pattern
```swift
enum CaptureError: LocalizedError {
    case permissionDenied
    case captureFailure(underlying: Error)
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission is required"
        case .captureFailure(let error):
            return "Capture failed: \(error.localizedDescription)"
        case .processingTimeout:
            return "Processing took too long"
        }
    }
}
```

## 📝 Documentation Standards

### Required Documentation
```swift
/// Captures the current screen and returns a processed image
/// - Parameters:
///   - region: The specific region to capture, nil for full screen
///   - options: Capture configuration options
/// - Returns: A processed NSImage ready for OCR
/// - Throws: `CaptureError` if permissions are missing or capture fails
func captureScreen(
    region: CGRect? = nil,
    options: CaptureOptions = .default
) async throws -> NSImage
```

## 🧪 Testing Requirements

### Test Coverage Goals
- **Unit Tests**: 80%+ coverage for Services and ViewModels
- **Integration Tests**: Critical user flows (capture → OCR → AI)
- **UI Tests**: Happy path for main features

### Test Structure
```swift
final class GeminiServiceTests: XCTestCase {
    var sut: GeminiService!
    
    override func setUp() {
        super.setUp()
        sut = GeminiService(apiKey: "test_key")
    }
    
    func testSearchWithText() async throws {
        // Given
        let query = "test query"
        
        // When
        let result = try await sut.searchWithText(query)
        
        // Then
        XCTAssertFalse(result.isEmpty)
    }
}
```

## 🎯 AI Integration Guidelines

### Gemini API Best Practices
```swift
// ALWAYS include system prompts for consistency
private func buildPrompt(query: String, context: String? = nil) -> String {
    """
    You are a helpful AI assistant integrated into macToSearch.
    Provide concise, relevant answers with proper markdown formatting.
    Use code blocks for technical content.
    
    \(context.map { "Context: \($0)\n" } ?? "")
    Query: \(query)
    """
}

// IMPLEMENT retry logic
func sendRequest<T>(
    _ request: Request<T>,
    maxRetries: Int = 3
) async throws -> T {
    for attempt in 0..<maxRetries {
        do {
            return try await performRequest(request)
        } catch {
            if attempt == maxRetries - 1 { throw error }
            await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
        }
    }
    throw RequestError.maxRetriesExceeded
}
```

## 🎬 Animation Guidelines

### Required Animations
```swift
// Entry animations for views
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .scale(scale: 0.95).combined(with: .opacity)
))

// State changes
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)

// Loading states
ProgressView()
    .scaleEffect(0.8)
    .opacity(isLoading ? 1 : 0)
    .animation(.easeInOut(duration: 0.2), value: isLoading)
```

## 🔄 Git Workflow

### Commit Message Format
```
<type>: <description>

[optional body]

Types:
- feat: New feature
- fix: Bug fix
- perf: Performance improvement
- refactor: Code refactoring
- docs: Documentation
- test: Tests
- style: Code style/formatting
```

### Branch Naming
- `feature/description-here`
- `fix/issue-description`
- `perf/optimization-description`

## 🚦 Pre-Release Checklist

Before EVERY release:
- [ ] All tests pass
- [ ] SwiftLint reports no violations
- [ ] No hardcoded API keys
- [ ] Memory leaks checked with Instruments
- [ ] Performance profiled for main flows
- [ ] Dark mode tested
- [ ] Multi-monitor tested
- [ ] Permissions flow tested on clean install
- [ ] Error states have user-friendly messages
- [ ] README is up to date

## 💡 Quick Reference

### Common Patterns
```swift
// Floating window setup
window.level = .floating
window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
window.backgroundColor = .clear
window.isOpaque = false
window.hasShadow = false

// Global hotkey registration
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    // Handle hotkey
}

// Screen capture with fallback
let screenshot = try await ScreenCaptureKit.capture() 
    ?? CGDisplayCreateImage(CGMainDisplayID())
    ?? fallbackCapture()
```

## 🔗 Important Links

- [ScreenCaptureKit Documentation](https://developer.apple.com/documentation/screencapturekit)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)
- [SwiftUI Layout System](https://developer.apple.com/documentation/swiftui/layout)
- [Gemini API Reference](https://ai.google.dev/docs)

## 📌 Critical Notes

1. **NEVER** use synchronous operations on the main thread
2. **ALWAYS** handle the case where screen recording permission is denied
3. **NEVER** assume OCR will succeed - always have fallback UI
4. **ALWAYS** test with both Light and Dark mode
5. **NEVER** block user interaction during network requests
6. **ALWAYS** provide visual feedback for every user action
7. **NEVER** use force unwrapping except in IBOutlets (which we don't use)
8. **ALWAYS** use semantic colors (e.g., `.primary`, not `.black`)

## ⚠️ Known Issues & Solutions

### Screen Capture Problem
**Issue**: Currently capturing only wallpaper without applications
**Status**: Under investigation - likely macOS permission or timing issue
**Workaround**: Ensure Screen Recording permission is granted in System Settings

### Solutions Attempted:
1. ✅ ESC key now properly closes overlay (OverlayWindow.swift)
2. ❌ Various capture methods (CGWindowList, CGDisplay, SCScreenshotManager)
3. ❌ Permission and timing adjustments

**Next Steps**:
- Debug window availability in SCShareableContent
- Try SCStream instead of screenshot API
- Check Console.app for WindowServer errors

---

**Remember**: This is a PREMIUM application. Every interaction should feel smooth, every animation deliberate, and every error handled gracefully. Think Apple-level polish with Google-level intelligence.