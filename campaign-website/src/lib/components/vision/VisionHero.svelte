<script>
  // Hero section for the Vision page
  // Features custom SVG illustration
</script>

<section class="vision-hero">
  <div class="container">
    <div class="hero-content">
      <h1 class="hero-title">The Aspiring Beauty</h1>
      <p class="hero-subtitle">A California Vision</p>
      <p class="hero-tagline">Organic permaculture meets fair-trade infrastructure</p>
    </div>
    
    <div class="hero-illustration">
      <svg viewBox="0 0 800 400" class="vision-svg" aria-hidden="true">
        <!-- California landscape with sunset -->
        <!-- Mountains -->
        <path d="M0,300 Q200,200 400,250 T800,280 L800,400 L0,400 Z" 
              fill="url(#mountainGradient)" />
        
        <!-- Central Valley fields (geometric permaculture) -->
        <g transform="translate(100, 250)">
          <!-- Food forest pattern -->
          <circle cx="0" cy="0" r="30" fill="var(--color-secondary)" opacity="0.6"/>
          <circle cx="60" cy="20" r="25" fill="var(--color-secondary)" opacity="0.5"/>
          <circle cx="120" cy="0" r="30" fill="var(--color-secondary)" opacity="0.6"/>
          <circle cx="180" cy="25" r="28" fill="var(--color-secondary)" opacity="0.5"/>
          <circle cx="240" cy="5" r="30" fill="var(--color-secondary)" opacity="0.6"/>
          
          <!-- Connecting lines (permaculture design) -->
          <path d="M0,0 L60,20 L120,0 L180,25 L240,5" 
                stroke="var(--color-green-blue-accent, var(--color-secondary))" 
                stroke-width="2" 
                fill="none" 
                opacity="0.4"/>
        </g>
        
        <!-- Sunset gradient -->
        <defs>
          <linearGradient id="sunsetGradient" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style="stop-color:var(--color-primary);stop-opacity:0.8" />
            <stop offset="50%" style="stop-color:var(--color-secondary);stop-opacity:0.6" />
            <stop offset="100%" style="stop-color:var(--color-tertiary);stop-opacity:0.4" />
          </linearGradient>
          <linearGradient id="mountainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" style="stop-color:var(--color-green-blue-dark, var(--color-secondary));stop-opacity:0.6" />
            <stop offset="100%" style="stop-color:var(--color-green-blue-medium, var(--color-secondary));stop-opacity:0.3" />
          </linearGradient>
        </defs>
        
        <!-- Sun -->
        <circle cx="650" cy="100" r="60" fill="url(#sunsetGradient)" />
        
        <!-- Sky gradient -->
        <rect x="0" y="0" width="800" height="250" 
              fill="url(#sunsetGradient)" />
      </svg>
    </div>
  </div>
</section>

<style>
  .vision-hero {
    padding: var(--spacing-lg) 0;
    background: linear-gradient(135deg, var(--color-bg) 0%, var(--color-bg-alt) 100%);
  }

  .hero-content {
    text-align: center;
    margin-bottom: var(--spacing-lg);
  }

  .hero-title {
    font-size: 3.5rem;
    color: var(--color-primary);
    margin-bottom: var(--spacing-sm);
  }

  .hero-subtitle {
    font-size: 2rem;
    color: var(--color-text-secondary);
    margin-bottom: var(--spacing-sm);
  }

  .hero-tagline {
    font-size: 1.25rem;
    color: var(--color-secondary);
    font-weight: 600;
  }

  .hero-illustration {
    max-width: 100%;
    margin: 0 auto;
  }

  .vision-svg {
    width: 100%;
    height: auto;
    max-height: 400px;
  }

  @media (max-width: 767px) {
    .hero-title {
      font-size: 2.5rem;
    }

    .hero-subtitle {
      font-size: 1.5rem;
    }

    .vision-svg {
      max-height: 300px;
    }
  }
</style>
