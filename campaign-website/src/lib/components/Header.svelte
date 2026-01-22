<script>
  // Explicit state
  let menuOpen = $state(false);
  
  function toggleMenu() {
    menuOpen = !menuOpen;
  }
</script>

<header class="header">
  <div class="container">
    <nav class="nav">
      <a href="/" class="logo">
        <strong>Keaton Livermore</strong>
        <span class="tagline">for California Governor 2026</span>
      </a>
      
      <button class="menu-toggle" onclick={toggleMenu} aria-label="Toggle menu">
        <span></span>
        <span></span>
        <span></span>
      </button>
      
      <ul class="nav-links" class:open={menuOpen}>
        <li><a href="#home">Home</a></li>
        <li><a href="#about">About</a></li>
        <li><a href="#vision">Vision</a></li>
        <li><a href="#platform">Platform</a></li>
        <li><a href="#get-involved">Get Involved</a></li>
      </ul>
    </nav>
  </div>
</header>

<style>
  .header {
    background: var(--color-bg-surface);
    border-bottom: 1px solid var(--color-border);
    padding: var(--spacing-sm) 0;
    box-shadow: var(--shadow-sm);
  }

  .nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .logo {
    display: flex;
    flex-direction: column;
    font-size: 1.25rem;
  }

  .tagline {
    font-size: 0.875rem;
    color: var(--color-text-light);
    font-weight: normal;
  }

  .nav-links {
    display: flex;
    list-style: none;
    gap: var(--spacing-md);
  }

  .menu-toggle {
    display: none;
    flex-direction: column;
    gap: 4px;
    background: none;
    border: none;
    cursor: pointer;
    padding: var(--spacing-xs);
  }

  .menu-toggle span {
    width: 24px;
    height: 2px;
    background: var(--color-text);
  }

  @media (max-width: 767px) {
    .menu-toggle {
      display: flex;
    }

    .nav-links {
      display: none;
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      background: var(--color-bg-surface);
      flex-direction: column;
      padding: var(--spacing-sm);
      border-top: 1px solid var(--color-border);
      box-shadow: var(--shadow-md);
    }

    .nav-links.open {
      display: flex;
    }
  }
</style>
