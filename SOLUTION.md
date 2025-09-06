# macToSearch - Screen Capture Solution

## Problem
The app was only capturing the wallpaper/background instead of all application windows when using Command+Shift+Space.

## Root Cause
1. **App Sandbox**: The app had sandbox enabled which was interfering with screen capture permissions
2. **Wrong API**: Using `SCScreenshotManager.captureImage` which wasn't reliable
3. **Permission Issues**: macOS wasn't recognizing the app as having the granted permissions

## Solution

### 1. Removed App Sandbox
**File: macToSearch.entitlements**
- Removed all sandbox-related keys
- The app now runs without sandbox restrictions (like QuickRecorder)

### 2. Switched to SCStream API
**File: AppDelegate.swift**
- Implemented `SCStreamDelegate` and `SCStreamOutput` protocols
- Used `SCStream` with delegate pattern instead of `SCScreenshotManager`
- Added proper frame capture through `stream(_ stream:didOutputSampleBuffer:of:)` callback

### 3. Key Changes Made

```swift
// Before (not working)
let screenshot = try await SCScreenshotManager.captureImage(
    contentFilter: filter,
    configuration: configuration
)

// After (working)
captureStream = SCStream(filter: filter, configuration: configuration, delegate: self)
try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
try await stream.startCapture()
// Wait for frame in delegate callback
```

### 4. Permission Handling
- Added proper error handling for `SCStreamError.userDeclined`
- Shows alert to open System Settings when permission is needed

## Testing Steps
1. Clean build: `xcodebuild -scheme macToSearch clean`
2. Remove derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/macToSearch-*`
3. Reset permissions: `tccutil reset ScreenCapture`
4. Build fresh: `xcodebuild -scheme macToSearch build`
5. Run app and grant Screen Recording permission

## Result
✅ App now captures ALL content on screen including:
- All application windows
- System UI elements
- Proper layering and transparency
- Full screen content exactly like Command+Shift+5

## Technical Details
- **No App Sandbox**: Allows full system access
- **SCStream API**: More reliable than SCScreenshotManager
- **Async/Await Pattern**: Proper handling of asynchronous capture
- **Delegate Pattern**: Receives frames directly from the stream

## Credits
Solution inspired by analyzing QuickRecorder implementation:
https://github.com/lihaoyun6/QuickRecorder