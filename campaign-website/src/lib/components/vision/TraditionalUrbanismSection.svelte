<script>
  // Traditional urbanism section with community layout SVG
</script>

<section class="urbanism-section">
  <div class="container">
    <div class="section-content">
      <div class="illustration">
        <svg viewBox="0 0 500 400" class="urbanism-svg" aria-hidden="true">
          <!-- Traditional urbanism community layout -->
          
          <!-- Walls (community boundaries) -->
          <rect x="50" y="50" width="400" height="300" 
                fill="none" 
                stroke="var(--color-tertiary)" 
                stroke-width="3" 
                rx="8"/>
          
          <!-- Main street (horizontal) -->
          <rect x="50" y="200" width="400" height="20" 
                fill="var(--color-border-medium)" 
                opacity="0.5"/>
          
          <!-- Buildings (mixed use) -->
          <!-- Left side buildings -->
          <rect x="80" y="80" width="120" height="100" 
                fill="var(--color-bg-surface)" 
                stroke="var(--color-border)" 
                stroke-width="2"/>
          <rect x="80" y="220" width="120" height="100" 
                fill="var(--color-bg-surface)" 
                stroke="var(--color-border)" 
                stroke-width="2"/>
          
          <!-- Center buildings (taller) -->
          <rect x="220" y="60" width="140" height="120" 
                fill="var(--color-bg-surface)" 
                stroke="var(--color-border)" 
                stroke-width="2"/>
          <rect x="220" y="240" width="140" height="100" 
                fill="var(--color-bg-surface)" 
                stroke="var(--color-border)" 
                stroke-width="2"/>
          
          <!-- Right side buildings -->
          <rect x="380" y="90" width="50" height="90" 
                fill="var(--color-bg-surface)" 
                stroke="var(--color-border)" 
                stroke-width="2"/>
          <rect x="380" y="230" width="50" height="90" 
                fill="var(--color-bg-surface)" 
                stroke="var(--color-border)" 
                stroke-width="2"/>
          
          <!-- Windows -->
          <g class="windows">
            <rect x="95" y="100" width="15" height="20" fill="var(--color-primary)" opacity="0.6"/>
            <rect x="120" y="100" width="15" height="20" fill="var(--color-primary)" opacity="0.6"/>
            <rect x="170" y="100" width="15" height="20" fill="var(--color-primary)" opacity="0.6"/>
            <rect x="240" y="80" width="20" height="25" fill="var(--color-primary)" opacity="0.6"/>
            <rect x="280" y="80" width="20" height="25" fill="var(--color-primary)" opacity="0.6"/>
            <rect x="320" y="80" width="20" height="25" fill="var(--color-primary)" opacity="0.6"/>
          </g>
          
          <!-- Productive trees (espaliered on walls) -->
          <g class="trees">
            <circle cx="50" cy="150" r="12" fill="var(--color-secondary)" opacity="0.7"/>
            <circle cx="450" cy="150" r="12" fill="var(--color-secondary)" opacity="0.7"/>
            <circle cx="50" cy="250" r="12" fill="var(--color-secondary)" opacity="0.7"/>
            <circle cx="450" cy="250" r="12" fill="var(--color-secondary)" opacity="0.7"/>
            
            <!-- Community orchard (center) -->
            <circle cx="250" cy="180" r="15" fill="var(--color-secondary)" opacity="0.6"/>
            <circle cx="230" cy="200" r="12" fill="var(--color-green-blue-accent)" opacity="0.5"/>
            <circle cx="270" cy="200" r="12" fill="var(--color-secondary)" opacity="0.6"/>
          </g>
          
          <!-- Water features (canals) -->
          <rect x="50" y="350" width="400" height="8" 
                fill="var(--color-info)" 
                opacity="0.4"/>
          
          <!-- Narrow alleys (human-scaled) -->
          <rect x="200" y="50" width="8" height="150" 
                fill="var(--color-border)" 
                opacity="0.3"/>
          <rect x="300" y="200" width="8" height="150" 
                fill="var(--color-border)" 
                opacity="0.3"/>
        </svg>
      </div>
      
      <div class="text-content">
        <h2>Traditional Urbanism</h2>
        <p class="lead">Walkable, sustainable communities built with local materials for permanence.</p>
        
        <div class="features">
          <div class="feature">
            <h3>Human-Scaled</h3>
            <p>Narrow streets, mixed-use buildings, productive trees, and water features create community spaces.</p>
          </div>
          
          <div class="feature">
            <h3>Local Materials</h3>
            <p>Timber frame, rammed earth, fired brick, and stone from nearby sources—everything permanent.</p>
          </div>
          
          <div class="feature">
            <h3>Productive Beauty</h3>
            <p>Espaliered fruit trees, community orchards, market gardens—trees mean productivity and meaning.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<style>
  .urbanism-section {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg);
  }

  .section-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--spacing-lg);
    align-items: center;
  }

  .text-content h2 {
    color: var(--color-primary);
    font-size: 2.5rem;
    margin-bottom: var(--spacing-sm);
  }

  .lead {
    font-size: 1.25rem;
    color: var(--color-text-secondary);
    margin-bottom: var(--spacing-md);
    line-height: 1.6;
  }

  .features {
    display: flex;
    flex-direction: column;
    gap: var(--spacing-md);
  }

  .feature {
    padding: var(--spacing-sm);
    background: var(--color-bg-surface);
    border-left: 4px solid var(--color-tertiary);
    border-radius: 4px;
  }

  .feature h3 {
    color: var(--color-tertiary);
    font-size: 1.25rem;
    margin-bottom: var(--spacing-xs);
  }

  .feature p {
    color: var(--color-text-secondary);
    line-height: 1.6;
  }

  .illustration {
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .urbanism-svg {
    width: 100%;
    max-width: 500px;
    height: auto;
  }

  @media (max-width: 968px) {
    .section-content {
      grid-template-columns: 1fr;
    }
  }
</style>
