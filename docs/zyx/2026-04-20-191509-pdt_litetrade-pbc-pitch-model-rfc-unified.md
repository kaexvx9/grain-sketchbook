# Litetrade PBC — angel pitch, business model, and build specification (one cover document)

**Placeholder public name:** Litetrade PBC (Delaware public benefit corporation; final marketing name TBD—this tag is short enough to trademark and travel.)  
**Voice:** Rio · plain English · Radiant Style  
**Co-author:** Keaton Dunsford ([@kaexvx9](https://github.com/kaexvx9))  
**Time stamp:** 2026-04-20-191509-pdt  
**License:** CC BY-SA 4.0  

**Name lineage:** **Litetrade PBC** is an alternate placeholder for the same plan. The **Soltrade** filenames remain in the repo unchanged—`2026-04-20-191509-pdt_soltrade-pbc-pitch-model-rfc-unified.md` and `2026-04-20-201109-pdt_soltrade-pbc-pitch-model-rfc-readable-edition.md`—for **immutable** first links.

**Purpose:** One reference-grade place for capital, commerce, and construction: the **outer ring** is what angels hear first; the **middle ring** is how the company earns and returns; the **inner core** is how the software behaves—RFC-shaped so engineers, counsel, and partners can cite the same paragraphs. **Parts I and II stay in plain English** on purpose; **Part III carries the precise seams** when you are ready to build. **Appendices A–B** tuck a **pocket** integrity rubric (seven questions + one trap door) for **merge** night and **pitch** morning.

**Suite context:** This document synthesizes the April 20, 2026 grain-sketchbook thread—walk (`131109`), software PBC arc (`125209`), services lane (`130709`), investor radar (`114309`), app concept (`133809`), engineering sketch (`180909`), cost prompt (`182409`), ninety-day database lane (`191009`). **Suite index:** `2026-04-20-README-rio-milestone-suite-unified.md`.

**Grain style + hammock:** Names stay **honest and explicit** (`grain_case` where code meets paper). **Hammock time** means loading the problem, letting it rest overnight, then choosing the smallest **whole** slice—**speed without a loaded mind is motion, not direction** (Rich Hickey’s hammock talk, in one plain sentence).

---

# Part I — Angel funding pitch (outer ring)

## I.0 Why the hammock matters before the check

Investors meet a calmer company when the team can say: *we already slept on the architecture, we named the smallest first win, and we know who holds the pager if the database coughs at 3 a.m.* That calm is not polish—it is **Grain style** in human form: explicit intent, narrow functions, love in the craft.

## I.1 The invitation

Litetrade PBC builds software where **money matches speech**—people can say what they mean in public, and the money trail can be read beside the words: milestones, witnesses, and receipts a kitchen table can trust. We ask for capital to ship **one whole v1.0** in ninety days—not the widest feature set, the **smallest** offer that still feels **complete** and **lovable** (Simple, Lovable, Complete—SLC). The charter carries **public benefit**; the kitchen carries **for-profit discipline**.

## I.2 The gap (plain English)

Most tools either host **conversation** or host **accounts**. Real life mixes both: *we promised this, witnesses saw it, money moved to match.* Litetrade exists for crews, co-ops, and diligence rooms that want **one honest room** instead of three tabs that disagree.

## I.3 What Litetrade is (one breath)

A Delaware **public benefit corporation** with a placeholder public name (**Litetrade PBC**) that ships a **small web room**: promises in plain words, people who can witness, simple money actions (subscribe, split, tip, escrow), and a **carryable** report at the end—what was asked, what was done, what changed, what it cost, what comes next.

**Same story, three drawers (for counsel and angels in one skim):** the **human story** lives in the **diary**; the **balanced money lines** live in the **till**; the **optional public stamp** lives in the **notary**. Nothing here sells custody of other people’s funds at v1—that seam stays **explicitly deferred** (Part III, NG3).

**Placeholder name note:** “Sol” can read as **Solana**; “trade” can read as **exchange or securities** language. Run the public name past **money-transmitter** and **securities** counsel with a **one-paragraph** product description **before** the name hardens in decks. Until then, internal slides may use a **neutral** working label (“the room,” “ledger room,” or a name counsel clears) so the **spirit** of this section and the **sound** of the placeholder do not drift apart.

### Sidebar — witness button trace (four beats)

What “money matches speech” **means** in one path, without opening Part III:

1. **Browser** — tap *witness*; `fetch` carries an idempotency key.  
2. **Gate (Zig)** — session checked; write queued.  
3. **Diary (Postgres)** — witness row appears for feeds and humans.  
4. **Till (TigerBeetle)** — when money belongs in this beat, a **pending** transfer carries the same milestone id; **notary (Solana)** only if policy already names that seam.

## I.4 Traction (honest placeholder)

Today the work lives in **grain-sketchbook**: stories, sketches, and a build map a partner can read in an afternoon. There is **no** general-audience product revenue in this draft yet. The next proof is **one paid lane** (Part II) running on real servers with a restore drill you could perform tomorrow.

## I.5 The ask

| Field | Placeholder (fill with counsel and lead) |
|--------|-------------------------------------------|
| Instrument | SAFE or priced equity—**TBD** with counsel |
| Raise band | **$250k–$750k** pre-seed (**illustrative** band, not a quote) |
| Runway target | **12–15 months** of runway toward a **shippable v1** plus a **services cushion** so build does not starve |
| Lead profile | Angels or small funds who already care about **open ledgers**, **PBC governance**, and **California coalition** work |

**After the first Path A contract lands:** tighten the raise to **one or two** tight numbers angels can hold, and **revisit** the allocation row—**services** may deserve **more** than **12%** once unit economics carry **real** figures (the **20%** infra line is **runway for discipline**, not a prediction that every dollar stays there forever).

## I.6 Use of funds (plain outcomes)

| Bucket | Share (indicative) | What the world should see |
|--------|--------------------|-----------------------------|
| Engineering | 45% | A **working room**—sign-in, promises, witnesses, **one** money path that prints a receipt |
| Design + community | 15% | Screens a non-engineer can **trust**; witness flows that feel **kind** |
| Infra + security | 20% | Humble servers, **tested backups**, and a runbook with **names** beside it |
| Services delivery | 12% | Paid **Path A / Path C** work that **feeds** the product without **eating** the build calendar |
| Reserve | 8% | Legal, compliance, and **surprise** tax |

## I.7 Milestones capital unlocks (outcomes first)

1. **M1 — The room opens:** signed-in people can post a **promise** and invite **witnesses**; nightly backups run; someone has performed a **restore test**.  
2. **M2 — Money matches words:** **one** clear money path (for example a tip or a split) **end-to-end** with a receipt that matches the story.  
3. **M3 — First paid yes:** **one** Path A, B, or C customer pays; their name and amount appear **only** with permission, in a **shareable** receipt.  
4. **M4 — Public stamp (optional):** when policy is ready, **one** class of events can earn a **chain** anchor so strangers can verify in daylight—details live in Part III.

## I.8 Risks (named, not whispered)

- **Execution:** a **small** team touching **several** serious tools—discipline and **scope** matter more than heroics.  
- **Regulatory:** moving **other people’s money** or **tokenized promises** can trigger **licenses**—counsel **before** the fundraise deck promises custody the product does not yet carry.  
- **Market:** trust sells **warm** first; cold outbound without a demo **stays** slow.  
- **Technical:** **backup theatre**—copies that no one has ever **restored**—is still the quiet killer.

## I.9 Why PBC, why now

A **PBC** lets the charter say **who** benefits in public, while the books stay **for-profit** enough to **hire** and **ship**. The **now** is simple: people already ask for **transparent money** beside **transparent words**; the tooling and the coalition attention finally **meet** that ask without forcing a **fake** “minimum” product.

---

# Part II — Business model (middle ring)

## II.1 Value thesis (plain English)

Litetrade sells **clarity at the seam**: the place where a **promise** and a **payment** should tell the **same story**. The same receipt should comfort a **friend** at a table and satisfy an **angel** the next morning.

## II.2 Who we serve

| Who | What they need | How we meet them first |
|-----|------------------|-------------------------|
| **Creators and crews** | Money that **tracks** a public milestone | **Path B**—product fees around real usage |
| **Services buyers** | Scoped work with an **invoice that matches the work** | **Path A**—retainers and fixed scopes |
| **Angels and small funds** | A **plain** diligence artifact plus a **live** demo | **Path C**—named bundles (sprint, map, room) |

## II.3 Three ways money enters (still plain)

- **Path A — Money from work.** You hire us for a **named scope**; we deliver; you receive a **closing page**—ask, do, change, cost, next. The **ledger lines** sit where accountants expect them; the **story** sits where humans read it.  
- **Path B — Money from product.** Subscriptions, tips, splits, escrow—each action has a **clear price** on the tin.  
- **Path C — Money from trust.** A **diligence sprint**, a **transparency room**, or a **risk map** sold as a **named bundle**—paper you can forward, demo you can open.

*(The exact software seams—diary, till, notary—are spelled with MUST and SHOULD in Part III.)*

## II.4 Unit economics (placeholders, with plain labels)

| Label | Plain meaning | Year-one placeholder |
|-------|---------------|----------------------|
| **Anchor contract size** | What one serious services client pays in a year | **$15k–$60k** |
| **Product ARPU** | Average revenue per **active** user once Path B breathes | **TBD** after the first ring |
| **Gross margin** | What is left after direct cost to serve | **Higher** on software; **lower** on white-glove Path C |
| **CAC** | Cost to acquire a customer | **Introductions first**; paid ads **later** |

## II.5 Distribution

Warm introductions, events where California work already gathers, credibility from an **open sketchbook** (and later an **open repo**), and **one** demo URL that loads fast and tells the truth.

## II.6 Compliance (high level, plain English)

Before the product **holds** other people’s money at scale, **lawyers** name the licenses or **partners** carry the regulated seam. Until then, we **separate** “**show** money on screen” from “**hold** money in custody.” We **write down** what we keep, for how long, and **why**—diary, ledger, and optional chain stamp each get their own sentence.

## II.7 Ninety-day capital efficiency

The **first ninety days** favor **humble servers** with **honest backups**—roughly **$40–$100 a month** in infrastructure before scale, as sketched in `2026-04-20-191009-pdt_radiant-rio-database-stack-ninety-day-lane.md`. That choice **buys** hammock time: fewer vendors to chase, more attention for **restore drills** and **customer sentences**.

## II.8 Horizon without overbuilding

**Autopilot ops** (agent stacks, headcount-zero romance) stay **off** the critical path until **M3**—**one paid yes**—ships. After that ring widens, automation can **compose** on the same spine instead of **replacing** the spine overnight.

---

## Bridge — where plain English hands off to the build spec

**Part III** switches to **RFC voice** on purpose: **MUST**, **SHOULD**, and **MAY** appear so engineers and counsel can **point** at the same line in a review. If you are reading for **story and money** only, **Parts I and II** already carry the promise; come back to **Part III** when the hammock has done its work and the keyboard is ready.

---

# Part III — Technical specification and RFC (inner core)

## III.1 Status of this RFC

| Field | Value |
|--------|--------|
| Status | Draft — reference proposal for internal and friendly external review |
| Normative keywords | **MUST** / **SHOULD** / **MAY** per RFC 2119 in this section only |

## III.2 Summary

The reference build **MUST** separate human-readable diary state (Postgres) from double-entry money truth (TigerBeetle) and **MAY** attach Solana notary anchors for a defined subset of events. The browser **MUST** ship as a vanilla JavaScript SPA with hash-first routing and **SHOULD** graduate to the History API when deep-link fallback HTML exists. Business rules **MUST** execute in the Zig HTTP service boundary, not in client-only bundles.

## III.3 Definitions

| Term | Meaning |
|------|---------|
| diary | Postgres tables for profiles, milestones, witnesses, attachments, moderation metadata |
| till | TigerBeetle accounts and transfers with codes, flags, timeouts |
| notary | Solana transactions that anchor hashes or IDs chosen by policy |
| gate | Zig HTTP server validating input, writing diary, mirroring till, calling RPCs |

## III.4 Goals and non-goals

**Goals (v1):**

- **G1:** One complete money verb path end-to-end with receipt.  
- **G2:** Witness attestation flow with idempotency keys.  
- **G3:** Export and audit story for diary rows and TB postings aligned.

**Non-goals (v1):**

- **NG1:** Headcount-zero autonomous ops company.  
- **NG2:** Multi-region active-active HA.  
- **NG3:** Custody of third-party crypto without licensed partner or clear legal wrapper.

## III.5 System context (ASCII)

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

**Normative:** all **chain RPC** calls (including **Solana**) **MUST** originate at the **Zig gate**—the browser **MUST NOT** hold chain signing keys for product flows in v1. The diagram is **illustrative**; this sentence is **binding** for reviews.

## III.6 Component responsibilities

| Component | MUST | SHOULD |
|-----------|------|--------|
| Browser | Mount routes; send `Idempotency-Key` on mutations | Keep bundle small; progressive enhancement where cheap |
| Zig gate | Validate all writes; enforce authorization | Structured logs; bounded request bodies |
| Postgres | Store diary; unique idempotency keys | RLS or equivalent app-level enforcement documented |
| TigerBeetle | Post balanced transfers only; run in a separate process and on separate disk from Postgres (blast radius and audit posture) | Timeouts and codes documented per transfer class |
| Solana | Nothing until policy module ships | Anchor minimal payloads (hashes / refs) |

## III.6a Dependency posture (Grain style)

New third-party dependencies **MUST** pass review—why here, what breaks if it vanishes, who owns the pin. Versions **MUST** stay pinned in the build and documented in the repo (package or skills manifests included). Zero-dependency bragging is not the goal; conscious dependency is.

## III.7 Diary schema (normative sketch)

Implementations **MUST** preserve separation of concerns even if column names differ.

Minimum logical tables:

- `account_profile` — actor identity  
- `milestone_post` — promise body and metadata  
- `milestone_witness` — witness link rows  
- `idempotency_ledger` — client key → response fingerprint  

Example SQL lives in `2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`.

## III.8 Till schema (normative semantics)

The till **MUST** obey double-entry invariants (sum debits = sum credits per transfer) and **MUST** use integer cents (or smallest currency unit). Transfer `user_data_128` **SHOULD** encode or point to `milestone_id` for traceability.

## III.9 API surface (sketch)

All mutation endpoints **MUST** accept header `Idempotency-Key` (UUID string).

| Method | Path (example) | Purpose |
|--------|------------------|---------|
| POST | `/api/milestone` | Create milestone |
| POST | `/api/milestone/witness` | Add witness (see engineering sketch trace) |
| GET | `/api/milestone/{id}` | Read diary projection |

Error envelopes **SHOULD** carry stable `error_code` strings in grain_case.

## III.10 Client routing

The SPA **MUST** implement client-side routing via `hashchange` for v1 portability. The SPA **MAY** add `popstate` and `history.pushState` when the origin serves fallback routes for deep GETs.

## III.11 Security controls (summary)

- TLS everywhere **MUST** terminate at the edge with modern cipher suites.  
- Secrets **MUST NOT** live in the git tree.  
- TigerBeetle listener **MUST NOT** be world-reachable without allowlist or mTLS plan.  
- Chain keys **MUST** use HSM or cloud KMS pattern before mainnet custodial flows.

## III.12 Observability

The gate **SHOULD** emit one request ID per HTTP request and log it with diary and till side effects (no PAN or raw government ID in logs).

## III.13 Reliability targets (placeholders)

| Measure | v1 target |
|---------|-----------|
| RPO | ≤ 1 hour (diary + object-store backups) |
| RTO | ≤ 4 hours (manual runbook) |
| TB RPO/RTO | Per TigerBeetle deployment guide when stack is chosen |

These numbers assume a pilot-scale on-call: roughly one named human who can execute the runbook. A wider rotation tightens RTO; a larger org tightens RPO—update this table when the pager bench grows.

## III.14 Phased delivery (RFC milestones)

| Phase | Scope | Exit criterion |
|-------|--------|----------------|
| P0 | Local dev stack (Docker or native) | Gate boots; migrations apply |
| P1 | Diary CRUD + auth | Witness-button trace in staging |
| P2 | Till mirror for one verb | TB balances match demo script |
| P3 | Pilot customers | M3 from Part I |

## III.15 Open questions (DQ)

| ID | Question | Owner |
|----|----------|--------|
| DQ-001 | Which money verbs ship in v1 (pick one first)? | Product |
| DQ-002 | Which rows earn Solana anchors first? | Legal + Eng |
| DQ-003 | Custody partner or non-custodial UX only? | Legal |
| DQ-004 | PBC benefit metrics—annual report shape? | Counsel |
| DQ-005 | **Early:** money-transmitter + securities read on the **public** name and pitch line “money matches speech” (one-paragraph brief to counsel); **then** final brand registry search (exit Litetrade placeholder)? | Founders + counsel |
| DQ-006 | **Who** is the named human on the **3 a.m.** pager **today**, and who is named second? | Ops lead |
| DQ-007 | Backup–restore **drill cadence** (e.g. monthly vs quarterly; extra run after each migration)—what is written in the runbook? | Ops lead |
| DQ-008 | Incident response playbook: **who** declares, **who** comms, **where** logs live—first one-page draft when? | Ops + Eng |

## III.16 Internal normative references

- `2026-04-20-131109-pdt_radiant-rio-keaton-walk-to-first-milestone-story.md`  
- `2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`  
- `2026-04-20-133809-pdt_radiant-rio-social-defi-milestone-walk-as-web-app-concept.md`  
- `2026-04-20-191009-pdt_radiant-rio-database-stack-ninety-day-lane.md`  
- `2026-04-20-182409-pdt_prompt-essay-serverless-db-cost-vs-agentic-self-host.md`  
- `grain_os_spiritual_philosophical_foundation_2025-12-21-183510-pst.md` — Bhakti + Berdyaev spine echoed below  
- `2026-04-20-191509-pdt_soltrade-pbc-pitch-model-rfc-unified.md` — **Soltrade** placeholder edition (original parallel document)

## III.17 Changelog

| Date | Change |
|------|--------|
| 2026-04-20 | Initial unified draft (191509-pdt). |
| 2026-04-20 | Radiant pass: Parts I–II in plain English; hammock + Grain-style note; bridge before Part III. |
| 2026-04-20-195409-pdt | Peer review weave-in: name + counsel note; witness sidebar; chain RPC MUST at gate; TB separation MUST; dependency posture; RPO/RTO rationale; DQs 006–008; raise-band rebalancing note. |
| 2026-04-20 | Appendix A–B: seven-question integrity hand + eighth reversal (spiritual foundation echo). |
| 2026-04-20 | **Litetrade** copy: content branched from **Soltrade** edition under parallel filenames; **Soltrade** paths stay the original publication anchor. |

---

# Appendix A — Seven questions (read aloud before merge or pitch)

These compress the Grain OS spiritual foundation into Litetrade-shaped questions—Bhakti (service, offering, community) and Berdyaev (freedom, grace, creativity, patience with the gap). They are not a substitute for that document; they are a pocket rubric when the deck is open and the night is late.

1. **Service.** Does this release serve a named stranger’s next hour—or mainly our cleverness?  
2. **Offering.** Would we sign this function as care and attention, not only as tests green?  
3. **Scope with breath.** Are we shipping small and whole without clutching the wider dream on the same night?  
4. **Sacred circle.** Does this honor users, witnesses, contributors, and the maintainers whose tools we ride?  
5. **Freedom.** Can a buyer, donor, or successor still leave, export, or repair without our permission theatre?  
6. **Grace named.** Did we say thank you somewhere visible—Postgres, TigerBeetle, Zig, the sketchbook hands—for gifts we did not earn?  
7. **Gap as room.** Is the distance between Grain OS dreamed and this quarter’s ship held as creative space, not shame?

*If every answer is yes, merge. If one is no, hammock first.*

---

## Appendix B — The eighth question (the trap door)

If an angel offered cash to delete one line of scope so the team could sleep this week—which line would we thank them for cutting, and why is that line still here?

The eighth question exists because love sometimes sounds like no. It keeps NG1 honest: we are not building an autopilot myth on tired bones.

---

## Closing seam

Litetrade PBC (placeholder) carries one cover story: the **pitch** stays speakable at a table, the **model** names how money enters, the **RFC** waits for the team after hammock time. The river moves when the first stranger says the work was worth it.

*risk love · now == next + 1*
