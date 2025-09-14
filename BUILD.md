# Building macToSearch

This guide explains how to build macToSearch from source and create distribution packages.

## Prerequisites

- **macOS 14.0 (Sonoma)** or later
- **Xcode 15.0** or later
- **Command Line Tools** installed
- **Git** for version control

## Quick Start

### Using Make (Easiest)

```bash
# Build for development
make build

# Build release version
make release

# Create DMG installer
make dmg

# Build and run immediately
make run

# Install to /Applications
make install
```

### Manual Build

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/macToSearch.git
cd macToSearch
```

#### 2. Quick Build (Development)
```bash
./Scripts/quick-build.sh
```

#### 3. Full Release Build with DMG
```bash
./Scripts/build.sh
```

## Build Options

### Development Build
Fast build for testing, includes debug symbols:
```bash
make build
# or
./Scripts/quick-build.sh debug
```

### Release Build
Optimized build for distribution:
```bash
make release
# or
./Scripts/quick-build.sh
```

### DMG Creation
Creates a distributable DMG installer:
```bash
make dmg
# or
./Scripts/build.sh
```

## Build Output

All build artifacts are placed in the `build/` directory:

- `build/macToSearch.app` - The application bundle
- `build/macToSearch-v{version}.dmg` - DMG installer (when using build.sh)
- `build/Export/` - Exported app from archive

## Automated Builds

### GitHub Actions

The project includes GitHub Actions workflow for automated builds:

1. **Automatic Release Builds**: Triggered when you push a tag starting with 'v'
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Manual Builds**: Trigger from GitHub Actions tab in the repository

### Release Process

1. Update version in Info.plist
2. Commit changes
3. Create and push tag:
   ```bash
   make tag  # Interactive version prompt
   # or manually:
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```
4. GitHub Actions will automatically:
   - Build the app
   - Create DMG and ZIP
   - Create GitHub Release
   - Upload artifacts

## Troubleshooting

### Build Failures

1. **Clean build artifacts**:
   ```bash
   make clean
   ```

2. **Reset Xcode derived data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/
   ```

3. **Check Xcode version**:
   ```bash
   xcodebuild -version
   ```

### Code Signing Issues

The build scripts use automatic signing. If you encounter issues:

1. Open project in Xcode
2. Select the project in navigator
3. Go to "Signing & Capabilities"
4. Ensure "Automatically manage signing" is checked
5. Select your development team (or None for local builds)

### DMG Creation Issues

If `hdiutil` fails:

1. Ensure you have enough disk space
2. Try with sudo (not recommended for CI):
   ```bash
   sudo hdiutil create ...
   ```

## Distribution

### For End Users

Users can install macToSearch via:

1. **DMG (Recommended)**:
   - Download the `.dmg` file
   - Open and drag to Applications
   - Launch from Applications

2. **ZIP Archive**:
   - Download the `.zip` file
   - Extract the archive
   - Move `macToSearch.app` to Applications

3. **Direct App Bundle**:
   - Download `macToSearch.app`
   - Move to Applications
   - Right-click and select "Open" on first launch

### Security Notice

Since the app is not notarized by Apple:
- Users may see a security warning on first launch
- They need to right-click and select "Open"
- Or go to System Settings > Privacy & Security to allow

## Build Customization

### Modify Build Settings

Edit `Scripts/build.sh` to customize:
- Build configuration
- Export options
- DMG appearance
- Version numbering

### Add Build Phases

In Xcode:
1. Select project
2. Go to Build Phases
3. Add run scripts for custom actions

## Testing

Run the test suite:
```bash
make test
```

Or with Xcode:
```bash
xcodebuild test \
  -project macToSearch.xcodeproj \
  -scheme macToSearch \
  -destination 'platform=macOS'
```

## Contributing

When contributing:
1. Ensure all tests pass
2. Build successfully completes
3. DMG can be created
4. App runs on clean macOS install

## Support

For build issues, please:
1. Check this guide first
2. Search existing GitHub issues
3. Create new issue with:
   - macOS version
   - Xcode version
   - Build output/errors
   - Steps to reproduce