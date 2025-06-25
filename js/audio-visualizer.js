class AudioVisualizer {
  constructor(audioContext, canvas) {
    this.audioContext = audioContext;
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.analyser = audioContext.createAnalyser();
    this.analyser.fftSize = 2048;
    this.bufferLength = this.analyser.frequencyBinCount;
    this.dataArray = new Uint8Array(this.bufferLength);

    this.type = 'bars'; // Visualization type
    this.isRunning = false;
    this.gradient = null;

    this.createGradients(); // Ambient gradient
    this.resize();

    // Settings for visualization
    this.settings = {
      barWidth: 2,
      barSpacing: 1,
      sensitivity: 1.5,
      smoothingTimeConstant: 0.8,
    };

    window.addEventListener('resize', () => this.resize());
  }

  createGradients() {
    this.gradient = this.ctx.createLinearGradient(0, this.canvas.height, 0, 0);
    this.gradient.addColorStop(0, '#4a8fc9'); // Light blue
    this.gradient.addColorStop(0.5, '#3B719F'); // Mid blue
    this.gradient.addColorStop(1, '#4a8fc9'); // Light blue
  }

  drawBars() {
    const width = this.canvas.width;
    const height = this.canvas.height;

    const totalBars = Math.min(128, Math.floor(width / (this.settings.barWidth + this.settings.barSpacing)));
    const barWidth = this.settings.barWidth;
    const spacing = this.settings.barSpacing;

    const startX = (width - (totalBars * (barWidth + spacing))) / 2;
    this.ctx.fillStyle = this.gradient;

    for (let i = 0; i < totalBars; i++) {
      const barHeight = Math.random() * height; // Example data for visualization
      const x = startX + (i * (barWidth + spacing));
      const y = height - barHeight;

      this.ctx.fillRect(x, y, barWidth, barHeight);
    }
  }
}