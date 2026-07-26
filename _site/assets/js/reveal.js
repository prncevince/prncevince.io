const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    // Check if the element has entered the viewport
    if (entry.isIntersecting) {
      entry.target.classList.add('in');
      // Optional: Stop observing if you only want it to fade in once
      // observer.unobserve(entry.target); 
    }
  });
}, {
  threshold: 0.25 // Triggers when 15% of the element is visible
});

// Attach the observer to all target elements
document.querySelectorAll('.reveal').forEach(element => {
  observer.observe(element);
});