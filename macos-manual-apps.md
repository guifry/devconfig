# macOS Manual Apps

Apps that cannot be automatically installed (paid, App Store, or manual download).
Install these manually after running `devconfig switch`.

## Click2Minimize
- **Website**: https://click2minimize.com
- **Purchase**: https://idemfactor.gumroad.com/l/click2minimize
- **Price**: ~$6
- **Purpose**: Click Finder icon to open Bloom instead, minimize to app icon
- **Setup**:
  1. Download and install from website
  2. Open Click2Minimize > Settings
  3. Under "Other Settings", enable "Click Finder icon to open alternate app"
  4. Select Bloom as the alternate app
- **Config**: Automatically restored by devconfig if previously exported

---

# macOS Manual Config Steps

Apps installed automatically via devconfig (brew) but require manual config import/export.
The app is ready to use - only your personal settings (hotkeys, preferences) need manual import.

## Raycast
- **Website**: https://www.raycast.com
- **Docs**: https://manual.raycast.com/preferences
- **Installed via**: `brew install --cask raycast` (in Brewfile)
- **Config location**: Export via app → `.rayconfig` file
- **Why manual**: No CLI import available
- **Export config**:
  1. Open Raycast
  2. Cmd+, → Advanced → Export Preferences & Data
  3. Save to `~/projects/devconfig/macos/raycast.rayconfig`
- **Import config (new machine)**:
  1. Open Raycast
  2. Cmd+, → Advanced → Import Preferences & Data
  3. Select `~/projects/devconfig/macos/raycast.rayconfig`
