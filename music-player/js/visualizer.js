function setupVisualizer(analyser, canvas) {
    const ctx = canvas.getContext('2d');
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    function draw() {
        requestAnimationFrame(draw);
        analyser.getByteFrequencyData(dataArray);
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        dataArray.forEach((value, index) => {
            ctx.fillStyle = `rgb(${value}, ${value / 2}, ${255 - value})`;
            ctx.fillRect(index * 5, canvas.height - value, 4, value);
        });
    }

    draw();
}

export default setupVisualizer;