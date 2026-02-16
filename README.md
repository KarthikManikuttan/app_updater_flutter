# Flutter Updater

A robust, modular, and customizable update checker for Flutter applications.
Supports Android (Google Play) and iOS (App Store) with advanced scraping, native UI integration, and V3 localization.

## Features 🚀

- **Cross-Platform**: Works on Android and iOS.
- **Native Android Support**: Leverage Google Play's **In-App Update API** (Immediate & Flexible flows).
- **Advanced Scraping**:
  - Automatically scrapes Version & Release Notes from the Play Store even if the API fails (e.g., debug builds, side-loaded apps).
  - Uses smart fallback strategies (JSON-LD, Script Regex, Mobile UA) to ensure reliability.
- **Modular Data Sources**:
  - App Store / Play Store (Default)
  - Custom JSON Endpoint (Private/Enterprise apps)
- **V3 Localization**: Built-in support for 30+ languages via `UpdaterMessages`.
- **Smart Logic**:
  - Semantic Versioning support (`1.0.0` vs `1.0.0-beta`).
  - **Snoozing**: Built-in "Update Later" logic with configurable timeouts.
  - **Lifecycle Aware**: Re-checks when app resumes (if not snoozed).
- **Customizable UI**:
  - **Adaptive**: Automatically uses Material on Android and Cupertino on iOS.
  - **UpgradeCard**: Ready-to-use widget for inline updates (e.g., Settings screen).
  - **Custom Builders**: Completely replace the UI with your own Widget/BottomSheet.
  - **PopScope Control**: Fine-grained control over back-button behavior (`canPopScope`, `onPopInvoked`).
  - **Styling**: Configure text styles for all action buttons.

## Usage 🛠️

### 1. Basic Usage (Declarative) - Recommended

Wrap your `MaterialApp` (or any part of your widget tree) with **`UpdaterListener`**. This handles lifecycle events automatically.

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UpdaterListener(
      config: UpdateConfig(
        checkInterval: Duration(days: 1), // Check at most once per day
        snoozeDuration: Duration(hours: 6), // "Later" snoozes for 6 hours
      ),
      onUpdateShown: () => print("Update dialog shown!"),
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}
```

### 2. Manual Usage (Imperative)

Call `Updater.init` in `initState`.

```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    Updater.init(
      context: context,
      config: UpdateConfig(
        dialogStyle: UpgradeDialogStyle.adaptive, // Default
      ),
    );
  }
}
```

### 3. Native Android Updates

Use Google Play's native blocking or flexible update screens.

**Immediate (Blocking):**
```dart
UpdaterListener(
  config: UpdateConfig(
    useAndroidNativeImmediateUpdate: true,
  ),
  child: ...
);
```

**Flexible (Background Download):**
```dart
UpdaterListener(
  config: UpdateConfig(
    useAndroidNativeFlexibleUpdate: true,
  ),
  child: ...
);
```

### 4. Localization (V3) 🌍

The package automatically detects the system locale. You can also force a language or customize messages.

```dart
UpdateConfig(
  languageCode: 'es', // Force Spanish
  // OR Custom Messages
  messages: UpdaterMessages(
    title: "Nueva Versión Disponible",
    body: "¡Actualiza ahora para obtener las últimas funciones!",
    buttonTitleUpdate: "Actualizar",
  ),
)
```

### 5. Advanced UI Customization 🎨

**Action Button Styles:**

You can customize the text styles of the "Update", "Later", and "Ignore" buttons.

```dart
UpdateConfig(
  updateButtonTextStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
  laterButtonTextStyle: TextStyle(color: Colors.grey),
  ignoreButtonTextStyle: TextStyle(color: Colors.red),
)
```

**Back Button Control (PopScope):**

Control whether users can dismiss the update dialog via the back button.

```dart
UpdateConfig(
  // Force user to update? Block back button.
  canPopScope: false, 
  
  // Callback when back button is pressed
  onPopInvoked: (didPop) {
    if (!didPop) print("User tried to escape the update!");
  },
)
```

**Fully Custom UI (Bottom Sheet):**

```dart
Updater.init(
  context: context,
  builder: (context, info, onUpdate, onLater) {
    return ModalBottomSheet(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Update Available: ${info.latestVersion}"),
            Text(info.releaseNotes ?? "Bug fixes and improvements."),
            ElevatedButton(onPressed: onUpdate, child: Text("Update Now")),
            TextButton(onPressed: onLater, child: Text("Not Now")),
          ],
        ),
      ),
    );
  },
);
```

### 6. Inline UI (UpgradeCard)

Use the `UpgradeCard` widget to show update status inside your app (e.g., in Settings).
It automatically inherits the `UpdateConfig` styling references.

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Basic Usage - uses default config
          UpgradeCard(),

          // Advanced Usage
          UpgradeCard(
             config: UpdateConfig(
                snoozeDuration: Duration(minutes: 5),
                dialogStyle: UpgradeDialogStyle.cupertino,
                updateButtonTextStyle: TextStyle(fontWeight: FontWeight.bold),
             ),
             // Completely replace actions
             dialogActionsBuilder: (context, info, onUpdate, onLater) {
                return [
                   IconButton(icon: Icon(Icons.close), onPressed: onLater),
                   ElevatedButton(onPressed: onUpdate, child: Text("Upgrade")),
                ];
             },
          ),
        ],
      ),
    );
  }
}
```

### 7. Custom JSON Source (Enterprise/Private Apps) 🏢
 
If your app is not on the store (or you want full control), use a custom JSON endpoint.
 
```dart
UpdaterListener(
  source: JsonUpdateSource(
    url: 'https://my-company.com/app/update.json',
    // Optional headers (auth, etc)
    headers: {'Authorization': 'Bearer ...'}, 
  ),
  child: MyApp(),
)
```
 
**JSON Format:**
The endpoint must return:
```json
{
  "latestVersion": "1.2.3",
  "url": "https://my-company.com/app/download.apk",
  "releaseNotes": "Fixes critical bugs.",
  "critical": true
}
```
 
## Debugging 🐞

**"App not owned" & Debugging in Emulator:**
When running debug builds, the Play Store API often fails (`App not owned`).

The `Updater` handles this gracefully:
1.  **Scraper Fallback:** It attempts to scrape the *real* store page for version/notes.
2.  **Debug Override:** Use `debugAlwaysShow: true` to force the dialog to appear.
    *   **Safe**: Only works in `kDebugMode` (ignored in Release).
    *   **Smart**: Shows the scraped version if the native API fails.

```dart
UpdateConfig(
  debugAlwaysShow: true, // Only triggers in kDebugMode
)
```

## Configuration Reference

| Property | Default | Description |
| :--- | :--- | :--- |
| `checkInterval` | `null` | Frequency of checks. `null` = always check. |
| `snoozeDuration` | `1 day` | Timeout after "Later" is clicked. |
| `dialogStyle` | `Adaptive` | Visual style (`material`, `cupertino`, or `adaptive`). Adaptive auto-selects based on platform. |
| `languageCode` | `null` | Override system language ('en', 'es', etc). |
| `canPopScope` | `null` | Allow/Block back button. Default: `false` for Critical. |
| `onPopInvoked` | `null` | Callback for back button attempts. |
| `debugAlwaysShow` | `false` | Force update prompt in Debug Mode. |
| `useAndroidNativeImmediateUpdate` | `false` | Use blocking native UI (Android). |
| `useAndroidNativeFlexibleUpdate` | `false` | Use background native UI (Android). |
| `updateButtonTextStyle` | `null` | Custom text style for "Update" button. |
| `laterButtonTextStyle` | `null` | Custom text style for "Later" button. |
| `ignoreButtonTextStyle` | `null` | Custom text style for "Ignore" button. |
