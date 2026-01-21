<script>
  import Stub from './Stub.svelte';
</script>

<section id="about" class="about-section">
  <div class="container">
    <h2>About the Campaign</h2>
    
    <div class="about-content">
      <div class="about-card">
        <h3>Keaton Livermore</h3>
        <p class="role">Candidate for California Governor 2026</p>
        <p>29 years old, will be 30 by January 2027. Ten years of studying healthy development and congress communication.</p>
        <Stub message="Full bio and background coming soon" />
      </div>
      
      <div class="about-card">
        <h3>Reya</h3>
        <p class="role">Virtual Lieutenant Governor</p>
        <p>Vegan healthy digital voice, neon-bright, high-tech with high ethics. Represents the digital-native generation, organic permaculture and fair-trade infrastructure ethic.</p>
        <Stub message="More about Reya's role coming soon" />
      </div>
    </div>
    
    <div class="slogan-box">
      <p class="slogan-large"><strong>risk love</strong></p>
      <p class="slogan-tagline">Elegant simplicity with compassionate purpose</p>
    </div>
  </div>
</section>

<style>
  .about-section {
    padding: var(--spacing-lg) 0;
  }

  .about-section h2 {
    text-align: center;
    margin-bottom: var(--spacing-lg);
    font-size: 2.5rem;
  }

  .about-content {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: var(--spacing-md);
    margin-bottom: var(--spacing-lg);
  }

  .about-card {
    background: var(--color-bg-surface);
    padding: var(--spacing-md);
    border-radius: 8px;
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
  }

  .about-card h3 {
    color: var(--color-primary);
    margin-bottom: var(--spacing-xs);
    font-size: 1.75rem;
  }

  .role {
    color: var(--color-secondary);
    font-weight: 600;
    margin-bottom: var(--spacing-sm);
    font-size: 1.125rem;
  }

  .about-card p {
    color: var(--color-text-secondary);
    line-height: 1.6;
    margin-bottom: var(--spacing-sm);
  }

  .slogan-box {
    text-align: center;
    padding: var(--spacing-lg);
    background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-secondary) 100%);
    border-radius: 12px;
    color: var(--color-text-inverse);
    margin-top: var(--spacing-lg);
  }

  .slogan-large {
    font-size: 3rem;
    font-weight: 700;
    margin-bottom: var(--spacing-sm);
  }

  .slogan-tagline {
    font-size: 1.5rem;
    opacity: 0.95;
    margin: 0;
  }

  @media (max-width: 767px) {
    .slogan-large {
      font-size: 2rem;
    }

    .slogan-tagline {
      font-size: 1.25rem;
    }
  }
</style>
