import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(const SyntaxCounterApp());
}

class SyntaxCounterApp extends StatelessWidget {
  const SyntaxCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Counter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SyntaxCounterScreen(),
    );
  }
}

class SyntaxCounterScreen extends StatefulWidget {
  const SyntaxCounterScreen({super.key});

  @override
  State<SyntaxCounterScreen> createState() => _SyntaxCounterScreenState();
}

class _SyntaxCounterScreenState extends State<SyntaxCounterScreen> {
  bool _isListening = false;
  String _targetWord = "";
  int _count = 0;
  String _lastRecognized = "";

  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );
    setState(() {});
  }

  void _toggleListening() async {
  if (!_speechAvailable) {
    print("Speech recognition not available");
    return;
  }

  // ✅ Ask for microphone permission
  if (await Permission.microphone.request().isGranted) {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords != _lastRecognized) {
            setState(() {
              _lastRecognized = result.recognizedWords;
              _count += _countOccurrences(result.recognizedWords, _targetWord);
            });
          }
        },
        listenMode: stt.ListenMode.confirmation,
      );
      setState(() => _isListening = true);
    }
  } else {
    print("Microphone permission denied");
  }
}


  int _countOccurrences(String text, String word) {
    if (word.isEmpty) return 0;
    final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
    return pattern.allMatches(text).length;
  }

  void _clearCount() {
    setState(() {
      _count = 0;
      _lastRecognized = "";
    });
    print("Count cleared");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Counter'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Input field
            TextField(
              decoration: const InputDecoration(
                labelText: "Enter word to detect",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _targetWord = value);
                print("Target word: $_targetWord");
              },
            ),

            const SizedBox(height: 30),

            // Count display
            Text(
              "Count: $_count",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Last recognized text placeholder
            Text(
              "Last heard: $_lastRecognized",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleListening,
                  icon: Icon(_isListening ? Icons.pause : Icons.play_arrow),
                  label: Text(_isListening ? "Pause" : "Start"),
                ),
                ElevatedButton.icon(
                  onPressed: _clearCount,
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
