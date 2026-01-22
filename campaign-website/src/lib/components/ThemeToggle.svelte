<script>
  import { onMount } from 'svelte';
  
  // Theme state: 'light', 'dark', or 'auto' (system preference)
  let theme = $state('auto');
  let systemPrefersDark = $state(false);
  
  onMount(() => {
    // Check localStorage for saved preference
    const saved = localStorage.getItem('theme');
    if (saved === 'light' || saved === 'dark') {
      theme = saved;
    }
    
    // Check system preference
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    systemPrefersDark = mediaQuery.matches;
    
    // Listen for system preference changes
    mediaQuery.addEventListener('change', (e) => {
      systemPrefersDark = e.matches;
      if (theme === 'auto') {
        applyTheme();
      }
    });
    
    applyTheme();
  });
  
  function toggleTheme() {
    // Cycle: auto -> light -> dark -> auto
    if (theme === 'auto') {
      theme = 'light';
    } else if (theme === 'light') {
      theme = 'dark';
    } else {
      theme = 'auto';
    }
    applyTheme();
  }
  
  function applyTheme() {
    let effectiveTheme = theme;
    if (theme === 'auto') {
      effectiveTheme = systemPrefersDark ? 'dark' : 'light';
    }
    
    // Remove existing theme attributes
    document.documentElement.removeAttribute('data-theme');
    document.documentElement.removeAttribute('data-palette');
    
    // Apply theme
    if (effectiveTheme === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
    }
    
    // Save preference
    localStorage.setItem('theme', theme);
  }
  
  // Get display text for tooltip
  let tooltipText = $derived(
    theme === 'auto' 
      ? `Theme: Auto (${systemPrefersDark ? 'Dark' : 'Light'}) - Click to set Light`
      : theme === 'light'
      ? 'Theme: Light - Click to set Dark'
      : 'Theme: Dark - Click to set Auto'
  );
</script>

<button 
  on:click={toggleTheme}
  class="theme-toggle"
  aria-label="Toggle theme"
  title={tooltipText}
>
  *
</button>

<style>
  .theme-toggle {
    position: fixed;
    top: 20px;
    /* Align with right edge of content, responsive */
    right: max(calc((100vw - var(--container-max-width)) / 2), 1rem);
    background: none;
    border: none;
    color: var(--color-text);
    font-size: 28px;
    cursor: pointer;
    padding: 8px 12px;
    line-height: 1;
    opacity: 0.6;
    transition: opacity 0.2s ease, transform 0.2s ease, color 0.2s ease;
    font-family: 'Times New Roman', serif;
    z-index: 1000;
    user-select: none;
  }
  
  .theme-toggle:hover {
    opacity: 1;
    transform: scale(1.2);
    color: var(--color-primary);
  }
  
  .theme-toggle:active {
    transform: scale(1.1);
  }
  
  .theme-toggle:focus {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
    border-radius: 4px;
  }
  
  /* Mobile adjustment */
  @media (max-width: 768px) {
    .theme-toggle {
      right: 0.5rem;
      top: 0.5rem;
      font-size: 24px;
      padding: 6px 10px;
    }
  }
  
  /* Adjust for header if it overlaps */
  @media (max-width: 640px) {
    .theme-toggle {
      top: 60px; /* Below mobile header */
    }
  }
</style>
