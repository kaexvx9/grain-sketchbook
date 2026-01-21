<script>
  // Video placeholder component
  // Shows thumbnail, loads YouTube embed on click
  
  export let youtubeId: string;
  export let thumbnail: string;
  export let title: string = '';
  export let aspectRatio: string = '16/9';
  
  let isLoaded = $state(false);
  let showEmbed = $state(false);
  
  function handleClick() {
    showEmbed = true;
    isLoaded = true;
  }
  
  function handleLinkClick(e: Event) {
    // Allow link to work normally
    e.stopPropagation();
  }
</script>

<div class="video-placeholder" style="aspect-ratio: {aspectRatio};">
  {#if !showEmbed}
    <div class="video-thumbnail" onclick={handleClick} role="button" tabindex="0" onkeydown={(e) => e.key === 'Enter' && handleClick()}>
      <img 
        src={thumbnail} 
        alt={title || 'Video thumbnail'}
        loading="lazy"
        decoding="async"
      />
      <div class="play-overlay">
        <svg class="play-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10" stroke-width="2"/>
          <path d="M10 8l6 4-6 4V8z" fill="currentColor"/>
        </svg>
        <span class="play-text">Play Video</span>
      </div>
    </div>
  {:else}
    <div class="video-embed">
      <iframe
        src="https://www.youtube.com/embed/{youtubeId}?autoplay=1"
        title={title || 'Video'}
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
        loading="lazy"
      ></iframe>
    </div>
  {/if}
  
  <div class="video-links">
    <a 
      href="https://www.youtube.com/watch?v={youtubeId}" 
      target="_blank" 
      rel="noopener noreferrer"
      onclick={handleLinkClick}
      class="video-link"
    >
      Watch on YouTube
    </a>
  </div>
</div>

<style>
  .video-placeholder {
    position: relative;
    width: 100%;
    background: var(--color-bg-muted);
    border-radius: 8px;
    overflow: hidden;
    border: 1px solid var(--color-border);
  }

  .video-thumbnail {
    position: relative;
    width: 100%;
    height: 100%;
    cursor: pointer;
    transition: transform 0.2s ease;
  }

  .video-thumbnail:hover {
    transform: scale(1.02);
  }

  .video-thumbnail:focus {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }

  .video-thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  .play-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: rgba(0, 0, 0, 0.4);
    color: white;
    transition: background 0.2s ease;
  }

  .video-thumbnail:hover .play-overlay {
    background: rgba(0, 0, 0, 0.6);
  }

  .play-icon {
    width: 64px;
    height: 64px;
    margin-bottom: var(--spacing-xs);
  }

  .play-text {
    font-weight: 600;
    font-size: 1.125rem;
  }

  .video-embed {
    position: relative;
    width: 100%;
    height: 0;
    padding-bottom: 56.25%; /* 16:9 aspect ratio */
  }

  .video-embed iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
  }

  .video-links {
    padding: var(--spacing-sm);
    text-align: center;
    background: var(--color-bg-surface);
    border-top: 1px solid var(--color-border);
  }

  .video-link {
    color: var(--color-primary);
    font-size: 0.875rem;
    text-decoration: none;
  }

  .video-link:hover {
    text-decoration: underline;
  }
</style>
