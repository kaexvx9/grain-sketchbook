<script>
  // Permaculture food forest section with SVG illustration
</script>

<section class="permaculture-section">
  <div class="container">
    <div class="section-content">
      <div class="text-content">
        <h2>Organic Permaculture Food Forests</h2>
        <p class="lead">Converting farms to regenerative, diverse food systems that heal the land as they feed us.</p>
        
        <div class="features">
          <div class="feature">
            <h3>Regeneration</h3>
            <p>No-till agriculture, cover crops, compost, and biochar enrich the soil year after year.</p>
          </div>
          
          <div class="feature">
            <h3>Diversity</h3>
            <p>Hemp, bamboo, timber, and diverse fruit and nut trees create abundant, resilient ecosystems.</p>
          </div>
          
          <div class="feature">
            <h3>Community</h3>
            <p>Job Guarantee workers learn permaculture while building soil and planting food forests.</p>
          </div>
        </div>
      </div>
      
      <div class="illustration">
        <svg viewBox="0 0 400 400" class="permaculture-svg" aria-hidden="true">
          <!-- Food forest layers illustration -->
          
          <!-- Canopy layer (tall trees) -->
          <g class="canopy-layer">
            <circle cx="100" cy="80" r="45" fill="var(--color-secondary)" opacity="0.7"/>
            <circle cx="200" cy="70" r="50" fill="var(--color-green-blue-accent)" opacity="0.6"/>
            <circle cx="300" cy="85" r="48" fill="var(--color-secondary)" opacity="0.7"/>
            <circle cx="150" cy="100" r="42" fill="var(--color-green-blue-medium)" opacity="0.6"/>
            <circle cx="250" cy="95" r="46" fill="var(--color-secondary)" opacity="0.7"/>
          </g>
          
          <!-- Understory layer (shrubs) -->
          <g class="understory-layer">
            <circle cx="80" cy="180" r="25" fill="var(--color-tertiary)" opacity="0.6"/>
            <circle cx="180" cy="170" r="28" fill="var(--color-green-blue-subtle)" opacity="0.5"/>
            <circle cx="280" cy="185" r="26" fill="var(--color-tertiary)" opacity="0.6"/>
            <circle cx="130" cy="200" r="24" fill="var(--color-green-blue-medium)" opacity="0.5"/>
            <circle cx="230" cy="195" r="27" fill="var(--color-tertiary)" opacity="0.6"/>
            <circle cx="320" cy="190" r="25" fill="var(--color-green-blue-subtle)" opacity="0.5"/>
          </g>
          
          <!-- Ground cover layer -->
          <g class="ground-layer">
            <circle cx="60" cy="280" r="15" fill="var(--color-green-blue-dark)" opacity="0.5"/>
            <circle cx="140" cy="275" r="18" fill="var(--color-secondary)" opacity="0.4"/>
            <circle cx="220" cy="285" r="16" fill="var(--color-green-blue-dark)" opacity="0.5"/>
            <circle cx="300" cy="280" r="17" fill="var(--color-secondary)" opacity="0.4"/>
            <circle cx="100" cy="300" r="15" fill="var(--color-green-blue-medium)" opacity="0.5"/>
            <circle cx="260" cy="295" r="16" fill="var(--color-green-blue-dark)" opacity="0.5"/>
          </g>
          
          <!-- Soil/roots (subtle) -->
          <rect x="0" y="320" width="400" height="80" 
                fill="var(--color-tertiary)" 
                opacity="0.3"/>
          
          <!-- Connecting mycelium network (permaculture principle) -->
          <path d="M100,80 Q150,150 200,70 T300,85" 
                stroke="var(--color-green-blue-accent)" 
                stroke-width="1.5" 
                fill="none" 
                opacity="0.3"/>
          <path d="M80,180 Q130,220 180,170 T280,185" 
                stroke="var(--color-green-blue-medium)" 
                stroke-width="1" 
                fill="none" 
                opacity="0.3"/>
        </svg>
      </div>
    </div>
  </div>
</section>

<style>
  .permaculture-section {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg-alt);
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
    border-left: 4px solid var(--color-secondary);
    border-radius: 4px;
  }

  .feature h3 {
    color: var(--color-secondary);
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

  .permaculture-svg {
    width: 100%;
    max-width: 400px;
    height: auto;
  }

  @media (max-width: 968px) {
    .section-content {
      grid-template-columns: 1fr;
    }

    .illustration {
      order: -1; /* Show illustration first on mobile */
    }
  }
</style>
