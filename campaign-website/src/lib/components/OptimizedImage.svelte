<script>
  // Optimized image component with lazy loading and responsive images
  
  export let src: string;
  export let alt: string;
  export let width?: number;
  export let height?: number;
  export let loading: 'lazy' | 'eager' = 'lazy';
  export let sizes?: string = '100vw';
  
  // Generate srcset for responsive images
  // In production, you'd generate these at build time
  const srcset = $derived(
    src.endsWith('.jpg') || src.endsWith('.jpeg')
      ? `${src.replace('.jpg', '-400w.jpg')} 400w, ${src.replace('.jpg', '-800w.jpg')} 800w, ${src.replace('.jpg', '-1200w.jpg')} 1200w`
      : undefined
  );
</script>

<picture>
  <!-- AVIF format (best compression) -->
  <source 
    srcset={srcset?.replace(/\.jpg/g, '.avif')} 
    type="image/avif"
    sizes={sizes}
  />
  <!-- WebP format (good compression) -->
  <source 
    srcset={srcset?.replace(/\.jpg/g, '.webp')} 
    type="image/webp"
    sizes={sizes}
  />
  <!-- Fallback to original -->
  <img 
    src={src}
    srcset={srcset}
    sizes={sizes}
    alt={alt}
    width={width}
    height={height}
    loading={loading}
    decoding="async"
    class="optimized-image"
  />
</picture>

<style>
  .optimized-image {
    max-width: 100%;
    height: auto;
    display: block;
  }
</style>
