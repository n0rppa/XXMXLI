// Helper: Generate title from filename
function niceTrackTitleFromPath(path) {
    let filename = path.split('/').pop().replace(/\.[^/.]+$/, "");
    return filename.replace(/[-_]/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

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
            this.updateUI();
            this.setupControls();
            this.renderPlaylist();
        },

        async loadTracks() {
            try {
                const response = await fetch('assets/audio/filelist.json');
                let tracks = await response.json();
                this.tracks = tracks.map(track => ({
                    ...track,
                    title: track.title || niceTrackTitleFromPath(track.path),
                    artist: track.artist || 'Unknown Artist'
                }));
            } catch (error) {
                console.error('%c[Error] Failed to load tracks:', 'color: #ff00cc; font-weight: bold;', error);
                this.tracks = [
                    { id: "default-1", title: "Sample Track", artist: "Unknown Artist", path: "assets/audio/sample.mp3" }
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
            this.updateUI();
            this.highlightActiveTrack();
        },

        play() {
            if (!this.audio) return;
            this.audio.play();
            this.isPlaying = true;
            document.getElementById('play-btn').innerHTML = '&#10073;&#10073;';
        },

        pause() {
            if (!this.audio) return;
            this.audio.pause();
            this.isPlaying = false;
            document.getElementById('play-btn').innerHTML = '&#9654;';
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
        },

        updateUI() {
            const track = this.tracks[this.currentIndex];
            document.getElementById('track-title').textContent = track.title || 'Unknown Title';
            document.getElementById('track-artist').textContent = track.artist || '';
        },

        renderPlaylist() {
            const playlist = document.getElementById('playlist');
            playlist.innerHTML = '';
            this.tracks.forEach((track, idx) => {
                const item = document.createElement('div');
                item.className = 'playlist-item';
                item.textContent = `${track.title} — ${track.artist}`;
                item.onclick = () => {
                    this.loadTrack(idx);
                    this.play();
                };
                playlist.appendChild(item);
            });
            this.highlightActiveTrack();
        },

        highlightActiveTrack() {
            document.querySelectorAll('.playlist-item').forEach((el, idx) => {
                el.classList.toggle('active', idx === this.currentIndex);
            });
        },

        setupControls() {
            document.getElementById('play-btn').onclick = () => { this.togglePlay(); };
            document.getElementById('prev-btn').onclick = () => { this.prevTrack(); };
            document.getElementById('next-btn').onclick = () => { this.nextTrack(); };
        }
    };
}