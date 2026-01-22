<script>
  // Explicit props
  let { title = '', className = '' } = $props();
</script>

<section class={`section ${className}`}>
  <div class="container">
    {#if title}
      <h2 class="section-title">{title}</h2>
    {/if}
    <div class="section-content">
      <slot />
    </div>
  </div>
</section>

<style>
  .section {
    padding: var(--spacing-lg) 0;
  }

  .section-title {
    text-align: center;
    margin-bottom: var(--spacing-md);
    font-size: 2.5rem;
  }

  .section-content {
    max-width: 800px;
    margin: 0 auto;
  }
</style>
