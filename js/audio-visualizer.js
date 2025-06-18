class AudioVisualizer {
  constructor(audioContext, canvas) {
    this.audioContext = audioContext;
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.analyser = audioContext.createAnalyser();
    this.analyser.fftSize = 2048;
    this.bufferLength = this.analyser.frequencyBinCount;
    this.dataArray = new Uint8Array(this.bufferLength);
    this.type = 'bars';
    this.isRunning = false;
    this.gradient = null;
    this.resize();
        
    // Create color gradients
    this.createGradients();
        
    // Handle window resize
    window.addEventListener('resize', () => this.resize());
        
    // Initialize settings
    this.settings = {
      barWidth: 2,
      barSpacing: 1,
      barMinHeight: 2,
      sensitivity: 1.5,
      smoothingTimeConstant: 0.8,
      peakDecay: 0.98,
      showPeaks: true
    };

    // Store peak values
    this.peaks = new Array(this.bufferLength).fill(0);
        
    // Animation properties
    this.rotationAngle = 0;
    this.hueRotation = 0;

    // Add gainNode for volume control
    this.gainNode = audioContext.createGain();
    this.gainNode.connect(audioContext.destination);
    
    // Connect analyser to gainNode
    this.analyser.connect(this.gainNode);
    
    // Initialize volume
    this._volume = 1.0;
    
    // Loading state
    this.isLoading = false;
    this.loadProgress = 0;
  }

  resize() {
    const dpr = window.devicePixelRatio || 1;
    const rect = this.canvas.getBoundingClientRect();
        
    // Set canvas size accounting for device pixel ratio
    this.canvas.width = rect.width * dpr;
    this.canvas.height = rect.height * dpr;
        
    // Scale context to device pixel ratio
    this.ctx.scale(dpr, dpr);
        
    // Update styles
    this.canvas.style.width = rect.width + 'px';
    this.canvas.style.height = rect.height + 'px';
        
    // Recreate gradients after resize
    this.createGradients();
  }

  createGradients() {
    // Classic Winamp gradient
    this.gradient = this.ctx.createLinearGradient(0, this.canvas.height, 0, 0);
    this.gradient.addColorStop(0, '#0f3');    // Green
    this.gradient.addColorStop(0.5, '#ff0');  // Yellow
    this.gradient.addColorStop(1, '#f00');    // Red
        
    // Wave gradient
    this.waveGradient = this.ctx.createLinearGradient(0, 0, this.canvas.width, 0);
    this.waveGradient.addColorStop(0, '#4a8fc9');     // Light blue
    this.waveGradient.addColorStop(0.5, '#3B719F');   // Mid blue
    this.waveGradient.addColorStop(1, '#4a8fc9');     // Light blue
  }

  // Add volume getter/setter
  get volume() {
    return this._volume;
  }

  set volume(value) {
    this._volume = Math.max(0, Math.min(1, value));
    if (this.gainNode) {
      this.gainNode.gain.value = this._volume;
    }
  }

  connectSource(source) {
    source.connect(this.analyser);
    // Update connection chain: source -> analyser -> gainNode -> destination
    this.analyser.disconnect(); // Disconnect existing connection
    this.analyser.connect(this.gainNode);
  }

  setLoadingState(isLoading, progress = 0) {
    this.isLoading = isLoading;
    this.loadProgress = progress;
    if (this.isLoading) {
      this.drawLoadingState();
    }
  }

  drawLoadingState() {
    if (!this.isLoading) return;

    const width = this.canvas.width;
    const height = this.canvas.height;
    
    // Clear canvas
    this.ctx.clearRect(0, 0, width, height);
    
    // Draw loading bar background
    this.ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
    const barWidth = width * 0.6;
    const barHeight = 4;
    const barX = (width - barWidth) / 2;
    const barY = height / 2;
    this.ctx.fillRect(barX, barY, barWidth, barHeight);
    
    // Draw loading progress
    this.ctx.fillStyle = this.gradient;
    this.ctx.fillRect(barX, barY, barWidth * this.loadProgress, barHeight);
    
    // Draw loading text
    this.ctx.fillStyle = '#fff';
    this.ctx.font = '14px Arial';
    this.ctx.textAlign = 'center';
    this.ctx.fillText('Loading... ' + Math.round(this.loadProgress * 100) + '%', width / 2, barY - 20);
  }

  start() {
    this.isRunning = true;
    this.draw();
  }

  stop() {
    this.isRunning = false;
  }

  draw() {
    if (!this.isRunning) return;

    requestAnimationFrame(() => this.draw());

    if (this.isLoading) {
      this.drawLoadingState();
      return;
    }

    // Get frequency data
    this.analyser.getByteFrequencyData(this.dataArray);
        
    // Clear canvas
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    switch (this.type) {
      case 'bars':
        this.drawBars();
        break;
      case 'wave':
        this.drawWave();
        break;
      case 'circle':
        this.drawCircle();
        break;
      case 'oscilloscope':
        this.drawOscilloscope();
        break;
    }
        
    // Update animation values
    this.rotationAngle += 0.01;
    this.hueRotation = (this.hueRotation + 1) % 360;
  }

  drawBars() {
    const width = this.canvas.width;
    const height = this.canvas.height;
    const analyzerData = Array.from(this.dataArray);
        
    // Calculate bar dimensions
    const totalBars = Math.min(128, Math.floor(width / (this.settings.barWidth + this.settings.barSpacing)));
    const barWidth = this.settings.barWidth;
    const spacing = this.settings.barSpacing;
        
    // Center the visualization
    const startX = (width - (totalBars * (barWidth + spacing))) / 2;
        
    for (let i = 0; i < totalBars; i++) {
      // Get frequency value and apply sensitivity
      const value = analyzerData[i] * this.settings.sensitivity;
      const barHeight = Math.max(this.settings.barMinHeight, (value / 255) * height);
            
      // Calculate bar position
      const x = startX + (i * (barWidth + spacing));
      const y = height - barHeight;
            
      // Draw main bar
      this.ctx.fillStyle = this.gradient;
      this.ctx.fillRect(x, y, barWidth, barHeight);
            
      // Update and draw peak
      if (this.settings.showPeaks) {
        if (barHeight > this.peaks[i]) {
          this.peaks[i] = barHeight;
        } else {
          this.peaks[i] *= this.settings.peakDecay;
        }
                
        // Draw peak line
        const peakY = height - this.peaks[i];
        this.ctx.fillStyle = '#fff';
        this.ctx.fillRect(x, peakY - 2, barWidth, 2);
      }
    }
  }

  drawWave() {
    const width = this.canvas.width;
    const height = this.canvas.height;
        
    this.ctx.lineWidth = 3;
    this.ctx.strokeStyle = this.waveGradient;
    this.ctx.beginPath();
        
    const sliceWidth = width / this.bufferLength;
    let x = 0;

    for (let i = 0; i < this.bufferLength; i++) {
      const v = this.dataArray[i] / 128.0;
      const y = v * height / 2;

      if (i === 0) {
        this.ctx.moveTo(x, y);
      } else {
        this.ctx.lineTo(x, y);
      }

      x += sliceWidth;
    }

    this.ctx.lineTo(width, height / 2);
    this.ctx.stroke();
        
    // Add glow effect
    this.ctx.shadowBlur = 10;
    this.ctx.shadowColor = '#4a8fc9';
    this.ctx.stroke();
    this.ctx.shadowBlur = 0;
  }

  drawCircle() {
    const width = this.canvas.width;
    const height = this.canvas.height;
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 4;
        
    // Update rotation
    this.ctx.save();
    this.ctx.translate(centerX, centerY);
    this.ctx.rotate(this.rotationAngle);
    this.ctx.translate(-centerX, -centerY);
        
    const totalBars = 180;
    const step = (Math.PI * 2) / totalBars;
        
    for (let i = 0; i < totalBars; i++) {
      const value = this.dataArray[i % this.bufferLength];
      const barHeight = (value / 255) * radius;
      const angle = step * i;
            
      const x1 = centerX + Math.cos(angle) * (radius - barHeight);
      const y1 = centerY + Math.sin(angle) * (radius - barHeight);
      const x2 = centerX + Math.cos(angle) * (radius + barHeight);
      const y2 = centerY + Math.sin(angle) * (radius + barHeight);
            
      // Draw bar with gradient
      const gradient = this.ctx.createLinearGradient(x1, y1, x2, y2);
      gradient.addColorStop(0, `hsl(${(i / totalBars * 360 + this.hueRotation) % 360}, 70%, 50%)`);
      gradient.addColorStop(1, `hsl(${((i / totalBars * 360 + 180 + this.hueRotation) % 360)}, 70%, 50%)`);
            
      this.ctx.beginPath();
      this.ctx.strokeStyle = gradient;
      this.ctx.lineWidth = 2;
      this.ctx.moveTo(x1, y1);
      this.ctx.lineTo(x2, y2);
      this.ctx.stroke();
    }
        
    this.ctx.restore();
  }

  drawOscilloscope() {
    const width = this.canvas.width;
    const height = this.canvas.height;
        
    // Get time domain data
    const timeData = new Uint8Array(this.analyser.frequencyBinCount);
    this.analyser.getByteTimeDomainData(timeData);
        
    this.ctx.lineWidth = 2;
    this.ctx.strokeStyle = '#4a8fc9';
    this.ctx.beginPath();
        
    const sliceWidth = width / timeData.length;
    let x = 0;
        
    for (let i = 0; i < timeData.length; i++) {
      const v = timeData[i] / 128.0;
      const y = v * height / 2;
            
      if (i === 0) {
        this.ctx.moveTo(x, y);
      } else {
        this.ctx.lineTo(x, y);
      }
            
      x += sliceWidth;
    }
        
    this.ctx.lineTo(width, height / 2);
    this.ctx.stroke();
        
    // Add glow
    this.ctx.shadowBlur = 5;
    this.ctx.shadowColor = '#4a8fc9';
    this.ctx.stroke();
    this.ctx.shadowBlur = 0;
  }
}

// Export for use in modules
try {
  if (window) {
    window.AudioVisualizer = AudioVisualizer;
  }
} catch (e) {
  // Not in browser environment
}

export default AudioVisualizer;
