<script>
  // Stub component - makes it obvious when content is placeholder
  let { message = 'This is a placeholder/stub' } = $props();
</script>

<div class="stub">
  <div class="stub-indicator">STUB</div>
  <p class="stub-message">{message}</p>
</div>

<style>
  .stub {
    padding: var(--spacing-md);
    background: var(--color-bg-muted);
    border: 2px dashed var(--color-border-medium);
    border-radius: 8px;
    text-align: center;
    margin: var(--spacing-md) 0;
  }

  .stub-indicator {
    display: inline-block;
    background: var(--color-warning);
    color: var(--color-text-inverse);
    padding: var(--spacing-xs) var(--spacing-sm);
    border-radius: 4px;
    font-weight: 700;
    font-size: 0.75rem;
    letter-spacing: 0.1em;
    margin-bottom: var(--spacing-sm);
  }

  .stub-message {
    color: var(--color-text-secondary);
    font-style: italic;
    margin: 0;
  }
</style>
