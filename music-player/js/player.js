function musicPlayer() {
    return {
        tracks: [],
        currentTrack: null,
        audioContext: null,
        analyser: null,
        isPlaying: false,
        audio: null,
        currentIndex: 0,
        visualizerAnimation: null,
        async init() {
            await this.loadTracks();
            this.setupAudioContext();
            this.setupVisualizer();
            this.loadTrack(0);
        },
        async loadTracks() {
            try {
                const response = await fetch('../assets/audio/filelist.json');
                this.tracks = await response.json();
            } catch (error) {
                console.error('%c[Error] Failed to load tracks:', 'color: #ff00cc; font-weight: bold;', error);
                this.tracks = [
                    { id: "default-1", title: "Sample Track", artist: "Unknown Artist", path: "../assets/audio/sample.mp3" }
                ];
            }
        },
        setupAudioContext() {
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            this.audioContext = new AudioContext();
            this.analyser = this.audioContext.createAnalyser();
            this.analyser.fftSize = 512;
        },
        setupVisualizer() {
            const canvas = document.getElementById('visualizer');
            if (this.analyser && canvas) {
                const ctx = canvas.getContext('2d');
                const bufferLength = this.analyser.frequencyBinCount;
                const dataArray = new Uint8Array(bufferLength);

                const draw = () => {
                    this.visualizerAnimation = requestAnimationFrame(draw);
                    this.analyser.getByteFrequencyData(dataArray);
                    ctx.clearRect(0, 0, canvas.width, canvas.height);

                    // Futuristic neon bars
                    const barWidth = (canvas.width / bufferLength) * 2.5;
                    let x = 0;

                    for (let i = 0; i < bufferLength; i++) {
                        let barHeight = dataArray[i] * 1.5;
                        ctx.save();
                        ctx.shadowColor = `hsl(${i * 2}, 90%, 60%)`;
                        ctx.shadowBlur = 18;
                        ctx.fillStyle = `hsl(${i * 2}, 100%, 55%)`;
                        ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight);
                        ctx.restore();
                        x += barWidth + 1.5;
                    }
                };
                draw();
            }
        },
        loadTrack(index) {
            if (this.audio) {
                this.audio.pause();
            }
            this.currentIndex = index;
            this.currentTrack = this.tracks[index];
            this.audio = new Audio(this.currentTrack.path);

            // Connect to analyser node for visualization
            const source = this.audioContext.createMediaElementSource(this.audio);
            source.connect(this.analyser);
            this.analyser.connect(this.audioContext.destination);

            this.audio.onended = () => this.nextTrack();
        },
        play() {
            if (!this.audio) return;
            this.audio.play();
            this.isPlaying = true;
            document.body.classList.add('playing');
        },
        pause() {
            if (!this.audio) return;
            this.audio.pause();
            this.isPlaying = false;
            document.body.classList.remove('playing');
        },
        togglePlay() {
            this.isPlaying ? this.pause() : this.play();
        },
        nextTrack() {
            let next = (this.currentIndex + 1) % this.tracks.length;
            this.loadTrack(next);
            if (this.isPlaying) this.play();
        },
        prevTrack() {
            let prev = (this.currentIndex - 1 + this.tracks.length) % this.tracks.length;
            this.loadTrack(prev);
            if (this.isPlaying) this.play();
        },
        setVolume(vol) {
            if (this.audio) this.audio.volume = vol;
        }
    };
}