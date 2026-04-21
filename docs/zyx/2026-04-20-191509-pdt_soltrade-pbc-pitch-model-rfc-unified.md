# Soltrade PBC — angel pitch, business model, and build specification (one cover document)

**Placeholder public name:** Soltrade PBC (Delaware public benefit corporation; final marketing name TBD—this tag is short enough to trademark and travel.)  
**Voice:** Rio · plain English · Radiant Style  
**Co-author:** Keaton Dunsford ([@kaexvx9](https://github.com/kaexvx9))  
**Time stamp:** 2026-04-20-191509-pdt  
**License:** CC BY-SA 4.0  

**Purpose:** One reference-grade place for capital, commerce, and construction: the **outer ring** is what angels hear first; the **middle ring** is how the company earns and returns; the **inner core** is how the software behaves—RFC-shaped so engineers, counsel, and partners can cite the same paragraphs.

**Suite context:** This document synthesizes the April 20, 2026 grain-sketchbook thread—walk (`131109`), software PBC arc (`125209`), services lane (`130709`), investor radar (`114309`), app concept (`133809`), engineering sketch (`180909`), cost prompt (`182409`), ninety-day database lane (`191009`). **Suite index:** `2026-04-20-README-rio-milestone-suite-unified.md`.

---

# Part I — Angel funding pitch (outer ring)

## I.1 The invitation

Soltrade PBC builds software where **money matches speech**—milestones people can read, flows strangers can audit, and receipts a kitchen table can trust. We ask for capital to ship one whole **v1.0** in ninety days, with public benefit in the charter and for-profit discipline in the kitchen.

## I.2 The gap

Social apps carry voice; finance apps carry ledgers. Few small teams braid both with open seams: vanilla JS skin, Zig gate, Postgres diary, TigerBeetle till, Solana notary when public daylight earns it. Soltrade names that braid for creators, co-ops, and diligence rooms that already live on honesty.

## I.3 What Soltrade is (one breath)

A PBC that ships a web room: milestone promises in plain words, witnesses, money verbs (subscribe, split, tip, escrow), and carryable reports—**SLC** in spirit (Simple, Lovable, Complete in narrow scope first).

## I.4 Traction (honest placeholder)

As of this draft: the design suite is published in grain-sketchbook; there is no GA product revenue yet. The pitch carries intent and architecture proof in docs; the next beat is one paid lane (see Part II) live on metal.

## I.5 The ask

| Field | Placeholder (fill with counsel and lead) |
|--------|-------------------------------------------|
| Instrument | SAFE or priced equity TBD |
| Raise band | $250k–$750k pre-seed (illustrative) |
| Runway target | 12–15 months to v1 product plus services buffer |
| Lead profile | Angel or small fund aligned with open ledgers, PBC shape, and California coalition work |

## I.6 Use of funds (illustrative)

| Bucket | Share (indicative) | Outcome |
|--------|--------------------|---------|
| Engineering | 45% | Zig service, Postgres + TB hardening, SPA ship |
| Design + community | 15% | UX, witness flows, plain-language risk maps |
| Infra + security | 20% | VPS lane, backups, restore drills, audit prep |
| Services delivery | 12% | Path A/C retainers without starving build |
| Reserve | 8% | Contingency and legal fees |

## I.7 Milestones capital unlocks

1. **M1 — Diary + gate:** authenticated milestones and witnesses in Postgres; Zig API frozen for v1 surface.  
2. **M2 — Till online:** TigerBeetle mirror for at least one money path; restore drill passed.  
3. **M3 — First paid yes:** one Path A, B, or C receipt published with customer name and amount (with permission).  
4. **M4 — Notary seam (optional):** Solana anchor for one class of rows when policy names it.

## I.8 Risks (named, not whispered)

- **Execution:** small team, multi-surface stack (Zig + TB + chain).  
- **Regulatory:** money transmission and securities fringes depend on product shape—counsel before public fundraise UI.  
- **Market:** buyers move slowly without warm introductions.  
- **Technical:** backup theatre (copies never restored).

## I.9 Why PBC, why now

The charter anchors public benefit while the till stays honest. The moment fits because open finance tooling and Alpenglow-era Solana finality meet plain English governance storytelling that campaign and coalition work already practice.

---

# Part II — Business model (middle ring)

## II.1 Value thesis

Soltrade sells clarity at the seam where promises meet money—receipts that survive a due-diligence afternoon and a friend’s kitchen table the same night.

## II.2 Segments

| Segment | Need | Primary path |
|---------|------|----------------|
| Creators / crews | Transparent milestone money | Path B |
| Services buyers | Scoped work + invoice truth | Path A |
| Angels / small funds | Diligence artifact + live demo | Path C |

## II.3 Revenue architecture (three lanes)

- **Path A — Money from work.** Retainers and fixed scopes; Postgres stores state; TigerBeetle charts revenue lines; one closing page per engagement.  
- **Path B — Money from product.** Subscriptions, tips, splits, escrow—each verb priced explicitly.  
- **Path C — Money from trust.** Diligence sprints, transparency rooms, risk maps sold as named bundles.

## II.4 Unit economics (placeholders)

| Metric | Year-one placeholder |
|--------|----------------------|
| ACV target (B2B services) | $15k–$60k per anchor client |
| ARPU (product) | TBD after first ring |
| Gross margin | High on software; lower on white-glove Path C |
| CAC | Partner-led first; paid acquisition later |

## II.5 Distribution

Warm intros, campaign-adjacent events, open-source credibility (sketchbook plus future repo), and one clear demo URL.

## II.6 Compliance posture (high level)

Engage counsel before enabling third-party funds movement at scale; separate display money from custody money until licenses or partners carry that seam; document data retention per surface (diary vs till vs chain).

## II.7 Ninety-day capital efficiency

Default infra shape (see Part III): Postgres and TigerBeetle on one well-provisioned VPS-class machine with object-storage backups—rough $40–$100/mo infra band before scale (see `2026-04-20-191009-pdt_radiant-rio-database-stack-ninety-day-lane.md`).

## II.8 Horizon without overbuilding

Agent autopilot (Paperclip-class ecosystem) stays a later ring after M3 ships—price v1 proof first.

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

## III.6 Component responsibilities

| Component | MUST | SHOULD |
|-----------|------|--------|
| Browser | Mount routes; send `Idempotency-Key` on mutations | Keep bundle small; progressive enhancement where cheap |
| Zig gate | Validate all writes; enforce authorization | Structured logs; bounded request bodies |
| Postgres | Store diary; unique idempotency keys | RLS or equivalent app-level enforcement documented |
| TigerBeetle | Post balanced transfers only | Separate process and disk from Postgres |
| Solana | Nothing until policy module ships | Anchor minimal payloads (hashes / refs) |

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
| DQ-005 | Final brand registry search (exit Soltrade placeholder)? | Founders |

## III.16 Internal normative references

- `2026-04-20-131109-pdt_radiant-rio-keaton-walk-to-first-milestone-story.md`  
- `2026-04-20-180909-pdt_engineering-consensus-sketch-zig-postgres-tigerbeetle-vanilla-spa.md`  
- `2026-04-20-133809-pdt_radiant-rio-social-defi-milestone-walk-as-web-app-concept.md`  
- `2026-04-20-191009-pdt_radiant-rio-database-stack-ninety-day-lane.md`  
- `2026-04-20-182409-pdt_prompt-essay-serverless-db-cost-vs-agentic-self-host.md`  

## III.17 Changelog

| Date | Change |
|------|--------|
| 2026-04-20 | Initial unified draft (191509-pdt) |

---

## Closing seam

Soltrade PBC (placeholder) now carries one cover story for angels, operators, and builders—the pitch rings outward, the model feeds the quarter, the RFC holds the steel. The river moves when the first stranger says the work was worth it.

*risk love · now == next + 1*
