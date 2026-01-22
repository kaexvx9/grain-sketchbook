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
  import ThemeToggle from './lib/components/ThemeToggle.svelte';
  import VisionHero from './lib/components/vision/VisionHero.svelte';
  import PermacultureSection from './lib/components/vision/PermacultureSection.svelte';
  import TraditionalUrbanismSection from './lib/components/vision/TraditionalUrbanismSection.svelte';
  import TechnologySection from './lib/components/vision/TechnologySection.svelte';
  import JobGuaranteeSection from './lib/components/vision/JobGuaranteeSection.svelte';
  import RegionalSection from './lib/components/vision/RegionalSection.svelte';
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
  <ThemeToggle />
  <Header />
  <main id="home">
    <Hero />
    
    <AboutSection />
    
    <!-- Vision Section with Custom SVGs -->
    <section id="vision" class="vision-section">
      <VisionHero />
      <PermacultureSection />
      <TraditionalUrbanismSection />
      <TechnologySection />
      <JobGuaranteeSection />
      <RegionalSection />
      
      <Section>
        <h2>The Vision in Action</h2>
        <p>This is a practical proposal that draws on principles that have worked for centuries, combined with technologies that are emerging right now.</p>
        <p>It's about making things whole again. Making things that heal and regenerate. Making things that are free and accessible to everyone. Making things that belong to communities. Making things that are open-source and transparent. Making things that last—truly permanent, built to serve generations to come.</p>
        
        <div class="cta-box">
          <p class="cta-slogan"><strong>risk love</strong></p>
          <p class="cta-tagline">Elegant simplicity with compassionate purpose</p>
        </div>
      </Section>
    </section>
    
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

  .vision-section {
    /* Vision sections flow naturally */
  }

  .cta-box {
    text-align: center;
    padding: var(--spacing-lg);
    background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-secondary) 100%);
    border-radius: 12px;
    color: var(--color-text-inverse);
    margin-top: var(--spacing-lg);
  }

  .cta-slogan {
    font-size: 3rem;
    font-weight: 700;
    margin-bottom: var(--spacing-sm);
  }

  .cta-tagline {
    font-size: 1.5rem;
    opacity: 0.95;
    margin: 0;
  }

  @media (max-width: 767px) {
    .cta-slogan {
      font-size: 2rem;
    }

    .cta-tagline {
      font-size: 1.25rem;
    }
  }

  .app {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  main {
    flex: 1;
  }
</style>
