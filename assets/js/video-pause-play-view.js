// Creates an observer that tracks when videos enter or leave the screen view
// Necessary to prevent Memory Leakage (RAM memory exhaustion in mobile browsers)
const videoMemoryOptimizer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    const videoElement = entry.target;
    if (entry.isIntersecting) {
      videoElement.play().catch(() => {}); // Resumes playback smoothly when visible
    } else {
      videoElement.pause(); // Instantly freezes decoding and drops mobile VRAM usage
    }
  });
}, { 
  threshold: 0.15 // Triggers when at least 15% of the video card box is visible
});

// Attach the script helper to both of your video elements
document.querySelectorAll('video.loop').forEach(element => {
  videoMemoryOptimizer.observe(element);
});