// Lazy loading utilities
// Following performance-first principles

/**
 * Intersection Observer for lazy loading images
 */
export function lazyLoadImages() {
  if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target;
          if (img.dataset.src) {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
            img.classList.add('loaded');
            observer.unobserve(img);
          }
        }
      });
    }, {
      rootMargin: '50px' // Start loading 50px before image enters viewport
    });

    // Observe all images with data-src
    document.querySelectorAll('img[data-src]').forEach(img => {
      imageObserver.observe(img);
    });
  } else {
    // Fallback for older browsers
    document.querySelectorAll('img[data-src]').forEach(img => {
      img.src = img.dataset.src;
      img.removeAttribute('data-src');
    });
  }
}

/**
 * Lazy load YouTube embeds
 */
export function lazyLoadEmbeds() {
  if ('IntersectionObserver' in window) {
    const embedObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const container = entry.target;
          const iframe = container.querySelector('iframe[data-src]');
          if (iframe) {
            iframe.src = iframe.dataset.src;
            iframe.removeAttribute('data-src');
            observer.unobserve(container);
          }
        }
      });
    }, {
      rootMargin: '100px'
    });

    document.querySelectorAll('.lazy-embed').forEach(container => {
      embedObserver.observe(container);
    });
  }
}

/**
 * Initialize all lazy loading
 */
export function initLazyLoading() {
  lazyLoadImages();
  lazyLoadEmbeds();
}
