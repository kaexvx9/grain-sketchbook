<footer class="footer">
  <div class="container">
    <div class="footer-content">
      <div class="footer-section">
        <h3>Campaign</h3>
        <p><strong>risk love</strong></p>
        <p>Elegant simplicity with compassionate purpose</p>
      </div>
      
      <div class="footer-section">
        <h3>Connect</h3>
        <ul>
          <li><a href="#get-involved">Get Involved</a></li>
          <li><a href="#about">About</a></li>
          <li><a href="#platform">Platform</a></li>
        </ul>
      </div>
      
      <div class="footer-section">
        <h3>Resources</h3>
        <ul>
          <li><a href="https://codeberg.org" target="_blank" rel="noopener">Code Repository</a></li>
          <li><a href="/docs" target="_blank" rel="noopener">Documentation</a></li>
          <li><a href="#get-involved">Contact</a></li>
        </ul>
      </div>
    </div>
    
    <div class="footer-bottom">
      <p>&copy; 2026 Keaton Livermore for California Governor. All rights reserved.</p>
      <p>Open source campaign. Code available on <a href="https://codeberg.org" target="_blank" rel="noopener">Codeberg</a>.</p>
    </div>
  </div>
</footer>

<style>
  .footer {
    background: var(--color-bg-alt);
    padding: var(--spacing-lg) 0 var(--spacing-md);
    margin-top: var(--spacing-lg);
    border-top: 1px solid var(--color-border);
  }

  .footer-content {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: var(--spacing-md);
    margin-bottom: var(--spacing-md);
  }

  .footer-section h3 {
    font-size: 1rem;
    margin-bottom: var(--spacing-sm);
  }

  .footer-section ul {
    list-style: none;
  }

  .footer-section li {
    margin-bottom: var(--spacing-xs);
  }

  .footer-bottom {
    border-top: 1px solid var(--color-border);
    padding-top: var(--spacing-md);
    text-align: center;
    font-size: 0.875rem;
    color: var(--color-text-muted);
  }

  .footer-bottom p {
    margin-bottom: var(--spacing-xs);
  }
</style>
