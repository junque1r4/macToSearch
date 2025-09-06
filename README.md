# macToSearch - Circle to Search for Mac

AI-powered visual search tool for macOS - Capture, Extract, Search with Gemini AI

## Features

- **Screen Capture with Selection** - Click and drag to select any area on screen (rectangle or circle)
- **OCR Text Extraction** - Automatic text extraction from images using Vision framework
- **Clipboard Monitoring** - Automatically detect and search clipboard content
- **Global Hotkey** - Press ⌘⇧Space anywhere to trigger capture
- **Gemini AI Integration** - Powered by Google's Gemini Flash model for fast responses
- **Search History** - Keep track of all your searches with SwiftData

## Setup

### 1. Get Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Generate a new API key
4. Copy the key

### 2. Configure the App

1. Open macToSearch
2. Go to Settings (⌘,)
3. Navigate to the AI tab
4. Paste your Gemini API key
5. Click Save

### 3. Grant Permissions

The app requires the following permissions:
- **Screen Recording** - To capture screen content
- **Accessibility** - For global hotkeys

When prompted, grant these permissions in System Settings > Privacy & Security

## Usage

### Quick Capture
- Press **⌘⇧Space** anywhere to start screen capture
- Click and drag to select area
- Release to capture and search

### Clipboard Search
- Copy any text or image
- Click "Search Clipboard" in the app
- Get instant AI-powered results

### Text Search
- Type your query in the search bar
- Press Enter or click Search
- Get responses from Gemini AI

## Models & Pricing

### Free Tier
- 1,500 requests per day
- No cost for input/output tokens
- Perfect for personal use

### Available Models
- **gemini-1.5-flash** (Recommended) - Fast and cost-efficient
- **gemini-1.5-flash-8b** - Smaller model for simple tasks
- **gemini-2.0-flash** - Latest features with thinking capabilities
- **gemini-1.5-pro** - More powerful but slower

## Technical Details

- Built with **Swift** and **SwiftUI**
- Uses **ScreenCaptureKit** for screen capture
- **Vision framework** for OCR (99.7% accuracy)
- **SwiftData** for search history
- Native **Carbon API** for global hotkeys

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Internet connection for AI features

## Privacy

- All processing happens locally except AI queries
- No data is stored on external servers
- API keys are stored securely in UserDefaults
- Screen recordings require explicit permission

## Known Issues

- macOS Sequoia requires monthly re-approval for screen recording
- Global hotkeys don't work in sandboxed Mac App Store version
- Some apps may block screen capture for security

## Building from Source

1. Clone the repository
2. Open `macToSearch.xcodeproj` in Xcode
3. Build and run (⌘R)

## License

MIT License - See LICENSE file for details