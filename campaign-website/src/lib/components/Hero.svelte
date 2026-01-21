<script>
  // Hero section with "risk love" slogan
</script>

<section class="hero">
  <div class="container">
    <div class="hero-content">
      <h1 class="hero-title">Keaton Livermore</h1>
      <p class="hero-subtitle">for California Governor 2026</p>
      <p class="hero-slogan">
        <strong>risk love</strong>
      </p>
      <p class="hero-tagline">
        Elegant simplicity with compassionate purpose
      </p>
      <div class="hero-actions">
        <a href="#get-involved" class="button button-primary">Get Involved</a>
        <a href="#platform" class="button button-secondary">Learn More</a>
      </div>
    </div>
  </div>
</section>

<style>
  .hero {
    background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-secondary) 100%);
    color: var(--color-text-inverse);
    padding: var(--spacing-lg) 0;
    text-align: center;
    position: relative;
    overflow: hidden;
  }

  .hero::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 30% 50%, rgba(255, 167, 38, 0.3), transparent 70%);
    pointer-events: none;
  }

  .hero-content {
    position: relative;
    z-index: 1;
  }

  .hero-content {
    max-width: 800px;
    margin: 0 auto;
  }

  .hero-title {
    font-size: 3rem;
    margin-bottom: var(--spacing-xs);
  }

  .hero-subtitle {
    font-size: 1.5rem;
    margin-bottom: var(--spacing-md);
    opacity: 0.9;
  }

  .hero-slogan {
    font-size: 2rem;
    margin-bottom: var(--spacing-sm);
  }

  .hero-tagline {
    font-size: 1.25rem;
    margin-bottom: var(--spacing-md);
    opacity: 0.95;
  }

  .hero-actions {
    display: flex;
    gap: var(--spacing-sm);
    justify-content: center;
    flex-wrap: wrap;
  }

  .button {
    display: inline-block;
    padding: var(--spacing-sm) var(--spacing-md);
    border-radius: 4px;
    font-weight: 600;
    text-decoration: none;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .button:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    text-decoration: none;
  }

  .button-primary {
    background: var(--color-text-inverse);
    color: var(--color-primary);
  }

  .button-primary:hover {
    background: var(--color-bg-surface);
    color: var(--color-primary-hover);
  }

  .button-secondary {
    background: rgba(255, 255, 255, 0.2);
    color: var(--color-text-inverse);
    border: 2px solid var(--color-text-inverse);
    backdrop-filter: blur(10px);
  }

  .button-secondary:hover {
    background: rgba(255, 255, 255, 0.3);
    border-color: var(--color-text-inverse);
  }

  @media (max-width: 767px) {
    .hero-title {
      font-size: 2rem;
    }

    .hero-subtitle {
      font-size: 1.25rem;
    }

    .hero-slogan {
      font-size: 1.5rem;
    }
  }
</style>
