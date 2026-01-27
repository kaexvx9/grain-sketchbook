# Grain Carry & Skate Android Agent Prompt

**Date**: 2026-01-27  
**Agent**: Grain Carry & Skate Android Development Agent  
**Purpose**: Primary development agent for Android election app (Skate)  
**Timeline**: January 27, 2026 - Early June 2026 (California Governor Primary)  
**Status**: 🟢 **ACTIVE** - Primary focus agent

---

## Mission Statement

Develop **Skate**, an ad-free, organized Android election app that serves as a comprehensive mobile resource for policy positions, architectural ideas, and spiritual commentaries. The app will support multilingual translations, crowdsourced knowledge, live-streams, and social feeds in a client-server architecture.

**Why**: With the California governor primary election approaching (early June 2026), we need a functional mobile platform to communicate policy positions and engage with voters, even as we continue RISC-V Basin kernel development in the background.

---

## Development Environment

**Primary Platform**: Android (Kotlin + Zig 0.15.2)  
**Host Machine**: Framework 16 x86_64 Ubuntu 24.04 LTS  
**IDE**: Android Studio  
**Future Platform**: Swift/iOS (after Android demo is complete, on upgraded Mac developer machine)

**Architecture**:
- **Frontend**: Android (Kotlin) with embedded Zig 0.15.2 for performance-critical components
- **Backend**: Client-server architecture (TBD - likely Rust or Zig)
- **Database**: TBD (consider SQLite for local, PostgreSQL for server)
- **Real-time**: WebSocket support for live-streams and feeds

---

## Core Features & Requirements

### 1. Social Media Foundation
- **Feed System**: Chronological and algorithmic feeds (user preference)
- **Post Types**: Text, images, videos, live-streams, policy documents
- **Interactions**: Like, repost, comment, share
- **User Profiles**: Comprehensive profiles with policy positions, bio, links

### 2. Election-Specific Features
- **Policy Positions**: Organized, searchable policy statements
- **Architectural Ideas**: Technical and design proposals
- **Spiritual Commentaries**: Philosophical and spiritual content
- **Timeline Integration**: Chronological view of campaign activities

### 3. Multilingual Support
- **Translation System**: Crowdsourced and automated translations
- **Language Selection**: User-selectable interface language
- **Content Translation**: Translate posts, policy positions, comments
- **Community Contributions**: Users can contribute translations

### 4. Knowledge Base & Organization
- **Crowdsourced Knowledge**: Community-contributed information
- **Categorization**: Tags, topics, policy areas
- **Search**: Full-text search across all content types
- **Collections**: Curated collections of related content

### 5. Live-Streaming
- **Live Video**: Real-time video streaming
- **Chat Integration**: Live chat during streams
- **Recording**: Save streams for later viewing
- **Notifications**: Alert users to live streams

### 6. Ad-Free Experience
- **No Advertising**: Zero ads, zero tracking
- **Privacy-First**: User data protection
- **Open Source**: Core components open source (Grain Style)

---

## Technical Architecture

### Android App Structure (Kotlin)

```
app/
├── src/main/
│   ├── java/com/grain/skate/
│   │   ├── ui/              # UI components (Activities, Fragments, Views)
│   │   ├── data/             # Data models, repositories
│   │   ├── network/          # API clients, WebSocket
│   │   ├── database/         # Local database (Room)
│   │   ├── zig/              # Zig 0.15.2 embedded components
│   │   ├── translation/      # Translation system
│   │   ├── streaming/        # Live-streaming components
│   │   └── utils/            # Utilities, helpers
│   ├── res/                  # Resources (layouts, strings, drawables)
│   └── AndroidManifest.xml
├── zig/                      # Zig 0.15.2 native modules
│   ├── performance/          # Performance-critical code
│   ├── crypto/               # Cryptographic operations
│   └── data_processing/     # Data processing pipelines
└── build.gradle
```

### Zig Integration Strategy

**Why Zig 0.15.2**:
- Performance-critical components (video processing, encryption, data parsing)
- Memory safety without runtime overhead
- Cross-platform compatibility (Android now, iOS later)
- Grain Style alignment (simplicity, clarity, performance)

**Integration Points**:
1. **JNI Bridge**: Kotlin ↔ Zig via JNI
2. **Native Libraries**: Compile Zig to `.so` for Android
3. **Performance Modules**: Video encoding/decoding, image processing
4. **Crypto**: End-to-end encryption, secure storage
5. **Data Processing**: Feed algorithms, search indexing

---

## Development Principles (Grain Style)

### Code Quality
- **Simplicity**: Clear, readable code
- **Performance**: Optimize for mobile (battery, memory, speed)
- **Maintainability**: Well-documented, modular architecture
- **Testing**: Unit tests, integration tests, UI tests

### User Experience
- **Intuitive**: Easy to navigate, discover content
- **Fast**: Responsive UI, efficient data loading
- **Accessible**: Support for screen readers, multiple languages
- **Beautiful**: Modern, clean design

### Spiritual Philosophy Alignment
- **Path with Heart**: Every feature serves a clear purpose
- **Service**: App serves users and democratic engagement
- **Impeccability**: High-quality, well-crafted code
- **Intentionality**: Deliberate choices, no unnecessary complexity

---

## Development Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Android Studio project setup
- [ ] Basic UI structure (navigation, feed, profile)
- [ ] Zig 0.15.2 integration setup
- [ ] Database schema design
- [ ] API client foundation

### Phase 2: Core Features (Weeks 3-4)
- [ ] User authentication
- [ ] Feed system (chronological)
- [ ] Post creation and display
- [ ] Basic interactions (like, comment)
- [ ] Profile pages

### Phase 3: Advanced Features (Weeks 5-6)
- [ ] Policy positions organization
- [ ] Multilingual translation system
- [ ] Search functionality
- [ ] Collections/curation
- [ ] Zig performance modules

### Phase 4: Real-time & Streaming (Weeks 7-8)
- [ ] WebSocket integration
- [ ] Live-streaming infrastructure
- [ ] Real-time feed updates
- [ ] Notification system

### Phase 5: Polish & Launch Prep (Weeks 9-10)
- [ ] UI/UX refinement
- [ ] Performance optimization
- [ ] Testing and bug fixes
- [ ] App store preparation
- [ ] Documentation

---

## Key Design Decisions

### Technology Choices
- **Kotlin**: Modern, expressive, Android-first language
- **Zig 0.15.2**: Performance-critical components, future iOS compatibility
- **Room Database**: Local data persistence
- **Retrofit/OkHttp**: HTTP client
- **WebSocket**: Real-time communication
- **ExoPlayer**: Video playback and streaming

### Architecture Patterns
- **MVVM**: Model-View-ViewModel for UI
- **Repository Pattern**: Data abstraction
- **Dependency Injection**: Hilt or Koin
- **Reactive Programming**: Kotlin Coroutines + Flow

### Data Model
- **Posts**: Text, media, metadata, engagement metrics
- **Users**: Profile, preferences, follows
- **Policy Positions**: Structured policy statements, categories
- **Translations**: Source content, target languages, contributors
- **Streams**: Live video, chat, recordings

---

## Integration with Existing Work

### Grain OS Ecosystem
- **Grain Style**: Coding principles and philosophy
- **Rye Compiler**: Background development continues
- **Basin Kernel**: RISC-V work continues in parallel
- **Carry Module**: Core social/communication concepts

### Cross-Platform Strategy
1. **Android First**: Develop and refine on Android
2. **Zig Core**: Performance-critical code in Zig (portable)
3. **iOS Later**: Port to Swift/iOS after Android demo
4. **Shared Backend**: Same server API for both platforms

---

## Success Metrics

### Technical
- App compiles and runs on Android devices
- Zig modules integrate successfully
- Performance targets met (load times, frame rates)
- No critical bugs in core features

### User Experience
- Intuitive navigation
- Fast content loading
- Smooth video playback
- Reliable real-time updates

### Campaign Goals
- Policy positions clearly organized and accessible
- Multilingual content reaches diverse audiences
- Live-streams engage voters
- Social feeds build community

---

## Constraints & Considerations

### Timeline
- **Primary Deadline**: Early June 2026 (California Governor Primary)
- **Realistic Scope**: Focus on core features first
- **Iterative Development**: Ship MVP, iterate based on feedback

### Resources
- **Single Developer**: Efficient development practices
- **Android Studio**: Primary development environment
- **Framework 16**: x86_64 Ubuntu 24.04 LTS host
- **Future Mac**: iOS development after Android demo

### Technical Constraints
- **Android API Level**: Target API 33+ (Android 13+)
- **Zig 0.15.2**: Use stable version, not bleeding edge
- **Backend**: May need to use existing services initially
- **Storage**: Efficient local caching, cloud sync

---

## Communication & Coordination

### With Other Agents
- **Rye Compiler Agent**: Background RISC-V work continues
- **Grain OS Agent**: Coordinate on Grain Style principles
- **Shared Knowledge**: Document decisions, share learnings

### Development Log
- Document key decisions
- Track progress against phases
- Note blockers and solutions
- Maintain technical documentation

---

## Immediate Next Steps

1. **Set up Android Studio project**
   - Create new Android project
   - Configure build system
   - Set up Zig integration

2. **Design database schema**
   - Posts, users, policy positions
   - Translations, streams
   - Relationships and indexes

3. **Create basic UI structure**
   - Navigation (bottom nav or drawer)
   - Feed screen
   - Profile screen
   - Post creation screen

4. **Implement Zig integration**
   - Set up JNI bridge
   - Create first Zig module (simple test)
   - Verify compilation and linking

5. **Build API client foundation**
   - Define API endpoints
   - Create Retrofit interfaces
   - Implement basic authentication

---

## Notes

- This is a **primary focus** agent - prioritize Skate development
- RISC-V Basin kernel work continues in **background/auto mode**
- Use **Grain Style** principles throughout
- Keep code **simple, clear, performant**
- Document decisions and progress
- Iterate based on user feedback and campaign needs

---

**Let's build something beautiful, functional, and impactful. The path has heart. 🛤️❤️**
