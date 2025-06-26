function musicPlayer() {
    return {
        tracks: [],
        currentTrack: null,
        audioContext: null,
        analyser: null,
        isPlaying: false,
        audio: null,
        async init() {
            await this.loadTracks();
            this.setupAudioContext();
            this.setupVisualizer();
        },
        async loadTracks() {
            try {
                const response = await fetch('../assets/audio/filelist.json');
                this.tracks = await response.json();
            } catch (error) {
                console.error('Failed to load tracks:', error);
                this.tracks = [
                    { id: "default-1", title: "Sample Track", artist: "Unknown Artist", path: "../assets/audio/sample.mp3" }
                ];
            }
        },
        setupAudioContext() {
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            this.audioContext = new AudioContext();
            this.analyser = this.audioContext.createAnalyser();
            this.analyser.fftSize = 256;
        },
        setupVisualizer() {
            if (this.analyser && document.getElementById('visualizer')) {
                setupVisualizer(this.analyser, document.getElementById('visualizer'));
            }
        }
    };
}