<script>
  import Stub from './Stub.svelte';
</script>

<section id="get-involved" class="get-involved-section">
  <div class="container">
    <h2>Get Involved</h2>
    
    <div class="involved-grid">
      <div class="involved-card">
        <h3>Volunteer</h3>
        <p>Join our team of volunteers. Help with content creation, social media, events, and more.</p>
        <Stub message="Volunteer sign-up form coming soon" />
        <button class="button button-primary" disabled>Sign Up to Volunteer</button>
      </div>
      
      <div class="involved-card">
        <h3>Donate</h3>
        <p>Support the campaign financially. Every contribution helps us reach more Californians.</p>
        <Stub message="Donation platform integration coming soon" />
        <button class="button button-secondary" disabled>Donate Now</button>
      </div>
      
      <div class="involved-card">
        <h3>Contact</h3>
        <p>Have questions? Want to get in touch? We'd love to hear from you.</p>
        <Stub message="Contact form coming soon" />
        <button class="button button-outline" disabled>Contact Us</button>
      </div>
    </div>
  </div>
</section>

<style>
  .get-involved-section {
    padding: var(--spacing-lg) 0;
    background: var(--color-bg-alt);
  }

  .get-involved-section h2 {
    text-align: center;
    margin-bottom: var(--spacing-lg);
    font-size: 2.5rem;
  }

  .involved-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: var(--spacing-md);
  }

  .involved-card {
    background: var(--color-bg-surface);
    padding: var(--spacing-md);
    border-radius: 8px;
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
    display: flex;
    flex-direction: column;
  }

  .involved-card h3 {
    color: var(--color-primary);
    margin-bottom: var(--spacing-sm);
    font-size: 1.5rem;
  }

  .involved-card p {
    color: var(--color-text-secondary);
    line-height: 1.6;
    margin-bottom: var(--spacing-md);
    flex: 1;
  }

  .involved-card .button {
    width: 100%;
    margin-top: auto;
  }

  .involved-card .button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
