<script>
  import { onMount } from 'svelte';
  import Header from './lib/components/Header.svelte';
  import Footer from './lib/components/Footer.svelte';
  import Hero from './lib/components/Hero.svelte';
  import Section from './lib/components/Section.svelte';
  import PlatformSection from './lib/components/PlatformSection.svelte';
  import AboutSection from './lib/components/AboutSection.svelte';
  import GetInvolvedSection from './lib/components/GetInvolvedSection.svelte';
  import SocialLinks from './lib/components/SocialLinks.svelte';
  import { initLazyLoading } from './lib/utils/lazyLoad.js';
  
  // Initialize lazy loading on mount
  onMount(() => {
    initLazyLoading();
  });
  
  // Social links - STUB: Replace with actual links when available
  // In production, load from config file or CMS
  const socialLinks = {
    // youtube: 'https://youtube.com/@keatonlivermore', // STUB: Add when channel exists
    // twitter: 'https://twitter.com/keatonlivermore', // STUB: Add when account exists
    // instagram: 'https://instagram.com/keatonlivermore', // STUB: Add when account exists
    // tiktok: 'https://tiktok.com/@keatonlivermore', // STUB: Add when account exists
    // threads: 'https://threads.net/@keatonlivermore', // STUB: Add when account exists
    // bluesky: 'https://bsky.app/profile/keatonlivermore.bsky.social', // STUB: Add when account exists
    // nostr: 'nostr:...', // STUB: Add when account exists
    // facebook: 'https://facebook.com/keatonlivermore', // STUB: Add when account exists
  };
</script>

<div class="app">
  <Header />
  <main>
    <Hero />
    
    <AboutSection />
    
    <PlatformSection />
    
    <Section>
      <h2>Connect With Us</h2>
      <p>Follow the campaign on social media for updates, videos, and more.</p>
      {#if Object.keys(socialLinks).length > 0}
        <SocialLinks links={socialLinks} />
      {:else}
        <div class="stub-notice">
          <p><em>Social media links will appear here once accounts are set up.</em></p>
        </div>
      {/if}
    </Section>
    
    <GetInvolvedSection />
  </main>
  <Footer />
</div>

<style>
  .stub-notice {
    padding: var(--spacing-md);
    background: var(--color-bg-muted);
    border: 1px dashed var(--color-border-medium);
    border-radius: 8px;
    text-align: center;
    color: var(--color-text-secondary);
    font-style: italic;
  }
</style>

<style>
  .app {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  main {
    flex: 1;
  }
</style>
