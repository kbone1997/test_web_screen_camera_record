let mediaRecorder;
let recordedChunks = [];

async function startScreenRecording(audioOption)
{
    let screenStream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: audioOption !== 'mic', // system audio if not mic-only
    });

    let finalStream;

    if (audioOption === 'mic')
    {
        const micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        finalStream = new MediaStream([
            screenStream.getVideoTracks()[0],
            ...micStream.getAudioTracks()
        ]);
    } else if (audioOption === 'both')
    {
        const micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const audioContext = new AudioContext();

        const systemSource = audioContext.createMediaStreamSource(screenStream);
        const micSource = audioContext.createMediaStreamSource(micStream);
        const dest = audioContext.createMediaStreamDestination();

        systemSource.connect(dest);
        micSource.connect(dest);

        finalStream = new MediaStream([
            screenStream.getVideoTracks()[0],
            ...dest.stream.getAudioTracks()
        ]);
    } else
    {
        finalStream = screenStream; // system audio only
    }

    startRecorder(finalStream, "screen_recording.webm");
}

async function startCameraRecording(withMic)
{
    const camStream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: withMic
    });

    startRecorder(camStream, "camera_recording.webm");
}

async function startScreenAndCameraRecording(audioOption)
{
    const screenStream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: audioOption !== 'mic' // include system audio if needed
    });

    const camStream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: audioOption !== 'system' // include mic audio if needed
    });

    const screenVideoTrack = screenStream.getVideoTracks()[0];
    const camVideoTrack = camStream.getVideoTracks()[0];

    // Create canvas to merge both videos
    const canvas = document.createElement("canvas");
    const screenVideo = document.createElement("video");
    const camVideo = document.createElement("video");

    screenVideo.srcObject = new MediaStream([screenVideoTrack]);
    camVideo.srcObject = new MediaStream([camVideoTrack]);
    screenVideo.play();
    camVideo.play();

    await Promise.all([
        new Promise((res) => screenVideo.onloadedmetadata = res),
        new Promise((res) => camVideo.onloadedmetadata = res)
    ]);

    canvas.width = screenVideo.videoWidth;
    canvas.height = screenVideo.videoHeight;

    const ctx = canvas.getContext("2d");

    function drawFrame()
    {
        ctx.drawImage(screenVideo, 0, 0, canvas.width, canvas.height);

        const camWidth = canvas.width / 4;
        const camHeight = canvas.height / 4;
        ctx.drawImage(camVideo, canvas.width - camWidth - 10, canvas.height - camHeight - 10, camWidth, camHeight);

        requestAnimationFrame(drawFrame);
    }

    drawFrame();

    const canvasStream = canvas.captureStream(30); // 30fps

    // Mix audio
    const audioContext = new AudioContext();
    const dest = audioContext.createMediaStreamDestination();

    if (audioOption !== 'system')
    {
        const micSource = audioContext.createMediaStreamSource(camStream);
        micSource.connect(dest);
    }

    if (audioOption !== 'mic')
    {
        const systemSource = audioContext.createMediaStreamSource(screenStream);
        systemSource.connect(dest);
    }

    const finalStream = new MediaStream([
        canvasStream.getVideoTracks()[0],
        ...dest.stream.getAudioTracks()
    ]);

    startRecorder(finalStream, "screen_and_camera_recording.webm");
}

function startRecorder(stream, filename)
{
    recordedChunks = [];
    mediaRecorder = new MediaRecorder(stream);

    mediaRecorder.ondataavailable = function (event)
    {
        if (event.data.size > 0)
        {
            recordedChunks.push(event.data);
        }
    };

    mediaRecorder.onstop = function ()
    {
        const blob = new Blob(recordedChunks, { type: "video/webm" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
    };

    mediaRecorder.start();
}

function stopRecording()
{
    if (mediaRecorder && mediaRecorder.state !== "inactive")
    {
        mediaRecorder.stop();
    }
}
