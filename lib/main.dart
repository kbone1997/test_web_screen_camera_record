library recorder;

import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui; // For platform view registry
import 'dart:html' as html;
import 'dart:js_util' as js_util;

part 'helper.dart'; // Declare the part

html.VideoElement? previewVideo;
html.VideoElement? cameraVideo;
html.MediaRecorder? mediaRecorder;
html.MediaStream? activeStream;
List<html.Blob> recordedBlobs = [];

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

  @override
  void initState() {
    super.initState();

    previewVideo = html.VideoElement()
      ..id = 'previewVideo'
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '8px'
      ..style.objectFit = 'cover'
      ..setAttribute('playsinline', 'true');

    cameraVideo = html.VideoElement()
      ..id = 'previewVideo'
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '8px'
      ..style.objectFit = 'cover'
      ..setAttribute('playsinline', 'true');

    // Register the video element to the platform view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'preview-video',
      (int viewId) => previewVideo!,
    );
    // For camera preview
    ui.platformViewRegistry.registerViewFactory(
      'camera-preview',
      (int viewId) => cameraVideo!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Screen Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(8)),
                height: (MediaQuery.of(context).size.width * 0.4) * 9 / 16,
                width: MediaQuery.of(context).size.width * 0.4,
                child: HtmlElementView(viewType: 'preview-video'),
              ),
              if (selectedType == 'both') ...[
                SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.black),
                      borderRadius: BorderRadius.circular(8)),
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: (MediaQuery.of(context).size.width * 0.4) * 9 / 16,
                  child: HtmlElementView(viewType: 'camera-preview'),
                ),
              ],
            ]),
            DropdownButton<String>(
              value: selectedType,
              items: ['screen', 'camera', 'both'].map((type) {
                return DropdownMenuItem(
                    value: type, child: Text(type.toUpperCase()));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
                preparePreview(selectedAudio,
                    selectedType); // Refresh preview on type change
              },
            ),
            DropdownButton<String>(
              value: selectedAudio,
              items: ((selectedType == "camera")
                      ? ['mic']
                      : ['mic', 'system', 'both'])
                  .map((opt) {
                return DropdownMenuItem(
                    value: opt, child: Text("Audio: ${opt.toUpperCase()}"));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedAudio = value!);
                preparePreview(value!,
                    selectedType); // Refresh preview on audio option change
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (activeStream != null) {
                  startNativeRecording(activeStream!, selectedType);
                }
              },
              child: Text('Start Recording'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: stopNativeRecording,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Stop Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
