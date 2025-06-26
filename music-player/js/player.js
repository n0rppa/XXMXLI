function musicPlayer() {
    return {
        tracks: [],
        currentTrack: null,
        isPlaying: false,
        volume: 0.7,
        progress: 0,
        currentTime: 0,
        duration: 0,
        audioContext: null,
        analyser: null,
        sound: null,

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
            const canvas = this.$refs.visualizer;
            const ctx = canvas.getContext('2d');
            const bufferLength = this.analyser.frequencyBinCount;
            const dataArray = new Uint8Array(bufferLength);

            const draw = () => {
                requestAnimationFrame(draw);
                this.analyser.getByteFrequencyData(dataArray);
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                dataArray.forEach((value, index) => {
                    ctx.fillStyle = `rgb(${value}, 50, 50)`;
                    ctx.fillRect(index * 5, canvas.height - value, 4, value);
                });
            };

            draw();
        },

        playTrack(track) {
            // Implement track playback logic
        },

        togglePlay() {
            this.isPlaying ? this.pause() : this.play();
        },

        formatTime(seconds) {
            const minutes = Math.floor(seconds / 60);
            const remainingSeconds = Math.floor(seconds % 60);
            return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
        },
    };
}