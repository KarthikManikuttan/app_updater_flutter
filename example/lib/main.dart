import 'package:flutter/material.dart';
import 'package:updater/updater.dart';

void main() {
  runApp(const ExampleApp());
}

/// A mock source that simulates an available update.
///
/// Real apps should use [StoreUpdateSource] or [JsonUpdateSource].
class MockUpdateSource implements UpdateSource {
  final bool available;
  final bool critical;

  const MockUpdateSource({this.available = true, this.critical = false});

  @override
  Future<UpdateInfo?> fetchUpdateInfo() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!available) return null;

    return UpdateInfo(
      currentVersion: Version(1, 0, 0),
      latestVersion: Version(1, 1, 0),
      updateUrl: 'https://flutter.dev',
      releaseNotes: "This is a simulated update from MockUpdateSource.\n\n"
          "- Added cool features\n"
          "- Fixed bugs\n"
          "- Improved performance",
      isCritical: critical,
    );
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Updater Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // 1. Wrap your home widget with UpdaterListener
      // This ensures MaterialLocalizations are available via context.
      home: UpdaterListener(
        // Using a Mock Source for demonstration.
        // In production, use StoreUpdateSource() (default).
        source: const MockUpdateSource(),

        // Configure the updater
        config: const UpdateConfig(
          checkInterval: Duration(seconds: 10), // Short interval for testing
          dialogStyle: UpgradeDialogStyle.adaptive,
          snoozeDuration: Duration(minutes: 1),
        ),

        onUpdateShown: () => debugPrint('Update dialog shown!'),
        onUpdateAccepted: () => debugPrint('User accepted update'),
        onUpdateIgnored: () => debugPrint('User snoozed update'),
        onError: (e) => debugPrint('Error checking for updates: $e'),

        child: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    FeaturesPage(),
    InlinePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Updater Features')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Features'),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_agenda),
            label: 'Inline Card',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Manual Check',
          ),
        ],
      ),
    );
  }
}

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Welcome! The app automatically checked for updates on startup '
              'using the UpdaterListener wrapper.\n\n'
              'If you dismissed it, wait 10 seconds (checkInterval) and restart/resume '
              'or use the Manual Check tab.',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Example: Critical Update Simulation
        FilledButton.tonal(
          onPressed: () {
            Updater.init(
              context: context,
              source: const MockUpdateSource(critical: true),
              config: const UpdateConfig(
                checkInterval: Duration.zero,
                snoozeDuration: Duration.zero,
                canPopScope: false, // Prevent back button
                showIgnore: false,
                showLater: false,
                dialogStyle: UpgradeDialogStyle.material,
              ),
            );
          },
          child: const Text('Simulate Critical Update (Material)'),
        ),

        const SizedBox(height: 8),

        // Example: iOS Style
        OutlinedButton(
          onPressed: () {
            Updater.init(
              context: context,
              source: const MockUpdateSource(),
              config: const UpdateConfig(
                checkInterval: Duration.zero,
                snoozeDuration: Duration.zero,
                dialogStyle: UpgradeDialogStyle.cupertino,
              ),
            );
          },
          child: const Text('Simulate Update (Cupertino Style)'),
        ),

        const SizedBox(height: 8),

        // Example: Styling
        ElevatedButton(
          onPressed: () {
            Updater.init(
              context: context,
              source: const MockUpdateSource(),
              config: const UpdateConfig(
                checkInterval: Duration.zero,
                snoozeDuration: Duration.zero,
                dialogStyle: UpgradeDialogStyle.adaptive,
                updateButtonTextStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                laterButtonTextStyle: TextStyle(color: Colors.grey),
                ignoreButtonTextStyle: TextStyle(color: Colors.red),
              ),
            );
          },
          child: const Text('Custom Button Styles'),
        ),

        const SizedBox(height: 8),

        // Example: Custom Language
        TextButton(
          onPressed: () {
            Updater.init(
              context: context,
              source: const MockUpdateSource(),
              config: const UpdateConfig(
                checkInterval: Duration.zero,
                snoozeDuration: Duration.zero,
                messages: UpdaterMessages(
                  title: "Mise à jour disponible",
                  body:
                      "Une nouvelle version {{latestVersion}} est disponible !",
                  buttonTitleUpdate: "Mettre à jour",
                  buttonTitleLater: "Plus tard",
                  buttonTitleIgnore: "Ignorer",
                ),
              ),
            );
          },
          child: const Text('Custom Localization (French)'),
        ),
      ],
    );
  }
}

class InlinePage extends StatelessWidget {
  const InlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'UpgradeCard Widget',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Embed update status directly in your UI:'),
          SizedBox(height: 16),

          // Basic Usage
          UpgradeCard(
            source: MockUpdateSource(),
            config: UpdateConfig(dialogStyle: UpgradeDialogStyle.adaptive),
          ),

          SizedBox(height: 16),
          Text('With Custom Styling:'),
          SizedBox(height: 8),

          // Styled Usage
          UpgradeCard(
            source: MockUpdateSource(critical: true),
            config: UpdateConfig(
              dialogStyle: UpgradeDialogStyle.cupertino, // Force iOS style
              showIgnore: false,
              showLater: false,
              updateButtonTextStyle: TextStyle(fontWeight: FontWeight.w900),
            ),
            margin: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Manual Check'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Manual check logic
              Updater.init(
                context: context,
                source: const MockUpdateSource(),
                config: const UpdateConfig(
                  // Override snooze to force check
                  checkInterval: Duration.zero,
                  snoozeDuration: Duration.zero,
                ),
              );
            },
            child: const Text('Check for Update Now'),
          ),
        ],
      ),
    );
  }
}
