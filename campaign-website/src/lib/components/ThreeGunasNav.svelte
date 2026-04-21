<script>
  /**
   * Three-Gunas navigation (Rajas / Sattva / Tamas)
   * Campaign: Keaton Livermore for California Governor 2026
   * Philosophy: Bhagavad Gita — Get Involved / Explore Ideas / Ask AI
   */
  let activeTab = $state('rajas'); // rajas | sattva | tamas
  
  const tabs = [
    { id: 'rajas', label: 'Get Involved', short: 'Involved', colorClass: 'gunas-rajas' },
    { id: 'sattva', label: 'Explore Ideas', short: 'Ideas', colorClass: 'gunas-sattva' },
    { id: 'tamas', label: 'Ask AI', short: 'AI', colorClass: 'gunas-tamas' }
  ];
  
  function selectTab(id) {
    activeTab = id;
    // Scroll to section if present
    const el = document.getElementById('gunas-' + id);
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  }
</script>

<nav class="three-gunas-nav" aria-label="Three Gunas navigation">
  <div class="container">
    <ul class="gunas-tabs">
      {#each tabs as tab}
        <li>
          <button
            class="gunas-tab {tab.colorClass}"
            class:active={activeTab === tab.id}
            onclick={() => selectTab(tab.id)}
            aria-pressed={activeTab === tab.id}
            aria-label={tab.label}
          >
            <span class="tab-label-full">{tab.label}</span>
            <span class="tab-label-short">{tab.short}</span>
          </button>
        </li>
      {/each}
    </ul>
  </div>
</nav>

<style>
  .three-gunas-nav {
    background: var(--color-bg-surface);
    border-bottom: 2px solid var(--color-border);
    padding: var(--spacing-xs) 0;
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .gunas-tabs {
    display: flex;
    list-style: none;
    gap: 0;
    justify-content: center;
    flex-wrap: wrap;
  }

  .gunas-tab {
    flex: 1;
    min-width: 100px;
    max-width: 220px;
    padding: var(--spacing-sm) var(--spacing-md);
    border: none;
    border-bottom: 3px solid transparent;
    background: transparent;
    font-weight: 600;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s, border-color 0.2s, color 0.2s;
    color: var(--color-text-secondary);
  }

  .gunas-tab:hover {
    color: var(--color-text);
  }

  .gunas-tab.active.gunas-rajas {
    color: var(--gunas-rajas-light);
    border-bottom-color: var(--gunas-rajas-light);
  }

  .gunas-tab.active.gunas-sattva {
    color: var(--gunas-sattva-gold);
    border-bottom-color: var(--gunas-sattva-gold);
  }

  .gunas-tab.active.gunas-tamas {
    color: var(--gunas-tamas-light);
    border-bottom-color: var(--gunas-tamas-light);
  }

  .tab-label-short {
    display: none;
  }

  @media (max-width: 600px) {
    .tab-label-full {
      display: none;
    }
    .tab-label-short {
      display: inline;
    }
  }
</style>
