
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
                    { id: "default-1", title: "Sample Track", artist: "Unknown Artist", path: "../assets/audio/sample.mp