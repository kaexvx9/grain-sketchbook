<script>
  // Regional optimization section with California map SVG
</script>

<section class="regional-section">
  <div class="container">
    <h2 class="section-title">Regional Optimization</h2>
    <p class="section-lead">California is many places. Each region has its own character, opportunities, and potential.</p>
    
    <div class="regions">
      <div class="region-card">
        <h3>Central Valley</h3>
        <p>Fresno, Bakersfield, Modesto, Stockton</p>
        <p class="region-desc">Food forests with hemp, bamboo, timber, and diverse fruit and nut trees. Higher density, urban agriculture integration.</p>
        <div class="region-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Valley/fields -->
            <rect x="10" y="40" width="80" height="50" fill="var(--color-secondary)" opacity="0.4"/>
            <circle cx="30" cy="50" r="8" fill="var(--color-secondary)" opacity="0.6"/>
            <circle cx="50" cy="55" r="8" fill="var(--color-green-blue-accent)" opacity="0.5"/>
            <circle cx="70" cy="50" r="8" fill="var(--color-secondary)" opacity="0.6"/>
          </svg>
        </div>
      </div>
      
      <div class="region-card">
        <h3>Bay Area</h3>
        <p>San Francisco, Oakland, San Jose, Berkeley</p>
        <p class="region-desc">Urban permaculture integration, traditional urbanism communities, local technology infrastructure. Higher density, mixed-use, walkable.</p>
        <div class="region-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Urban/building -->
            <rect x="30" y="40" width="15" height="40" fill="var(--color-tertiary)" opacity="0.6"/>
            <rect x="50" y="30" width="15" height="50" fill="var(--color-tertiary)" opacity="0.6"/>
            <rect x="70" y="35" width="15" height="45" fill="var(--color-tertiary)" opacity="0.6"/>
            <circle cx="57" cy="25" r="8" fill="var(--color-primary)" opacity="0.7"/>
          </svg>
        </div>
      </div>
      
      <div class="region-card">
        <h3>Los Angeles Basin</h3>
        <p>Los Angeles, Long Beach, Pasadena, Santa Monica</p>
        <p class="region-desc">Marine permaculture integration, ocean resilience, hybrid economy. Kelp farming, coastal food forests, salt-tolerant plants.</p>
        <div class="region-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Ocean/coast -->
            <rect x="0" y="50" width="100" height="50" fill="var(--color-info)" opacity="0.4"/>
            <path d="M0,50 Q25,45 50,50 T100,50" stroke="var(--color-info)" stroke-width="2" fill="none" opacity="0.6"/>
            <circle cx="20" cy="30" r="6" fill="var(--color-secondary)" opacity="0.6"/>
            <circle cx="40" cy="25" r="6" fill="var(--color-green-blue-accent)" opacity="0.5"/>
            <circle cx="60" cy="28" r="6" fill="var(--color-secondary)" opacity="0.6"/>
          </svg>
        </div>
      </div>
    </div>
  </div>
</section>

<style>
  .regional-section {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg-alt);
  }

  .section-title {
    text-align: center;
    color: var(--color-primary);
    font-size: 2.5rem;
    margin-bottom: var(--spacing-sm);
  }

  .section-lead {
    text-align: center;
    font-size: 1.25rem;
    color: var(--color-text-secondary);
    margin-bottom: var(--spacing-lg);
    max-width: 800px;
    margin-left: auto;
    margin-right: auto;
  }

  .regions {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: var(--spacing-md);
  }

  .region-card {
    background: var(--color-bg-surface);
    padding: var(--spacing-md);
    border-radius: 8px;
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
    text-align: center;
  }

  .region-card h3 {
    color: var(--color-primary);
    font-size: 1.5rem;
    margin-bottom: var(--spacing-xs);
  }

  .region-card > p:first-of-type {
    color: var(--color-secondary);
    font-weight: 600;
    margin-bottom: var(--spacing-sm);
  }

  .region-desc {
    color: var(--color-text-secondary);
    line-height: 1.6;
    margin-bottom: var(--spacing-sm);
  }

  .region-icon {
    width: 100px;
    height: 100px;
    margin: var(--spacing-sm) auto 0;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .region-icon svg {
    width: 100%;
    height: 100%;
  }
</style>
