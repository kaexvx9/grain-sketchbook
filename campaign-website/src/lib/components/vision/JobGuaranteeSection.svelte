<script>
  // Job Guarantee section with work illustration
</script>

<section class="job-guarantee-section">
  <div class="container">
    <h2 class="section-title">Job Guarantee</h2>
    <p class="section-lead">$25-35/hour minimum wage, regionally adjusted. Healthcare, childcare, retirement benefits.</p>
    
    <div class="work-grid">
      <div class="work-card">
        <div class="work-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Farming/permaculture icon -->
            <circle cx="50" cy="30" r="20" fill="var(--color-secondary)" opacity="0.6"/>
            <path d="M30,50 Q50,40 70,50" stroke="var(--color-green-blue-accent)" stroke-width="3" fill="none"/>
            <rect x="40" y="60" width="20" height="30" fill="var(--color-tertiary)" opacity="0.5"/>
          </svg>
        </div>
        <h3>Farming & Permaculture</h3>
        <p>Convert farms to food forests. Build soil, plant diversity, create habitat.</p>
      </div>
      
      <div class="work-card">
        <div class="work-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Construction icon -->
            <rect x="30" y="40" width="40" height="40" fill="var(--color-tertiary)" opacity="0.6"/>
            <line x1="30" y1="40" x2="50" y2="20" stroke="var(--color-border)" stroke-width="2"/>
            <line x1="70" y1="40" x2="50" y2="20" stroke="var(--color-border)" stroke-width="2"/>
            <rect x="45" y="50" width="10" height="20" fill="var(--color-primary)" opacity="0.7"/>
          </svg>
        </div>
        <h3>Traditional Urbanism</h3>
        <p>Build walkable communities. Timber framing, rammed earth, local materials.</p>
      </div>
      
      <div class="work-card">
        <div class="work-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Technology icon -->
            <rect x="25" y="30" width="50" height="40" fill="var(--color-bg-surface)" stroke="var(--color-primary)" stroke-width="2" rx="4"/>
            <circle cx="40" cy="45" r="5" fill="var(--color-primary)" opacity="0.7"/>
            <circle cx="60" cy="45" r="5" fill="var(--color-secondary)" opacity="0.7"/>
            <rect x="35" y="55" width="30" height="8" fill="var(--color-green-blue-accent)" opacity="0.6"/>
          </svg>
        </div>
        <h3>Technology Infrastructure</h3>
        <p>Maintain local compute clusters. Open-source systems, community networks.</p>
      </div>
      
      <div class="work-card">
        <div class="work-icon">
          <svg viewBox="0 0 100 100" aria-hidden="true">
            <!-- Education icon -->
            <path d="M30,20 L50,10 L70,20 L70,60 L50,70 L30,60 Z" fill="var(--color-bg-surface)" stroke="var(--color-secondary)" stroke-width="2"/>
            <circle cx="50" cy="40" r="8" fill="var(--color-secondary)" opacity="0.7"/>
            <path d="M40,50 Q50,55 60,50" stroke="var(--color-secondary)" stroke-width="2" fill="none"/>
          </svg>
        </div>
        <h3>Education & Teaching</h3>
        <p>Community learning centers. Intergenerational education, skill-sharing.</p>
      </div>
    </div>
  </div>
</section>

<style>
  .job-guarantee-section {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg);
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

  .work-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: var(--spacing-md);
  }

  .work-card {
    background: var(--color-bg-surface);
    padding: var(--spacing-md);
    border-radius: 8px;
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
    text-align: center;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
  }

  .work-card:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-md);
  }

  .work-icon {
    width: 80px;
    height: 80px;
    margin: 0 auto var(--spacing-sm);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .work-icon svg {
    width: 100%;
    height: 100%;
  }

  .work-card h3 {
    color: var(--color-primary);
    font-size: 1.25rem;
    margin-bottom: var(--spacing-sm);
  }

  .work-card p {
    color: var(--color-text-secondary);
    line-height: 1.6;
    margin: 0;
  }
</style>
