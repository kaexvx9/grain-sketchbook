# Engineering consensus sketch — Zig diary, TigerBeetle till, Postgres memory, vanilla SPA routes

**Voice:** Rio · technical plain English  
**Co-author:** Keaton Dunsford ([@kaexvx9](https://github.com/kaexvx9))  
**Time stamp:** 2026-04-20-180909-pdt  
**License:** CC BY-SA 4.0  

**Purpose:** A **high-level** “end of design meeting” handoff: the stack we **name** together, **dynamic client-side routing** in **open browser primitives** (hash-first, History API when you add server fallback), and **pseudocode-level** shapes for **Zig**, **Postgres**, and **TigerBeetle**. Names follow **`docs/grain_style.md`** (`grain_case` = snake_case with intent). **Suite index:** `2026-04-20-README-rio-milestone-suite-unified.md`. **Product concept:** `2026-04-20-133809-pdt_radiant-rio-social-defi-milestone-walk-as-web-app-concept.md`.

---

## Consensus (what we said “yes” to)

1. **Browser:** Vanilla JS owns **navigation shell** and **view mounting**. **Dynamic SPA routing** belongs here: listen for URL changes, parse route, swap DOM (or templates). The **hash router** (`#/milestones/42`) is the **smallest** portable pattern; **`popstate`** + **`history.pushState`** carries **clean URLs** once the server serves a fallback for deep `GET`s.
2. **Server (Zig):** One **IO boundary**: validate input, write **Postgres** facts, enqueue or mirror **TigerBeetle** money moves, touch **chain** RPC when the product names that seam. **Business rules live here**; the bundle **renders** and **asks**.
3. **Postgres:** **Human-readable** state, search, moderation, attachments, **idempotency keys** so retries stay safe on busy networks.
4. **TigerBeetle:** **Double-entry** truth for balances and in-flight transfers; **codes** and **timeouts** for policy; the **ledger** carries money semantics while the **social graph** stays in Postgres.
5. **Solana:** Settlement / notary for what belongs **in public daylight**—**timestamped** across strangers—with details **gathered** in one chain-facing module.

**Next passes (still open):** depth of the TigerBeetle chart of accounts; clean URLs in v0 vs v1; which rows earn chain anchors first.

---

## Zig — domain shapes at the server gate

Illustrative only: real code would add `!` error paths, length caps, and explicit allocators.

```zig
/// Why: keep milestone story and money legs in one validated envelope at the HTTP edge.
pub const milestone_key = struct {
    bytes: [16]u8, // uuid binary, fixed size
};

pub const money_cents = i64; // assert non-negative at call sites for credits policy

pub const witness_ref = struct {
    account_handle: []const u8,
    attested_at_unix_ms: i64,
};

pub const milestone_post_ingress = struct {
    id: milestone_key,
    author_handle: []const u8,
    body_text: []const u8,
    witnesses: []const witness_ref,
    /// Links Postgres row to TB transfer batch (nullable until first money attach).
    tb_batch_id: ?u128,
};

pub const tb_mirror_result = struct {
    batch_id: u128,
    posted: bool,
};
```

---

## Postgres — diary tables (relational sketch)

```sql
-- grain_case table names; big-endian-ish column order: identity, time, body, foreign legs.

create table if not exists account_profile (
    account_id uuid primary key default gen_random_uuid(),
    handle text not null unique,
    display_name text not null,
    created_at timestamptz not null default now()
);

create table if not exists milestone_post (
    milestone_id uuid primary key default gen_random_uuid(),
    author_account_id uuid not null references account_profile (account_id),
    body_text text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    tb_batch_id uuid null, -- correlate with application batch id / TB metadata table
    chain_anchor_tx_sig bytea null
);

create table if not exists milestone_witness (
    milestone_id uuid not null references milestone_post (milestone_id) on delete cascade,
    witness_account_id uuid not null references account_profile (account_id),
    attested_at timestamptz not null default now(),
    primary key (milestone_id, witness_account_id)
);

create table if not exists idempotency_ledger (
    client_key text primary key,
    response_hash bytea not null,
    created_at timestamptz not null default now()
);
```

---

## TigerBeetle — till semantics (conceptual schema)

TigerBeetle models **accounts** and **transfers** with **debits** / **credits**, **codes**, **flags**, and **timeouts**. The block below is a **sketch** (not a checked-in `.tigerbeetle` definition); it states the **agreement** your Zig service implements when building structs for the client.

```text
-- Accounts (examples):
--   chart:asset:escrow:pool
--   chart:liability:user:alice
--   chart:revenue:platform:fee

-- Transfer (one leg):
--   debit  chart:asset:escrow:pool   amount_cents
--   credit chart:liability:user:alice   amount_cents
--   user_data_128 = milestone_uuid_as_u128
--   code = enum: pledge_lock | pledge_release | tip | subscription_split
--   flags = e.g. pending until chain confirmation (policy-specific)
--   timeout = ledger time window for two-phase commits you choose

Invariant the meeting keeps visible:
  sum(debits) == sum(credits) per transfer; integer cents only; floats stay out of the till.
```

---

## Vanilla JS — dynamic SPA routing (hash router)

**Answer to “is routing only static in vanilla JS?”:** **Client-side routing** is already in the platform—**you** listen for navigation signals and **mount** the right UI. Frameworks **package** the same **`hashchange` / `popstate`** primitives this sketch uses.

```javascript
// grain_case function names; no build step required.

const route_table = {
  "#/": () => mount_home(document.getElementById("app_root")),
  "#/milestones": () => mount_milestone_list(document.getElementById("app_root")),
  "#/milestones/new": () => mount_milestone_editor(document.getElementById("app_root")),
};

function route_from_hash() {
  const raw = window.location.hash || "#/";
  const normalized = raw.endsWith("/") && raw.length > 2
    ? raw.slice(0, -1)
    : raw;
  const mount = route_table[normalized] || mount_not_found;
  mount();
}

function on_hash_changed() {
  route_from_hash();
}

function boot_spa_shell() {
  window.addEventListener("hashchange", on_hash_changed);
  route_from_hash();
}

// Optional second phase (clean URLs): history.pushState + popstate + server HTML fallback
// for GET /milestones/42 — same route_table keyed by pathname once parsed.
```

**HTML side (minimal):**

```html
<nav>
  <a href="#/">home</a>
  <a href="#/milestones">milestones</a>
  <a href="#/milestones/new">new</a>
</nav>
<div id="app_root"></div>
<script src="/static/boot_spa_shell.js" defer></script>
```

---

## One trace — “witness button” through the stack

1. **JS:** `hash` stays on milestone detail; `fetch("/api/milestone/witness", { method: "POST", headers: { "idempotency-key": crypto.randomUUID() } })`.
2. **Zig:** verify session, insert `milestone_witness`, return JSON.
3. **Zig (later beat):** when escrow opens for that pledge, open a TB **pending** transfer with `milestone_id` in `user_data_128`.
4. **Postgres:** row visible in feeds; **TB** shows balance truth; **chain** carries optional attestation of milestone hash.

---

## Style note

Identifiers in snippets use **`grain_case`** in step with **`docs/grain_style.md`**. Where a host repo prefers `camelCase`, **wrap** at the boundary and keep **one** convention visible per subtree—readers see a single rhythm.

---

*risk love · the room has a map*
