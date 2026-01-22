<script>
  // Fair-trade infrastructure section with technology SVG
</script>

<section class="technology-section">
  <div class="container">
    <div class="section-content">
      <div class="text-content">
        <h2>Fair-Trade Infrastructure</h2>
        <p class="lead">Open-source technology that serves communities with transparency, repairability, and local control.</p>
        
        <div class="features">
          <div class="feature">
            <h3>Local Compute Clusters</h3>
            <p>Sustainable energy powers open-source systems designed for repairability, privacy, and community control.</p>
          </div>
          
          <div class="feature">
            <h3>Autonomous Farming</h3>
            <p>Networked robotics and sensors, no-till compatible, self-assemblable, open-source, and modular.</p>
          </div>
          
          <div class="feature">
            <h3>Community Ownership</h3>
            <p>When something breaks, your neighbor can fix it. When you need a feature, your community can build it.</p>
          </div>
        </div>
      </div>
      
      <div class="illustration">
        <svg viewBox="0 0 400 400" class="technology-svg" aria-hidden="true">
          <!-- Technology infrastructure illustration -->
          
          <!-- Local compute cluster (circular nodes) -->
          <g class="cluster">
            <circle cx="200" cy="150" r="40" 
                    fill="var(--color-secondary)" 
                    opacity="0.3" 
                    stroke="var(--color-secondary)" 
                    stroke-width="2"/>
            <circle cx="150" cy="200" r="30" 
                    fill="var(--color-green-blue-accent)" 
                    opacity="0.4" 
                    stroke="var(--color-green-blue-accent)" 
                    stroke-width="2"/>
            <circle cx="250" cy="200" r="30" 
                    fill="var(--color-secondary)" 
                    opacity="0.4" 
                    stroke="var(--color-secondary)" 
                    stroke-width="2"/>
            <circle cx="200" cy="250" r="35" 
                    fill="var(--color-green-blue-medium)" 
                    opacity="0.3" 
                    stroke="var(--color-green-blue-medium)" 
                    stroke-width="2"/>
            
            <!-- Network connections -->
            <line x1="200" y1="150" x2="150" y2="200" 
                  stroke="var(--color-green-blue-accent)" 
                  stroke-width="2" 
                  opacity="0.5"/>
            <line x1="200" y1="150" x2="250" y2="200" 
                  stroke="var(--color-secondary)" 
                  stroke-width="2" 
                  opacity="0.5"/>
            <line x1="150" y1="200" x2="200" y2="250" 
                  stroke="var(--color-green-blue-medium)" 
                  stroke-width="2" 
                  opacity="0.5"/>
            <line x1="250" y1="200" x2="200" y2="250" 
                  stroke="var(--color-secondary)" 
                  stroke-width="2" 
                  opacity="0.5"/>
            <line x1="150" y1="200" x2="250" y2="200" 
                  stroke="var(--color-green-blue-accent)" 
                  stroke-width="1.5" 
                  opacity="0.4"/>
          </g>
          
          <!-- Solar panels (sustainable energy) -->
          <g class="solar" transform="translate(50, 50)">
            <rect x="0" y="0" width="60" height="40" 
                  fill="var(--color-primary)" 
                  opacity="0.6" 
                  rx="2"/>
            <line x1="10" y1="0" x2="10" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="20" y1="0" x2="20" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="30" y1="0" x2="30" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="40" y1="0" x2="40" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="50" y1="0" x2="50" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
          </g>
          
          <g class="solar" transform="translate(290, 50)">
            <rect x="0" y="0" width="60" height="40" 
                  fill="var(--color-primary)" 
                  opacity="0.6" 
                  rx="2"/>
            <line x1="10" y1="0" x2="10" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="20" y1="0" x2="20" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="30" y1="0" x2="30" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="40" y1="0" x2="40" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
            <line x1="50" y1="0" x2="50" y2="40" 
                  stroke="var(--color-text)" 
                  stroke-width="1" 
                  opacity="0.3"/>
          </g>
          
          <!-- Autonomous robot (farming) -->
          <g class="robot" transform="translate(120, 300)">
            <rect x="0" y="0" width="80" height="60" 
                  fill="var(--color-bg-surface)" 
                  stroke="var(--color-border)" 
                  stroke-width="2" 
                  rx="4"/>
            <circle cx="20" cy="20" r="8" fill="var(--color-info)" opacity="0.7"/>
            <circle cx="60" cy="20" r="8" fill="var(--color-info)" opacity="0.7"/>
            <rect x="30" y="35" width="20" height="15" 
                  fill="var(--color-secondary)" 
                  opacity="0.6" 
                  rx="2"/>
            <!-- Wheels -->
            <circle cx="15" cy="55" r="8" fill="var(--color-tertiary)" opacity="0.5"/>
            <circle cx="65" cy="55" r="8" fill="var(--color-tertiary)" opacity="0.5"/>
          </g>
          
          <!-- Open-source symbol (simplified) -->
          <g class="opensource" transform="translate(280, 320)">
            <circle cx="0" cy="0" r="25" 
                    fill="none" 
                    stroke="var(--color-green-blue-accent)" 
                    stroke-width="2" 
                    opacity="0.6"/>
            <path d="M-15,-10 L15,10 M15,-10 L-15,10" 
                  stroke="var(--color-green-blue-accent)" 
                  stroke-width="2" 
                  opacity="0.6"/>
          </g>
        </svg>
      </div>
    </div>
  </div>
</section>

<style>
  .technology-section {
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
    border-left: 4px solid var(--color-primary);
    border-radius: 4px;
  }

  .feature h3 {
    color: var(--color-primary);
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

  .technology-svg {
    width: 100%;
    max-width: 400px;
    height: auto;
  }

  @media (max-width: 968px) {
    .section-content {
      grid-template-columns: 1fr;
    }

    .illustration {
      order: -1;
    }
  }
</style>
