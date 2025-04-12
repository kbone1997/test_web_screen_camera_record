import 'dart:io';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(ScreenRecorderApp());
}

class ScreenRecorderApp extends StatelessWidget {
  const ScreenRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Screen Recorder Web',
      home: RecorderPage(),
    );
  }
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  _RecorderPageState createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  String selectedType = 'screen';
  String selectedAudio = 'mic';

  void startRecording() {
    if (kIsWeb) {
      if (selectedType == 'screen') {
        js.context.callMethod('startScreenRecording', [selectedAudio]);
      } else if (selectedType == 'camera') {
        bool withMic = selectedAudio == 'mic' || selectedAudio == 'both';
        js.context.callMethod('startCameraRecording', [withMic]);
      } else if (selectedType == 'both') {
        js.context.callMethod('startScreenAndCameraRecording', [selectedAudio]);
      }
    } else {
      if (Platform.isAndroid) {
      } else if (Platform.isIOS) {}
    }
  }

  void stopRecording() {
    js.context.callMethod('stopRecording');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Screen Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedType,
              items: ['screen', 'camera', 'both'].map((type) {
                return DropdownMenuItem(
                    value: type, child: Text(type.toUpperCase()));
              }).toList(),
              onChanged: (value) => setState(() => selectedType = value!),
            ),
            DropdownButton<String>(
              value: selectedAudio,
              items: ((selectedType == "camera")
                      ? [
                          'mic',
                        ]
                      : ['mic', 'system', 'both'])
                  .map((opt) {
                return DropdownMenuItem(
                    value: opt, child: Text("Audio: ${opt.toUpperCase()}"));
              }).toList(),
              onChanged: (value) => setState(() => selectedAudio = value!),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startRecording,
              child: Text('Start Recording'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: stopRecording,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Stop Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
