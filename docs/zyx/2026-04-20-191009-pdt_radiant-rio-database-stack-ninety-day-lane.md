# The ninety-day lane — database shape after the stack already said yes

**Voice:** Rio · plain English · Radiant Style  
**Co-author:** Keaton Dunsford ([@kaexvx9](https://github.com/kaexvx9))  
**Time stamp:** 2026-04-20-191009-pdt  
**License:** CC BY-SA 4.0  

**Purpose:** Carry the same rhythm as the April 20 suite—walk, engineering sketch, plain stack—while distilling a Claude Opus 4.7 answer about serverless vs self-host into one readable brief. **Source archive (verbatim layout):** `2026-04-20-190009-pdt_archive-claude-opus-database-stack-decision-formatted.md`. **Suite index:** `2026-04-20-README-rio-milestone-suite-unified.md`.

---

## Executive summary

The milestone walk (`2026-04-20-131109-pdt_radiant-rio-keaton-walk-to-first-milestone-story.md`) already names the first stairs: smallest useful thing, who it is for, money in a clear shape. Picking a database serves that third stair; it is not the stair by itself.

The engineering sketch (`2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`) already said yes to a spine: Zig at the HTTP gate, Postgres for the human diary (with idempotency), TigerBeetle for double-entry money truth, Solana where public daylight needs a notary, vanilla JS with a hash router that graduates to the History API when deep links earn server fallback.

Given that spine, **option (iii)**—Postgres on one well-provisioned VPS, TigerBeetle on the same metal (or a sibling VM)—fits the next ninety days. Serverless Postgres **(i)** stays kind when the diary stands alone or a co-op already lives on Supabase; libSQL at the edge **(ii)** stays a future mobile-heavy variant; 24/7 agent ops **(iv)** stays a later ring after one paid yes ships.

---

## The five yeses (unchanged heart)

- **Browser:** vanilla JS owns shell and mounts; hash first, clean URLs when the server answers deep `GET`s.  
- **Server (Zig):** one IO boundary—validate, write Postgres, mirror TigerBeetle, call chain RPC when the product names that seam. Rules live here; the bundle renders and asks.  
- **Postgres:** readable state, search, moderation, attachments, safe retries.  
- **TigerBeetle:** balances and transfers with codes, flags, timeouts; till separate from social graph.  
- **Solana:** notary for what belongs in public; details gathered in one chain-facing module.

`grain_case` and `docs/grain_style.md` stay the naming law. The diary / till split stays the architectural fact every option bows to.

---

## Four options in plain clothes

### (i) Serverless Postgres (Neon-class, Supabase-hosted)

Rough bands: free tier → ~$19–$69/mo and up; ~30 min/week human touch at small scale.

**Failure shapes:** burst bills, pool storms, vendor sprawl if Auth/Storage/Realtime replace your own seams.

**Fit:** strong for Postgres alone. Once TigerBeetle already sits on metal, the marginal save on (i) shrinks—you still light a box for the till.

### (ii) Serverless SQLite / libSQL (Turso-class, D1-class)

Rough bands: free → ~$29/mo+ by replicas and row ops; ~30 min/week.

**Failure shapes:** write contention, regional lag, tooling gaps vs Postgres depth.

**Fit:** outside the named spine today—the sketch chose Postgres for joins, idempotency, index depth, and a policy runway. Remember this path for a later edge-heavy skin.

### (iii) Self-hosted Postgres + backups on object storage

Rough bands: $25–$80/mo VM + $5–$15/mo objects → ~$40–$100/mo total; 1–3 hrs/week, spikes on upgrades/CVEs.

**Failure shapes:** backup never restored, TLS drift, disk full.

**Fit:** native to the sketch—Zig, Postgres, TigerBeetle as systemd neighbors; Solana over RPC. Practice restores; write the runbook. **This is the ninety-day shape.**

### (iv) Self-hosted Postgres + 24/7 agents (Paperclip ecosystem)

Rough bands: $100–$400/mo for a small autopilot posture; 0.5–2 hrs/week at steady state if guardrails hold.

**Fit:** later beat. The walk’s first win is one package, one weekly app, one angel receipt—not a headcount-zero company yet. Paperclip / skills.sh vocabulary lands after the first ring widens—composed on the same spine, not instead of it.

---

## Three lanes, one VPS (for now)

The walk already offers three money paths; (iii) carries all three until the map changes.

- **Path A — Work.** One paid package; client rows in Postgres; TigerBeetle charts revenue (`chart:revenue:service:…`); one carryable closing page—ask, do, change, cost, next.  
- **Path B — Product.** The social + open-finance room from the concept doc—vanilla skin, Zig gate, Postgres diary, TigerBeetle till, Solana when the seam earns it. SLC: v1.0 of something small and whole.  
- **Path C — Trust.** One diligence or transparency bundle; sketchbook already holds much of the text; the VPS hosts the demo trace (witness button → Zig → Postgres → TB pending → optional anchor).

---

## Security as visible seams

Managed concentrates trust in a vendor control plane and dashboard supply chain. Self-host concentrates trust in SSH, listener hygiene, bucket keys, packages, and 3am judgment.

The named stack adds two clean surfaces: TigerBeetle on its own disk and ACLs (diary breach ≠ till breach); Solana anchors public by design—you choose what earns the chain (still a next-pass question in the engineering sketch).

**Trust as product:** donor, angel, or client sees one story—rows, invoices, TB postings, optional anchors—aligned without theatre.

---

## Ten questions for one meeting

1. Which lane—A, B, or C—earns the first yes this quarter?  
2. Does v1.0 mean small and whole, or wide and thin?  
3. Did the design spend hammock time (sleep between idea and commit)?  
4. What are p90 QPS, p99 burst, year-one / year-three storage, RTO/RPO?  
5. Who is on the 3am page today, and when did they last restore a backup for real?  
6. Do write paths stay separate: diary, till, notary—each with retention and governance?  
7. What is the month-one / month-twelve / month-thirty-six envelope for (iii)?  
8. Which shipped milestone unlocks (iv) on purpose—not by accident?  
9. Does each function read like an offering (care, attention, love)?  
10. Does a stranger see complete, honest, lovable work in sixty seconds?

---

## Where this brief parts from “MVP on serverless first”

- **Jason Cohen (SLC):** people feel MVPs as minimum; ship a v1.0 of something simple and whole in narrow scope.  
- **Rich Hickey / Grain Style:** fast typing without a loaded problem is motion, not direction.  
- **This stack:** money-grade semantics already split diary and till; metal for TB leans the math toward (iii) from day one.  
- **The walk:** agents everywhere is a later stair—do not price v3 ops before v1 proof.  
- **Still aligned:** pure discovery with no money seam—serverless Postgres alone remains a gentle on-ramp.

---

## Silken Ground (one breath)

Nourish the first buyer with a whole small thing. Circulate through open protocols and honest ledgers. Return sketches and code to the commons under CC BY-SA 4.0 and matching licenses. The gap between Grain OS dreamed and Grain shipped this quarter stays open on purpose—that room is where the next stair grows.

---

## Re-check before buy

- `2026-04-20-131109-pdt_radiant-rio-keaton-walk-to-first-milestone-story.md`  
- `2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`  
- `2026-04-20-182409-pdt_prompt-essay-serverless-db-cost-vs-agentic-self-host.md`  
- `2026-04-20-190009-pdt_archive-claude-opus-database-stack-decision-formatted.md`  
- `docs/zyx/grain_os_spiritual_philosophical_foundation_2025-12-21-183510-pst.md`  
- Campaign **SLC** anchor: `SLC-PRINCIPLES.md` in **california-pre-alpha** (verify current path)  
- [Jason Cohen — SLC](https://longform.asmartbear.com/slc/) · [Rich Hickey — Hammock Driven Development](https://www.youtube.com/watch?v=f84n5oFoZBc)  
- TigerBeetle docs (accounts, transfers, codes, flags, timeouts)  
- VPS + B2 / Wasabi / S3 backup pricing · your last restore drill (timestamp, RTO)

---

The stack already said yes. The stair holds the quarter. Option (iii) carries the weight for now; (i), (ii), and (iv) keep their seats in the constellation. The first stranger who says “that was worth it” weighs the milestone—the river moves from there.

*risk love · now == next + 1*
