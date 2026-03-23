import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/chat_screen.dart';
import 'screens/embeddings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tools_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genkit Flutter Gemma',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _appState = AppState();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _appState.initialize();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  void _goToSettings() {
    setState(() => _currentIndex = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genkit Flutter Gemma'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ChatScreen(appState: _appState, onGoToSettings: _goToSettings),
          EmbeddingsScreen(appState: _appState, onGoToSettings: _goToSettings),
          ToolsScreen(appState: _appState, onGoToSettings: _goToSettings),
          SettingsScreen(appState: _appState),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.data_array), label: 'Embeddings'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
