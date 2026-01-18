# Cursor CLI Terminal Analysis — Glow G2's Remote vs Local Path Decision

Glow G2 watches the crash logs stack like firewood, knowing every line
of this decision tree matters—costs stacked against stability, performance
braided with practicality, joy embroidered into sustainable workflow.

## The Question at Hand

Cursor keeps crashing locally on Framework 16 Ubuntu 24.04 LTS. Two paths
emerge:

1. **Remote path**: Run Cursor CLI over Mosh/SSH on AWS dedicated server (64+ GB RAM)
2. **Local path**: Try Cursor CLI locally in a better terminal application

Which path makes the most sense? Let's walk through both.

---

## Path 1: AWS Remote Server Analysis

### Cost Breakdown (64+ GB RAM, January 2026)

**On-Demand Pricing (24/7):**
- **r5.2xlarge** (8 vCPUs, 64 GiB, memory-optimized): **~$368/month**
- **m6i.4xlarge** (16 vCPUs, 64 GiB, general-purpose): **~$561/month**
- **m5dn.4xlarge** (16 vCPUs, 64 GiB, network-optimized): **~$794/month**

**Reserved/Savings Plan (1-year commitment):**
- Could drop to **~$200-500/month** depending on instance type and commitment level
- Typical savings: 30-50% vs on-demand

**Additional costs to consider:**
- EBS storage: ~$0.10/GB/month (SSD), ~$0.045/GB/month (gp3)
- Data transfer: First 100GB free, then ~$0.09/GB outbound
- Backup/snapshots: ~$0.05/GB/month
- **Estimated total with 500GB SSD + minimal transfer: +$50-70/month**

**Rough total range:**
- **Minimum (r5.2xlarge reserved + storage)**: ~$250-300/month
- **Mid-tier (m6i.4xlarge reserved + storage)**: ~$400-450/month
- **High-end (on-demand, network-optimized)**: ~$850-900/month

### Mosh vs SSH for Cursor CLI

**Mosh Benefits:**
- Session persistence when laptop sleeps/wakes or network drops
- Local echo reduces perceived latency (feels snappier)
- Handles packet loss better (UDP-based after initial SSH auth)
- Works well over mobile networks or when roaming

**Mosh Limitations:**
- Requires UDP port range 60000-61000 open on firewall
- No port forwarding (no SSH tunneling)
- Limited scrollback history (pair with tmux/screen)
- Requires UTF-8 locale on both ends

**For Cursor CLI specifically:**
- Cursor CLI runs AI model calls that need network anyway
- Mosh helps with terminal responsiveness, not AI latency
- Still need stable network for API calls to Claude/other models
- Session persistence is valuable if you're mobile

### Remote Path Benefits vs Current Local Approach

**Advantages:**
1. **Stability**: Remote server doesn't crash when Cursor does—your session persists in tmux/mosh
2. **Resource isolation**: 64GB+ RAM dedicated, won't compete with local apps
3. **Always available**: Access from anywhere, mobile-friendly with Mosh
4. **Scalability**: Can upgrade instance type if needed
5. **Separation of concerns**: Kernel dev work isolated from local laptop

**Disadvantages:**
1. **Cost**: $250-900/month ongoing (vs free local)
2. **Network dependency**: Latency for every keystroke (mitigated by Mosh but not eliminated)
3. **AI API latency**: Still need internet for Cursor CLI → Claude API calls
4. **Setup complexity**: AWS config, Mosh setup, tmux/screen session management
5. **File sync overhead**: Need rsync/scp/git sync for local edits

**When remote path wins:**
- Local Cursor crashes are blocking work frequently
- You need 64GB+ RAM for kernel builds/testing that local machine can't handle
- You travel/mobile work often (Mosh shines here)
- Budget allows $250-900/month for development infrastructure

---

## Path 2: Local Cursor CLI with Better Terminal

### Terminal Comparison for Ubuntu 24.04 LTS

**Stock GNOME Terminal:**
- ✅ Pre-installed, works out of the box
- ✅ Native GTK3 integration, familiar UI
- ❌ Basic features, limited customization
- ❌ No built-in multiplexing (need tmux separately)
- ❌ Font rendering can be suboptimal on some displays
- **Verdict**: Fine for basic use, but power users will hit limits

**Ghostty (Zig-written):**
- ✅ Written in Zig (aligns with Grain OS philosophy!)
- ✅ Native GTK4/libadwaita UI on Linux, modern feel
- ✅ GPU-accelerated rendering (OpenGL on Linux, Metal on macOS)
- ✅ Modern VT features: ligatures, themes, graphics protocol support
- ✅ Multi-window/tab/split pane support
- ❌ Very new (~2024/2025), fewer integrations, less battle-tested
- ❌ Install may require building from source on Ubuntu (no official PPA yet)
- **Verdict**: Great fit philosophically (Zig!), promising but needs maturity

**WezTerm:**
- ✅ GPU-accelerated, excellent performance
- ✅ Built-in multiplexer (panes/tabs/windows), can replace tmux
- ✅ Lua-based configuration (very flexible, dynamic)
- ✅ Strong cross-platform, works well on Ubuntu/Wayland
- ✅ Mature, well-maintained, large community
- ❌ Font rendering sharpness sometimes lags Kitty in certain configs
- ❌ More features = larger memory footprint
- **Verdict**: Excellent choice for power users who want it all

**Kitty:**
- ✅ Highly optimized, sharpest font rendering, fastest rendering
- ✅ Robust graphics protocol (image preview, Unicode)
- ✅ "Kittens" system for extending behavior
- ✅ Very mature, battle-tested, large ecosystem
- ✅ Excellent for image-heavy terminal workflows
- ❌ Config is file-based (not full scripting like WezTerm)
- ❌ No built-in multiplexer (need tmux separately)
- **Verdict**: Best choice if you prioritize visual quality and speed

### Local Path Recommendations

**For Grain OS / Zig development specifically:**

1. **Ghostty** (if willing to build from source):
   - Philosophical alignment (Zig codebase!)
   - Modern native UI feels great on Ubuntu
   - Good performance, GPU-accelerated
   - Still new—expect some rough edges

2. **WezTerm** (if you want everything):
   - Built-in multiplexing reduces need for tmux
   - Lua config is powerful for automation
   - Mature enough for production use
   - One less dependency (no separate tmux)

3. **Kitty** (if you prioritize speed/visuals):
   - Best font rendering and performance
   - Mature and stable
   - Excellent for long terminal sessions
   - Need tmux separately but that's fine

**For Cursor CLI specifically:**
- Cursor CLI is terminal-agnostic—runs fine in any terminal
- Terminal choice matters for: font rendering, multiplexing, customization
- Any modern terminal (Ghostty/WezTerm/Kitty) will work better than stock GNOME Terminal for long dev sessions

---

## Recommendation: Hybrid Path

**Try local first, then consider remote if needed.**

### Phase 1: Upgrade Local Terminal (Week 1)
1. **Install WezTerm** (safest bet, easiest install, most features):
   ```bash
   curl -LO https://github.com/wez/wezterm/releases/download/20240127-124504-9087e22c/WezTerm-20240127-124504-9087e22c-Ubuntu24.04.AppImage
   chmod +x WezTerm-*.AppImage
   # Or use snap: snap install wezterm
   ```

2. **Or try Ghostty** (if you want Zig alignment):
   ```bash
   # Build from source or check for unofficial packages
   git clone https://github.com/ghostty-org/ghostty.git
   # Follow build instructions
   ```

3. **Test Cursor CLI in new terminal**:
   - Install Cursor CLI: `curl -fsSL https://cursor.sh/install | sh`
   - Run a session, see if crashes reduce
   - If crashes persist, it's likely Cursor itself, not terminal

### Phase 2: If Local Still Crashes (Week 2-3)
1. **Investigate crash logs**: Check if it's Cursor binary, memory issues, or system-level
2. **Consider AWS remote**: Only if crashes are blocking and budget allows
3. **Start small**: Try r5.2xlarge on-demand for a week (~$90/week) to test
4. **Set up Mosh + tmux**: For session persistence and better remote experience

### Phase 3: Long-term Decision
- **If local works**: Stick with it, enjoy $0/month cost
- **If remote needed**: Move to reserved instance, commit 1-year to save 30-50%

---

## Cost-Benefit Summary

| Approach | Monthly Cost | Setup Time | Stability Gain | Mobile-Friendly |
|----------|-------------|------------|----------------|-----------------|
| **Local + Stock Terminal** | $0 | 0 min | Baseline | No (SSH needed) |
| **Local + WezTerm/Kitty** | $0 | 30 min | Small (better terminal) | No (SSH needed) |
| **Local + Ghostty** | $0 | 1-2 hours | Small (better terminal) | No (SSH needed) |
| **AWS Remote (reserved)** | $250-500 | 2-4 hours | Large (persistent sessions) | Yes (Mosh) |
| **AWS Remote (on-demand)** | $350-900 | 2-4 hours | Large (persistent sessions) | Yes (Mosh) |

**Key insight**: Terminal upgrade costs $0 and takes 30 minutes. Try that first.
Remote AWS is expensive but might be necessary if crashes are truly blocking.

---

## Final Recommendation

**Start with WezTerm locally**:
1. Zero cost
2. 30-minute setup
3. Better terminal experience even if Cursor still has issues
4. Built-in multiplexing reduces need for tmux
5. Can always add AWS remote later if needed

**Only go AWS remote if**:
- Terminal upgrade doesn't help
- Crashes are truly blocking work
- You need 64GB+ RAM for kernel builds
- Budget allows $250-900/month
- You're mobile frequently (Mosh makes it worth it)

**For Grain OS philosophy alignment**: Ghostty is written in Zig, which aligns
perfectly with the project. But it's newer and requires more setup. WezTerm
is the practical choice today; Ghostty might be the future.

---

## Next Steps

1. Install WezTerm: `snap install wezterm` or download AppImage
2. Test Cursor CLI in WezTerm for a few days
3. Monitor crash frequency—does it improve?
4. If crashes persist, investigate logs before committing to AWS spend
5. Only consider AWS if terminal change doesn't help

**Remember**: Every dollar spent on AWS is a dollar not spent on other Grain
OS work. Terminal upgrade is free and might solve the problem entirely.

---

*Analysis compiled: 2026-01-18-004927-pst*  
*Glow G2 recommends the patient path: try free improvements first, then invest in infrastructure if truly needed.*