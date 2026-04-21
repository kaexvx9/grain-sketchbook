# Soltrade PBC — readable edition: pitch, business plan, and build spec (one document)

**Edition:** Readable (about **8th-grade to college** reading level; same three-part goal as the denser `2026-04-20-191509-pdt_soltrade-pbc-pitch-model-rfc-unified.md`.)  
**Placeholder public name:** Soltrade PBC (Delaware public benefit corporation; marketing name still open.)  
**Voice:** Rio · plain English · Radiant Style  
**Co-author:** Keaton Dunsford ([@kaexvx9](https://github.com/kaexvx9))  
**Time stamp:** 2026-04-20-201109-pdt  
**License:** CC BY-SA 4.0  

**Purpose:** One place for **money**, **story**, and **build rules**: Part I for people who fund; Part II for people who sell and buy; Part III for people who code and review contracts. **Appendices** hold a short integrity check you can read out loud.

**Suite index:** `2026-04-20-README-rio-milestone-suite-unified.md` · **Dense twin:** `2026-04-20-191509-pdt_soltrade-pbc-pitch-model-rfc-unified.md`

**Litetrade readable twin:** `2026-04-20-201109-pdt_litetrade-pbc-pitch-model-rfc-readable-edition.md` — alternate placeholder; **this** file remains the **Soltrade** URL anchor.

---

## Quick glossary (read once, skim later)

| Term | Short meaning |
|------|----------------|
| **PBC** | Public benefit corporation: the charter names who benefits in public; the company can still earn profit. |
| **SAFE** | Simple Agreement for Future Equity—a common early-investor contract shape (lawyer picks the final form). |
| **v1.0** | First public version that is **small**, **finished enough to trust**, and **pleasant to use** (Simple, Lovable, Complete—SLC). |
| **RFC** | “Request for comments”—Part III uses strict words (**MUST**, **SHOULD**, **MAY**, plus the RFC keyword for **forbidden**) so everyone points at the same line in review. |
| **ARPU** | Average revenue per user (used when Path B grows). |
| **CAC** | Customer acquisition cost (what you spend to win one paying customer). |

**Hammock (one line):** Load the problem, sleep, then pick the **smallest whole slice** you can ship with pride. Typing before thinking is movement; thinking first is direction.

---

# Part I — Angel funding pitch (outer ring)

## I.0 Why we rest before we raise

**Plain point:** Investors relax when a team can answer three things calmly: **What is the smallest first win?** **Who answers the phone if the database wakes you at 3 a.m.?** **What did we prove in a backup restore drill, on purpose, before we asked for money?**  

That calm is **substance**: clear intent, small sharp scopes, craft with care. It is the same spirit as **Grain style**—honest names, bounded work, love in the details.

## I.1 The invitation

Soltrade PBC makes software where **money matches speech**: people say what they mean in public, and the money trail reads beside the words—milestones, witnesses, receipts a kitchen table can trust. We seek capital to ship **one whole v1.0** in ninety days: the **smallest** offer that still feels **complete** and **lovable** (SLC). The **charter** states public benefit; the **kitchen** runs on for-profit discipline so we can hire and ship.

## I.2 The gap

Many tools host **talk**; many tools host **accounts**. Daily life mixes them: *we promised this, people witnessed it, money moved to match.* Soltrade offers **one honest room** for crews, co-ops, and diligence tables—one place where story and numbers agree.

## I.3 What Soltrade is (one breath)

A Delaware **public benefit corporation** using the placeholder name **Soltrade PBC**. It ships a **small web room**: promises in plain words, people who can witness, simple money actions (subscribe, split, tip, escrow), and a **carryable** closing page—what was asked, what was done, what changed, what it cost, what comes next.

**Three drawers, one story (for lawyers and angels):** the **diary** holds the human story; the **till** holds balanced money lines; the **notary** holds optional public stamps on the chain. **v1** shows money on screen and moves money only inside the rules we ship with lawyers—**custody at scale stays a later chapter** (see Part III, NG3).

**Name check:** “Sol” can sound like **Solana**; “trade” can sound like **exchange** talk. Ask **money-transmitter** and **securities** counsel for a **one-paragraph** read **before** the name hardens in decks. Until then, slides can use a **neutral** label (“the room,” “ledger room,” or a cleared name) so the **product heart** and the **placeholder sound** stay friends.

### Sidebar — witness button in four steps

What “money matches speech” looks like in one path (still plain):

1. **Browser** — user taps *witness*; the request carries an idempotency key (so double-clicks stay safe).  
2. **Gate (Zig)** — server checks the session; work is queued in order.  
3. **Diary (Postgres)** — the witness row appears for feeds and humans.  
4. **Till (TigerBeetle)** — when this beat includes money, a **pending** transfer carries the same milestone id; **notary (Solana)** joins **only** when policy already says so.

## I.4 Traction (honest)

Right now the proof lives in **grain-sketchbook**: stories, sketches, a build map a partner can read in an afternoon. **General-audience product revenue:** still ahead of us in this draft. **Next proof:** one paid lane (Part II) on real servers, plus a backup restore you could run tomorrow if you had to.

## I.5 The ask

| Field | Placeholder (lawyer + lead fill in) |
|--------|--------------------------------------|
| Instrument | SAFE or priced equity—**TBD** |
| Raise band | **$250k–$750k** pre-seed (**example** range, tighten later) |
| Runway target | **12–15 months** toward a shippable **v1** plus a **services cushion** so consulting work feeds the build |
| Lead profile | Angels or small funds who already care about **open ledgers**, **PBC governance**, and **California coalition** work |

**After the first Path A contract:** narrow the raise to **one or two** firm numbers angels can remember; revisit the budget lines—**services** may deserve **more** than **12%** once real costs arrive (the **20%** infra line buys discipline early; it can shift later).

## I.6 Use of funds (what people should see)

| Bucket | Share (example) | Outcome people can point at |
|--------|-----------------|-----------------------------|
| Engineering | 45% | Working room—sign-in, promises, witnesses, **one** money path with a receipt |
| Design + community | 15% | Screens people trust; witness flows that feel kind |
| Infra + security | 20% | Modest servers, **tested** backups, runbook with **named** owners |
| Services delivery | 12% | Path A / Path C work that **feeds** the product while the calendar still fits |
| Reserve | 8% | Legal, compliance, surprise tax |

## I.7 Milestones money unlocks

1. **M1 — Room opens:** signed-in users post promises and witnesses; backups run nightly; someone has **restored** a backup on purpose.  
2. **M2 — Money matches words:** **one** money path end-to-end (tip or split, for example) with a receipt that matches the story.  
3. **M3 — First paid yes:** one Path A, B, or C customer pays; name and amount appear **with permission** on a shareable receipt.  
4. **M4 — Public stamp (optional):** when policy is ready, **one** event class can earn a chain anchor for daylight verification—details in Part III.

## I.8 Risks (said out loud)

- **Execution:** small crew, serious tools—**scope** beats heroics.  
- **Regulatory:** touching other people’s money or token-like promises can require **licenses**—lawyers review **before** the deck promises custody the code has earned.  
- **Market:** trust grows warm first; cold email alone stays slow.  
- **Technical:** **backup theatre**—backups nobody has ever restored—remains the quiet killer; **drills** are love.

## I.9 Why PBC, why now

The **PBC** charter names who benefits in public while the books stay strong enough to hire. **Now:** people already want **clear money** next to **clear words**; tools and coalition attention can meet that ask with a **whole small v1** worthy of the **SLC** label—small, lovable, complete in its chosen slice.

---

# Part II — Business model (middle ring)

## II.1 Value in one sentence

Soltrade sells **clarity where promises meet payments**—one receipt that works at a **friend’s table** and at an **angel’s desk** the next morning.

## II.2 Who we serve

| Who | What they need | First path |
|-----|------------------|------------|
| Creators and crews | Money that tracks a public milestone | Path B (usage fees) |
| Services buyers | Work scoped + invoice that matches the work | Path A (retainers, fixed scopes) |
| Angels and small funds | Plain diligence pack + live demo | Path C (named bundles) |

## II.3 Three money doors

- **Path A — Work money.** You buy a **named scope**; we deliver; you get a closing page—ask, do, change, cost, next. Ledger lines sit where accountants expect; story sits where humans read.  
- **Path B — Product money.** Subscriptions, tips, splits, escrow—each action carries a **clear price**.  
- **Path C — Trust money.** Diligence sprint, transparency room, or risk map—sold as a **named bundle** you can forward.

*(Part III spells diary, till, and notary with RFC words.)*

## II.4 Unit economics (examples)

| Label | Meaning | Year-one example |
|-------|---------|------------------|
| Anchor contract size | One serious services client per year | **$15k–$60k** |
| Product ARPU | Average revenue per active user once Path B runs | **TBD** after first ring |
| Gross margin | Money left after direct cost to serve | Higher on software; lower on white-glove Path C |
| CAC | Cost to win one paying customer | Introductions first; paid ads later |

## II.5 How people find us

Warm intros, California-facing events, open sketchbook (later open repo), **one** demo URL that loads fast and tells the truth.

## II.6 Compliance (plain)

Lawyers name licenses—or partners carry regulated seams—**before** the product holds other people’s money at scale. Until then we keep **on-screen money** and **custodied money** in **different lanes**, each written down: what we store, how long, why—diary, till, optional chain stamp each get a sentence.

## II.7 First ninety days, capital-wise

We favor **modest servers** and **honest backups**—about **$40–$100 a month** in infra before scale (`2026-04-20-191009-pdt_radiant-rio-database-stack-ninety-day-lane.md`). Fewer vendors early means more hours for **restore drills** and **customer sentences**.

## II.8 Later rings

Full autopilot agent stacks wait **until after M3** (first paid yes). Then automation can **stack on** the same spine the humans already proved.

---

## Bridge — when to open Part III

Part III uses **RFC voice** on purpose: **MUST**, **SHOULD**, **MAY**, and the RFC keyword for **forbidden** (see glossary row **RFC**—engineers and lawyers treat it as a red sign). This edition keeps **forbidden** lines light; the **dense twin** `191509` carries the full lawyer-grade keyword set. If you only need **story and money**, Parts I and II carry it; open Part III when the hammock has done its work and keyboards are warm.

---

# Part III — Technical specification and RFC (inner core)

## III.1 Status

| Field | Value |
|--------|--------|
| Status | Draft—for internal and friendly outside review |
| Keywords | RFC 2119: **MUST** (required), **SHOULD** (strongly preferred), **MAY** (optional), **forbidden** (exact RFC keyword spelling lives in dense twin `191509`) |

## III.2 Summary (normative)

The build **MUST** keep human-readable **diary** state (Postgres) separate from double-entry **till** truth (TigerBeetle). It **MAY** add Solana **notary** anchors for a named subset of events. The browser **MUST** ship as vanilla JavaScript SPA with **hash-first** routing; it **SHOULD** add History API routing when the server serves deep-link fallbacks. Business rules for money truth **MUST** run in the **Zig HTTP gate** (server); the browser **MUST** ship UI and API calls while the server holds the rules of record.

## III.3 Definitions

| Term | Meaning |
|------|---------|
| diary | Postgres tables: profiles, milestones, witnesses, attachments, moderation fields |
| till | TigerBeetle accounts and transfers (codes, flags, timeouts) |
| notary | Solana transactions that anchor hashes or ids policy picks |
| gate | Zig HTTP server: validate input, write diary, mirror till, call chain RPC |

## III.4 Goals for v1

- **G1:** One complete money verb path with receipt.  
- **G2:** Witness flow with idempotency keys.  
- **G3:** Export + audit story: diary rows and till postings line up.

## III.5 Out of scope for v1 (chosen)

- **NG1:** Headcount-zero “AI runs the company” posture.  
- **NG2:** Multi-region active-active high availability.  
- **NG3:** Third-party crypto custody ships **only** with licensed partner **or** counsel-cleared legal wrapper.

## III.6 System picture (ASCII)

```
[ Browser: vanilla JS SPA + hash router ]
           |  HTTPS
           v
[ Zig gate: validate | auth | orchestrate ]
     |              |                |
     v              v                v
[ Postgres ]   [ TigerBeetle ]   [ Solana RPC ]
   diary            till             notary
```

**Binding rule:** all chain RPC (including Solana) **MUST** start at the **Zig gate**. For v1 product flows, chain signing keys **MUST** stay server-side; browser wallet experiments stay **lab-only** until policy upgrades. The drawing helps memory; this sentence wins in a dispute.

## III.7 Component table

| Piece | MUST | SHOULD |
|-------|------|--------|
| Browser | Mount routes; send `Idempotency-Key` on writes | Small bundle; gentle upgrades where cheap |
| Zig gate | Validate writes; enforce auth | Structured logs; bounded bodies |
| Postgres | Hold diary; unique idempotency keys | Row-level rules documented |
| TigerBeetle | Balanced transfers only; **separate** process + disk from Postgres | Timeouts + codes documented per class |
| Solana | Idle until policy module ships | Small on-chain payloads (hashes / refs) |

## III.7a Dependencies (Grain style)

Each new outside library **MUST** earn a short review: **why here**, **what breaks if it leaves**, **who pins the version**. Versions stay pinned and written in the repo. The goal is **aware** dependencies, **bragging about zero** is optional noise.

## III.8 Diary tables (logical)

Minimum tables (names can vary if separation stays true):

- `account_profile`  
- `milestone_post`  
- `milestone_witness`  
- `idempotency_ledger`  

SQL example: `2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`.

## III.9 Till rules

Till **MUST** follow double-entry (debits = credits per transfer) and **MUST** use whole cents (smallest currency unit). `user_data_128` **SHOULD** tie to `milestone_id` for tracing.

## III.10 API sketch

All write endpoints **MUST** accept header `Idempotency-Key` (UUID).

| Method | Path (example) | Purpose |
|--------|------------------|---------|
| POST | `/api/milestone` | Create milestone |
| POST | `/api/milestone/witness` | Add witness |
| GET | `/api/milestone/{id}` | Read diary view |

Errors **SHOULD** return stable `error_code` strings (`grain_case`).

## III.11 Client routing

SPA **MUST** route with `hashchange` for v1 portability. SPA **MAY** add `popstate` + `history.pushState` when deep links get server HTML fallback.

## III.12 Security (short list)

- TLS **MUST** terminate at the edge with modern ciphers.  
- Secrets **MUST** live outside the git tree—vault, CI secret store, or host env only.  
- TigerBeetle port **MUST** sit on private interfaces or behind allowlist + mTLS—**wide-open public internet exposure stays off the v1 menu** (see RFC twin for **MUST NOT** wording).  
- Chain keys **MUST** use HSM or cloud KMS pattern before mainnet custodial flows.

## III.13 Logs

Gate **SHOULD** attach one request id per HTTP call and log diary + till side effects—skip card numbers and raw government ids in logs.

## III.14 Reliability (pilot scale)

| Measure | v1 target |
|---------|-----------|
| RPO | ≤ 1 hour (diary + object-store backups) |
| RTO | ≤ 4 hours (manual runbook) |
| TB RPO/RTO | Follow TigerBeetle guide once stack is fixed |

These targets assume **one** on-call human who can run the runbook; widen the bench and the numbers can tighten—update the table when the team grows.

## III.15 Phases

| Phase | Scope | Done when |
|-------|--------|-----------|
| P0 | Local dev stack | Gate boots; migrations apply |
| P1 | Diary + auth | Witness trace passes in staging |
| P2 | Till for one verb | Demo script balances match |
| P3 | Pilots | M3 from Part I |

## III.16 Open questions (DQ)

| ID | Question | Owner |
|----|----------|--------|
| DQ-001 | Which money verb ships first in v1? | Product |
| DQ-002 | Which rows earn Solana anchors first? | Legal + Eng |
| DQ-003 | Custody partner vs read-only chain UX for v1? | Legal |
| DQ-004 | PBC benefit metrics—annual report shape? | Counsel |
| DQ-005 | Early counsel read on public name + tagline; then brand search to exit placeholder? | Founders + counsel |
| DQ-006 | Named 3 a.m. pager owner + backup? | Ops |
| DQ-007 | Backup restore cadence in runbook? | Ops |
| DQ-008 | One-page incident playbook—who speaks, where logs live? | Ops + Eng |

## III.17 References

- `2026-04-20-131109-pdt_radiant-rio-keaton-walk-to-first-milestone-story.md`  
- `2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`  
- `2026-04-20-133809-pdt_radiant-rio-social-defi-milestone-walk-as-web-app-concept.md`  
- `2026-04-20-191009-pdt_radiant-rio-database-stack-ninety-day-lane.md`  
- `2026-04-20-182409-pdt_prompt-essay-serverless-db-cost-vs-agentic-self-host.md`  
- `grain_os_spiritual_philosophical_foundation_2025-12-21-183510-pst.md`  
- `2026-04-20-191509-pdt_soltrade-pbc-pitch-model-rfc-unified.md` (dense twin)

## III.18 Changelog

| Date | Change |
|------|--------|
| 2026-04-20-201109-pdt | Readable edition (8th-grade–college voice): glossary + restated I.0; Radiant scrub (positive MUST where prose allowed); bridge points to `191509` for exact forbidden RFC keyword spelling. |

---

# Appendix A — Seven yes questions (merge or pitch)

Shorter than the full spiritual foundation doc; same spine (service, offering, community, freedom, grace, creative gap). Read aloud; each line wants a **yes**.

1. **Service.** Does this release help a named stranger’s next hour?  
2. **Offering.** Would we sign this code as care + attention, green tests included?  
3. **Scope.** Are we shipping small + whole while the wider dream waits its turn?  
4. **Circle.** Users, witnesses, contributors, upstream maintainers—all honored here?  
5. **Freedom.** Can buyers, donors, or successors export, repair, or leave with dignity?  
6. **Grace.** Did we thank—in the open—the tools and hands that carried us here?  
7. **Gap.** Is the space between Grain OS dreamed and this quarter’s ship held as room to grow—with shame left outside the room?

*All yes → merge. Any stall → hammock first.*

---

## Appendix B — Eighth question (scope trap)

An angel pays you to delete **one** line of scope so the team sleeps this week—which line do you **thank** them for cutting, and why was that line still on the list?

Love sometimes answers scope with a **firm boundary**. This question honors **NG1**: people first, autopilot romance later.

---

## Closing seam

Soltrade PBC (placeholder): **Part I** speaks at the table, **Part II** names how money walks in, **Part III** holds steel for builders. The river rises when a stranger says the work was worth it.

*risk love · now == next + 1*
