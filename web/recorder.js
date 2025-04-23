let mediaRecorder;
let recordedChunks = [];

function startScreenRecording(audioOption)
{
    navigator.mediaDevices.getDisplayMedia({ video: true, audio: audioOption !== 'mic' }).then(screenStream =>
    {
        let tracks = [...screenStream.getTracks()];

        if (audioOption === 'mic' || audioOption === 'both')
        {
            navigator.mediaDevices.getUserMedia({ audio: true }).then(micStream =>
            {
                micStream.getAudioTracks().forEach(track => screenStream.addTrack(track));
                beginRecording(screenStream);
            });
        } else
        {
            beginRecording(screenStream);
        }
    });
}

function startCameraRecording(withMic)
{
    navigator.mediaDevices.getUserMedia({ video: true, audio: withMic }).then(stream =>
    {
        beginRecording(stream);
    });
}

function startScreenAndCameraRecording(audioOption)
{
    Promise.all([
        navigator.mediaDevices.getDisplayMedia({ video: true, audio: audioOption === 'system' || audioOption === 'both' }),
        navigator.mediaDevices.getUserMedia({ video: true, audio: audioOption === 'mic' || audioOption === 'both' })
    ]).then(([screenStream, cameraStream]) =>
    {
        // Merge tracks
        let combinedStream = new MediaStream([
            ...screenStream.getVideoTracks(),
            ...screenStream.getAudioTracks(),
            ...cameraStream.getAudioTracks(),
        ]);
        beginRecording(combinedStream);
    });
}

function beginRecording(stream)
{
    recordedChunks = [];
    mediaRecorder = new MediaRecorder(stream);
    mediaRecorder.ondataavailable = function (e)
    {
        if (e.data.size > 0) recordedChunks.push(e.data);
    };
    mediaRecorder.onstop = function ()
    {
        const blob = new Blob(recordedChunks, { type: 'video/webm' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'recording.webm';
        a.click();
        URL.revokeObjectURL(url);
    };
    mediaRecorder.start();
}

function stopRecording()
{
    if (mediaRecorder)
    {
        mediaRecorder.stop();
    }
}
