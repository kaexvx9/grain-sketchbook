<script>
  // Color scheme demo component for testing
  // Shows all colors in the palette
</script>

<section class="color-demo">
  <div class="container">
    <h2>Color Palette Demo</h2>
    
    <div class="color-grid">
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-primary);"></div>
        <h3>Primary Orange</h3>
        <code>var(--color-primary)</code>
        <p>Sunset orange - CTAs, links, highlights</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-secondary);"></div>
        <h3>Secondary Green</h3>
        <code>var(--color-secondary)</code>
        <p>Seafoam green - Success, permaculture</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-tertiary);"></div>
        <h3>Tertiary Beige</h3>
        <code>var(--color-tertiary)</code>
        <p>Sand beige - Borders, subtle accents</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-bg);"></div>
        <h3>Background</h3>
        <code>var(--color-bg)</code>
        <p>Main background color</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-bg-surface);"></div>
        <h3>Surface</h3>
        <code>var(--color-bg-surface)</code>
        <p>Card/surface background</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-text);"></div>
        <h3>Text</h3>
        <code>var(--color-text)</code>
        <p>Primary text color</p>
      </div>
      
      <!-- Light Mode: Darker Green-Blues -->
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-green-blue-dark);"></div>
        <h3>Green-Blue Dark</h3>
        <code>var(--color-green-blue-dark)</code>
        <p>Deep teal-green (light mode)</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-green-blue-accent);"></div>
        <h3>Green-Blue Accent</h3>
        <code>var(--color-green-blue-accent)</code>
        <p>Teal accent (light mode)</p>
      </div>
    </div>
    
    <!-- Dark Mode Colors (shown conditionally) -->
    <div class="color-grid dark-mode-colors">
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-purple-rose-light);"></div>
        <h3>Purple-Rose Light</h3>
        <code>var(--color-purple-rose-light)</code>
        <p>Light mauve-rose (dark mode)</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-purple-rose-accent);"></div>
        <h3>Purple-Rose Accent</h3>
        <code>var(--color-purple-rose-accent)</code>
        <p>Mauve accent (dark mode)</p>
      </div>
      
      <div class="color-card">
        <div class="color-swatch" style="background: var(--color-purple-rose-pale);"></div>
        <h3>Purple-Rose Pale</h3>
        <code>var(--color-purple-rose-pale)</code>
        <p>Pale rose highlight (dark mode)</p>
      </div>
    </div>
    
    <div class="button-demo">
      <h3>Button Styles</h3>
      <div class="button-group">
        <button class="button button-primary">Primary Button</button>
        <button class="button button-secondary">Secondary Button</button>
        <button class="button button-outline">Outline Button</button>
        <button class="button button-accent-green">Green-Blue Accent</button>
      </div>
      <div class="button-group dark-mode-only">
        <button class="button button-accent-purple">Purple-Rose Accent</button>
      </div>
    </div>
  </div>
</section>

<style>
  .color-demo {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg-alt);
  }

  .color-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: var(--spacing-md);
    margin: var(--spacing-md) 0;
  }

  .color-card {
    background: var(--color-bg-surface);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: var(--spacing-md);
    box-shadow: var(--shadow-sm);
  }

  .color-swatch {
    width: 100%;
    height: 120px;
    border-radius: 6px;
    margin-bottom: var(--spacing-sm);
    border: 1px solid var(--color-border);
  }

  .color-card h3 {
    font-size: 1.125rem;
    margin-bottom: var(--spacing-xs);
  }

  .color-card code {
    display: block;
    background: var(--color-bg-alt);
    padding: var(--spacing-xs);
    border-radius: 4px;
    font-size: 0.875rem;
    margin-bottom: var(--spacing-xs);
    color: var(--color-text-secondary);
  }

  .color-card p {
    font-size: 0.875rem;
    color: var(--color-text-secondary);
    margin: 0;
  }

  .button-demo {
    margin-top: var(--spacing-lg);
    padding: var(--spacing-md);
    background: var(--color-bg-surface);
    border-radius: 8px;
    border: 1px solid var(--color-border);
  }

  .button-group {
    display: flex;
    gap: var(--spacing-sm);
    flex-wrap: wrap;
    margin-top: var(--spacing-sm);
  }

  .dark-mode-colors {
    margin-top: var(--spacing-md);
    padding-top: var(--spacing-md);
    border-top: 2px dashed var(--color-border);
  }

  .dark-mode-only {
    display: none;
  }

  @media (prefers-color-scheme: dark) {
    .dark-mode-only {
      display: flex;
    }
    
    .dark-mode-colors {
      border-top-color: var(--color-border);
    }
  }
</style>
