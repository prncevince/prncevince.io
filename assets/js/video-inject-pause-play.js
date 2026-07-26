// 2 Steps
// - 1st: injects correct video assets to DOM on page load
//   Necessary to select proper source video codecs for browser environment (e.g. iOS or all other)
// - 2nd: add page "intersection observer" for scrolling out of view
//        & visibility change event listener for switching tabs
//   Pauses looping videos when out of the viewport (`isIntersecting`) OR when switching to new tab `document.hidden`
document.addEventListener("DOMContentLoaded", () => {

  // Helper function to cleanly build and attach a source element
  function injectVideoSource(videoNode, assetConfig) {
    if (!videoNode) return;
    const source = document.createElement("source");
    if (isIOS) {
      source.src = assetConfig.hevc.src;
      source.type = assetConfig.hevc.type;
    } else {
      source.src = assetConfig.webm.src;
      source.type = assetConfig.webm.type;
    }
    videoNode.appendChild(source);
    videoNode.load(); // Boots up the specific hardware decoding pipeline
  }
  // Define the path map for video assets (web app & show reel)
  const assets = {
    app: {
      webm: {
        src: "/assets/vid/savi-2026-07-24.webm",
        type: "video/webm; codecs=vp9"
      },
      hevc: {
        src: "/assets/vid/savi-2026-07-24-h265.mp4",
        type: "video/mp4; codecs=hvc1.1.6.L120.90"
      }
    },
    reel: {
      webm: {
        src: "/assets/vid/trailer-chasing-freedom-720p-1200kbps-dn.webm",
        type: "video/webm; codecs=vp9"
      },
      hevc: {
        src: "/assets/vid/trailer-chasing-freedom-720p-1200kbps-dn-h265-slow.mp4",
        type: "video/mp4; codecs=hvc1.1.6.L120.90"
      }
    }
  };
  // Detect if the user is explicitly on iOS WebKit (iPhone / iPad)
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || 
                (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  // video element selection
  const appVideo = document.querySelector("video.loop.app");
  const reelVideo = document.querySelector("video.loop.reel");
  // Execute the single-fetch source injections
  injectVideoSource(appVideo, assets.app);
  injectVideoSource(reelVideo, assets.reel);

  // Gather the newly initialized videos to attach Pause/Play performance handlers
  const activeVideos = document.querySelectorAll('video.loop');
  // 1. The Scroll Observer: Only updates the state, doesn't spam play/pause blindly
  const scrollVideoObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const video = entry.target;
      if (entry.isIntersecting) {
        video.setAttribute('data-visible', 'true');
        // Only play if the entire browser tab is actually active
        if (!document.hidden) {
          video.play().catch(() => {});
        }
      } else {
        video.setAttribute('data-visible', 'false');
        video.pause();
      }
    });
  }, { threshold: 0.15 });
  // Attach the scroll observer to all loops
  activeVideos.forEach((video) => scrollVideoObserver.observe(video));
  // 2. The Tab Switcher: Cross-references the scroll state before playing
  document.addEventListener("visibilitychange", () => {
    activeVideos.forEach((video) => {
      if (document.hidden) {
        video.pause(); // Freezes everything safely when you leave
      } else {
        // CRITICAL STEP: Only resume playback if the card is actively on-screen
        const isCardVisible = video.getAttribute('data-visible') === 'true';
        if (isCardVisible) {
          video.play().catch(() => {});
        }
      }
    });
  });
});
