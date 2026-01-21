<script>
  import Stub from './Stub.svelte';
  
  // Platform section component
  // Shows key campaign platform points
</script>

<section id="platform" class="platform-section">
  <div class="container">
    <h2>Our Platform</h2>
    
    <div class="platform-grid">
      <div class="platform-card">
        <h3>Job Guarantee</h3>
        <p>$25-35/hour minimum wage, regionally adjusted. Healthcare, childcare, retirement benefits.</p>
        <Stub message="Full Job Guarantee details coming soon" />
      </div>
      
      <div class="platform-card">
        <h3>Organic Permaculture</h3>
        <p>Convert farms to vegan permaculture food forests. Regenerative agriculture that heals the land.</p>
        <Stub message="Permaculture conversion plan details coming soon" />
      </div>
      
      <div class="platform-card">
        <h3>Traditional Urbanism</h3>
        <p>Walkable, sustainable communities. Local materials, permanent construction, human-scaled design.</p>
        <Stub message="Traditional urbanism specifications coming soon" />
      </div>
      
      <div class="platform-card">
        <h3>Fair-Trade Infrastructure</h3>
        <p>Open-source technology, local compute clusters, community-controlled networks, repairable hardware.</p>
        <Stub message="Technology infrastructure details coming soon" />
      </div>
    </div>
  </div>
</section>

<style>
  .platform-section {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg-alt);
  }

  .platform-section h2 {
    text-align: center;
    margin-bottom: var(--spacing-lg);
    font-size: 2.5rem;
  }

  .platform-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: var(--spacing-md);
  }

  .platform-card {
    background: var(--color-bg-surface);
    padding: var(--spacing-md);
    border-radius: 8px;
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
  }

  .platform-card h3 {
    color: var(--color-primary);
    margin-bottom: var(--spacing-sm);
    font-size: 1.5rem;
  }

  .platform-card p {
    color: var(--color-text-secondary);
    margin-bottom: var(--spacing-sm);
    line-height: 1.6;
  }
</style>
