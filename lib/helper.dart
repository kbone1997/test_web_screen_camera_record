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

void startNativeRecording(html.MediaStream stream, String selectedType) {
  print("Recording requested");
  recordedBlobs.clear();

  if (selectedType == 'both') {
    // Let this function handle canvas drawing + recording setup
    mergeAndRecordVideos(previewVideo!, cameraVideo!);
    return; // prevent continuing to the native MediaRecorder block below
  }

  // For 'screen' or 'camera' mode
  mediaRecorder = js_util.callConstructor(
    js_util.getProperty(html.window, 'MediaRecorder'),
    [stream],
  ) as html.MediaRecorder;

  js_util.setProperty(
    mediaRecorder!,
    'ondataavailable',
    js_util.allowInterop((event) {
      final blob = js_util.getProperty(event, 'data') as html.Blob;
      if (blob.size > 0) recordedBlobs.add(blob);
    }),
  );

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

void mergeAndRecordVideos(
    html.VideoElement screenVideo, html.VideoElement cameraVideo) {
  print("inside merger 2 videos");
  final canvas = html.CanvasElement(
    width: screenVideo.videoWidth,
    height: screenVideo.videoHeight,
  );
  final ctx = canvas.context2D;

  final mergedStream = canvas.captureStream();

  // Set up MediaRecorder with merged stream
  recordedBlobs.clear();
  mediaRecorder = js_util.callConstructor(
    js_util.getProperty(html.window, 'MediaRecorder'),
    [mergedStream],
  ) as html.MediaRecorder;

  // Set events
  js_util.setProperty(mediaRecorder!, 'ondataavailable',
      js_util.allowInterop((event) {
    final blob = js_util.getProperty(event, 'data') as html.Blob;
    if (blob.size > 0) recordedBlobs.add(blob);
  }));

  js_util.setProperty(mediaRecorder!, 'onstop', js_util.allowInterop((event) {
    final fullBlob = html.Blob(recordedBlobs, 'video/webm');
    final url = html.Url.createObjectUrlFromBlob(fullBlob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'mergeRecording_${DateTime.now().millisecondsSinceEpoch}.webm')
      ..click();

    html.Url.revokeObjectUrl(url);
  }));

  // Draw videos to canvas
  void draw() {
    // Clear previous frame
    ctx.clearRect(0, 0, canvas.width!, canvas.height!);

    // Draw the screen full-size
    ctx.drawImage(screenVideo, 0, 0);

    // Compute size and position for camera overlay
    final double camW = canvas.width! * 0.25; // 25% of screen width
    final double camH = camW *
        (cameraVideo.videoHeight /
            cameraVideo.videoWidth); // Maintain aspect ratio
    final double camX = canvas.width! - camW - 16; // 16px padding from right
    final double camY = canvas.height! - camH - 16; // 16px padding from bottom

    // Draw camera video scaled and positioned
    ctx.drawImageScaled(cameraVideo, camX, camY, camW, camH);

    // Loop
    html.window.requestAnimationFrame((_) => draw());
  }

  draw();
  mediaRecorder!.start();
}

void stopNativeRecording() {
  mediaRecorder?.stop();
}
