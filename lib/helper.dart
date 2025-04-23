part of recorder;

Future<void> preparePreview(String audioOption, String selectedType) async {
  try {
    html.MediaStream? mediaStream;

    if (selectedType == 'screen') {
      final screenOptions = {
        'video': true,
        'audio': audioOption != 'mic', // system or both
      };

      mediaStream = await js_util.promiseToFuture<html.MediaStream>(
        js_util.callMethod(
          html.window.navigator.mediaDevices!,
          'getDisplayMedia',
          [screenOptions],
        ),
      );
    } else if (selectedType == 'camera') {
      final constraints = {
        'video': true,
        'audio': true,
      };
      print('Requesting getUserMedia with constraints: $constraints');

      final jsConstraints = js_util.jsify(constraints);

      mediaStream = await js_util.promiseToFuture<html.MediaStream>(
        js_util.callMethod(
          html.window.navigator.mediaDevices!,
          'getUserMedia',
          [jsConstraints],
        ),
      );
    } else if (selectedType == 'both') {
      final screenStream = await js_util.promiseToFuture<html.MediaStream>(
        js_util.callMethod(
          html.window.navigator.mediaDevices!,
          'getDisplayMedia',
          [
            {
              'video': true,
              'audio': audioOption == 'system' || audioOption == 'both',
            }
          ],
        ),
      );

      final constraints = {
        'video': true,
        'audio': true,
      };
      print('Requesting getUserMedia with constraints: $constraints');

      final jsConstraints = js_util.jsify(constraints);

      final cameraStream = await js_util.promiseToFuture<html.MediaStream>(
        js_util.callMethod(
          html.window.navigator.mediaDevices!,
          'getUserMedia',
          [jsConstraints],
        ),
      );

      // For simplicity, just show screen in preview for now
      //need to check if this works or not
      mediaStream = screenStream;
      cameraVideo?.srcObject = cameraStream;
    }

    if (previewVideo != null && mediaStream != null) {
      previewVideo!.srcObject = mediaStream;
      activeStream = mediaStream;
    }
  } catch (e) {
    print('Error accessing media: $e');
  }
}

void startNativeRecording(html.MediaStream stream) {
  print("Recording requested");
  recordedBlobs.clear();

  // Create the MediaRecorder via JS interop
  mediaRecorder = js_util.callConstructor(
    js_util.getProperty(html.window, 'MediaRecorder'),
    [stream],
  ) as html.MediaRecorder;

  // Attach the `ondataavailable` event via allowInterop
  js_util.setProperty(
    mediaRecorder!,
    'ondataavailable',
    js_util.allowInterop((event) {
      final blob = js_util.getProperty(event, 'data') as html.Blob;
      if (blob.size > 0) {
        recordedBlobs.add(blob);
      }
    }),
  );

  // Attach the `onstop` event via allowInterop
  js_util.setProperty(
    mediaRecorder!,
    'onstop',
    js_util.allowInterop((event) {
      final fullBlob = html.Blob(recordedBlobs, 'video/webm');
      final url = html.Url.createObjectUrlFromBlob(fullBlob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'recording_${DateTime.now().millisecondsSinceEpoch}.webm')
        ..click();

      html.Url.revokeObjectUrl(url);
    }),
  );

  mediaRecorder!.start();
}

void stopNativeRecording() {
  mediaRecorder?.stop();
}
