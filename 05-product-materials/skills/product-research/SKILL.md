---
name: product-research
description: FF&E product research companion — captures, structures, and organizes products into a persistent Google Sheet library as the designer browses. Works continuously across sessions with Norma Jean and other data skills.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
  - AskUserQuestion
  - mcp__google__sheets_values_get
  - mcp__google__sheets_values_update
  - mcp__google__sheets_spreadsheet_get
---

# /product-research — Product Research Companion

A persistent research companion for FF&E product discovery. Walks alongside the designer as they browse, capturing products into a shared Google Sheet that serves as the firm's master product library.

This is **not a transactional tool** — there is no start or finish. The designer drops things in whenever they find something interesting, and the library grows over time.

## The Master Sheet

All product data lives in a single Google Sheet — the same one used by Norma Jean (browser clipper) and the other data-management skills. This skill is one of several doors into the same library.

### How products get in

| Source | How it works |
|--------|-------------|
| **Norma Jean** | Designer clicks Alt+C in Chrome → product clipped to sheet automatically |
| **This skill** | Designer drops a screenshot, paste, verbal note, PDF, or URL into Claude → added to sheet |
| **`/product-spec-bulk-fetch`** | Batch URL extraction → appended to sheet |
| **`/product-spec-pdf-parser`** | PDF catalog extraction → appended to sheet |

### Connecting to the sheet

On first invocation, ask for the Google Sheet ID or URL:

> "What's the Google Sheet for your product library? (Paste the URL or sheet ID)"

If the designer doesn't have one yet, offer to create a new one using the standard Norma Jean template format.

Once connected, remember the sheet ID for the session.

### Schema — 33 columns

The master schema is Norma Jean's 29-column layout plus 4 research columns. **All skills must write to this same schema.**

#### Row 1: Section group labels (merged cells)
| Product (A–J) | Dimensions (K–P) | Materials & Finish (Q–S) | Pricing (T–V) | Logistics (W–AA) | Meta (AB–AC) | Research (AD–AG) |

#### Row 2: Column headers
```
A:  Link                    — =HYPERLINK(url, "Link")
B:  Thumbnail               — =IMAGE(image_url)
C:  Product Name
D:  Description
E:  SKU
F:  Brand
G:  Designer
H:  Vendor
I:  Collection
J:  Category                — Chair, Table, Sofa, Bed, Light, Storage, Desk, Shelving, Rug, Mirror, Accessory, Tabletop, Kitchen, Bath, Window, Door, Outdoor Furniture, Textile
K:  W                       — Width (numeric)
L:  D                       — Depth (numeric)
M:  H                       — Height (numeric)
N:  Seat H                  — Seat height (numeric, seating only)
O:  Unit                    — in, cm, or mm
P:  Weight                  — As stated with unit (e.g. "45 lbs")
Q:  Materials               — Comma-separated
R:  Colors/Finishes         — All available options, comma-separated
S:  Selected Color/Finish   — Currently selected variant
T:  List Price              — Numeric, no currency symbol
U:  Sale Price              — Numeric, only if discounted
V:  Currency                — USD, EUR, etc.
W:  Lead Time               — As stated
X:  Warranty                — As stated
Y:  Certifications          — Comma-separated (GREENGUARD Gold, FSC, BIFMA, etc.)
Z:  COM/COL                 — COM, COL, COM/COL, or blank
AA: Indoor/Outdoor          — Indoor, Outdoor, Indoor/Outdoor, or blank
AB: Clipped At              — ISO timestamp
AC: Image URL               — Direct image URL
AD: Tags                    — Comma-separated, freeform (e.g. "lounge, scandinavian, project-oak")
AE: Notes                   — Designer notes (e.g. "Check COM options", "Great for small lobbies")
AF: Status                  — saved, shortlisted, rejected, ordered
AG: Source                  — norma-jean, research, bulk-fetch, pdf-parser, manual
```

**When this skill adds a row, set:**
- `Clipped At` → current ISO timestamp
- `Status` → "saved" (default)
- `Source` → "research" (or "manual" for verbal notes, "bulk-fetch"/"pdf-parser" when chaining)
- `Link` → `=HYPERLINK("url", "Link")` if URL is known
- `Thumbnail` → `=IMAGE("image_url")` if image URL is known

## How It Works

The designer can drop any of these into the conversation at any time:

| Input | What happens |
|-------|-------------|
| **Screenshot** | Read the image visually — extract product name, brand, specs, price, everything visible |
| **Copy-paste** | Designer selects text from a product page and pastes it — parse and structure |
| **Verbal note** | "Hem Chop Chair, stainless steel, Philippe Malouin, outdoor stacking" — create entry from description |
| **PDF** | Parse the spec sheet or catalog page, extract products |
| **URL** | Attempt to fetch the page; if JS-rendered (common), ask for a screenshot or paste instead |
| **Search request** | "Find me sustainable acoustic panels" — search the web, present options to capture |
| **Tag/organize** | "Tag the last 3 as 'project-oak'" or "Shortlist the Muuto sofa" |
| **Recall** | "What acoustic panels do we have?" — read and filter the sheet |

### Why screenshots and paste come first

Most furniture brand websites (Hem, Muuto, HAY, Vitra, etc.) are JavaScript-rendered single-page apps. Automated fetching returns empty CSS shells. The designer is already *looking at the page* in their browser, so the fastest path is:

1. **Screenshot** (one keystroke) — Claude reads it visually and extracts everything shown
2. **Copy-paste** (select the spec block) — Claude parses the raw text
3. **Verbal description** — Claude captures what the designer tells it and fills gaps from general knowledge

If the designer has Norma Jean installed, they should use **Alt+C for speed** — it reads the actual DOM and gets more data. This skill is for when they want to add context (tags, notes), add products from non-browser sources (PDFs, verbal), or work with the library conversationally.

If a URL fetch returns no product data, immediately ask:

> "That site is JS-rendered — I can't read it from here. You can Alt+C it with Norma Jean, screenshot it, or paste the specs."

## Core Behaviors

### 1. Capture

When the designer drops something in:

**Screenshot or image:**
1. Read the image visually — extract every piece of product data visible
2. Map to the 33-column schema
3. Fill gaps from general knowledge if the product/brand is recognizable
4. Append row to the Google Sheet
5. Show confirmation card

**Copy-paste (raw text from a product page):**
1. Parse the text — identify all schema fields
2. Append to sheet
3. Show confirmation card

**Verbal note:**
1. Capture what the designer says — even partial ("that walnut bench from Hem, around $1,200")
2. Fill in known specs from general knowledge
3. Append to sheet with blank fields for unknowns — partial entries are fine
4. Set Source to "manual"

**URL:**
1. Attempt WebFetch — if it returns product data, extract, append, confirm
2. If JS-rendered (returns only CSS/scripts), **don't retry** — ask for screenshot or paste
3. Store the URL in the Link column either way

**PDF:**
1. Read the PDF directly
2. Extract all products (may be multiple per page)
3. Append each as a row
4. Set Source to "pdf-parser"

**Confirmation card format:**

```
Added: Outline Sofa 3-Seater
Muuto · Seating · 220 × 84 × 71 cm
Materials: Aluminum, fabric · $4,895 USD
Tags: — · Status: saved

Want to add tags or notes?
```

### 2. Quick Capture Mode

If the designer is dropping multiple items rapidly (3+ without conversational text), switch to compact output:

```
✓ Outline Sofa 3-Seater — Muuto · Seating · $4,895
✓ Aeron Chair — Herman Miller · Seating · $1,395
✓ Tip Lamp — Muuto · Lighting · $295
⚠ https://example.com/page — JS-rendered, skipped (screenshot or Alt+C it)

3 added to sheet. Tag these? Add notes?
```

### 3. Recall & Search

When the designer asks about what's in the library, read the sheet and filter:

- **"What chairs do we have?"** → Filter by Category column
- **"Show me everything from Muuto"** → Filter by Brand
- **"Sustainable options under $500"** → Filter by List Price + Certifications
- **"What did I clip last week?"** → Filter by Clipped At
- **"Show the project-oak items"** → Filter by Tags column
- **"Anything in walnut?"** → Search Materials and Colors/Finishes columns

Present results as a table:

```
## Library: Seating (12 items)

| # | Product | Brand | Dims | Price | Tags | Status |
|---|---------|-------|------|-------|------|--------|
| 3 | Outline Sofa 3-Seater | Muuto | 220×84×71cm | $4,895 | lounge | saved |
| 7 | Aeron Chair | Herman Miller | 27×27×41in | $1,395 | task | shortlisted |
```

The `#` column is the sheet row number — useful for referencing specific items.

### 4. Organize

The designer can organize at any time:

- **Tag**: "Tag rows 3 and 7 as 'lobby'" → update Tags column (append, don't overwrite existing tags)
- **Note**: "Note on the Aeron — check Grade B fabric" → update Notes column
- **Status**: "Shortlist the Outline" → update Status to "shortlisted"
- **Remove**: "Remove row 12" → delete the row from the sheet
- **Edit**: "Update the Outline price to $4,500" → edit the cell

When the designer references a product by name ("the Muuto sofa", "that walnut bench"), search the sheet to find matching rows. If ambiguous, show options and ask.

**Updating cells:** Use `mcp__google__sheets_values_update` to write to specific cells. Reference by row number from the sheet.

### 5. Compare

When asked to compare products:

```
## Comparison: Task Chairs

|                  | Aeron          | Cosm           | Leap           |
|------------------|----------------|----------------|----------------|
| Brand            | Herman Miller  | Herman Miller  | Steelcase      |
| Price            | $1,395         | $1,195         | $1,289         |
| W × D × H       | 27×27×41 in    | 26×24×39 in    | 27×25×40 in    |
| Materials        | Mesh, aluminum | Mesh, die-cast | Fabric, steel  |
| Certifications   | —              | GREENGUARD     | Level 2, C2C   |
| Indoor/Outdoor   | Indoor         | Indoor         | Indoor         |
| Status           | shortlisted    | saved          | saved          |
```

### 6. Web Search

When the designer asks to find products (not capture existing ones):

1. Search the web using WebSearch
2. Present findings as candidates — **don't auto-add** to the sheet
3. Let the designer pick which to capture
4. For selected items, attempt to fetch full specs from the URL, or ask for screenshot/paste if JS-rendered
5. Append captured items to the sheet

### 7. Stats

When asked "how's the library?" or "library stats", read the sheet and report:

```
## Product Library — 47 products
Sheet: "Norma Jean - FF&E"

By category: Chair (14), Light (11), Table (8), Storage (6), Acoustic (4), Other (4)
By status: saved (38), shortlisted (7), ordered (2)
By source: norma-jean (28), research (12), bulk-fetch (5), manual (2)
Top brands: Muuto (8), HAY (6), Herman Miller (5)
Tags: project-oak (12), lobby (6), sustainable (4)

5 items missing dimensions · 3 items missing price
```

### 8. Duplicate Detection

Before appending a row, check for existing entries with the same Product Name + Brand, or the same URL. If found:

> "**Outline Sofa** by Muuto is already in row 14 (clipped Mar 10). Update that row with new info, or add as a separate entry?"

### 9. Handoff to Other Skills

The sheet is the shared interface. When the designer wants to run other skills:

- **"Clean up the sheet"** → Suggest running `/product-spec-bulk-cleanup` on the sheet
- **"Process images for my shortlist"** → Export shortlisted Image URLs, suggest `/product-image-processor`
- **"Run the full pipeline on these 5 URLs"** → Suggest `/spec-package`

These skills should read from and write back to the same sheet.

## Conversation Style

Keep responses **short and natural**:

- After a capture: show the card, move on
- After a recall: show the table, offer next actions
- After organizing: confirm the change, nothing more
- Don't re-explain the library concept each time

If the designer asks something unrelated to product research, respond normally — this skill doesn't take over the whole conversation.

## First Run

On first invocation with no sheet connected:

1. Ask for the sheet ID/URL, or offer to create one
2. If creating new: use Norma Jean's template format (frozen rows, section groups, column widths, filters, Spectral font, alternating rows) with the 4 additional research columns (AD–AG)
3. Brief intro:

> "Connected to your product library (47 items). Drop screenshots, paste specs, or describe products anytime — I'll add them to the sheet. You can also ask me to search, compare, tag, or filter."

That's it — let the designer start browsing.

## Schema Alignment Note

The 29-column Norma Jean schema is the **master**. The other data-management skills (`/product-spec-bulk-fetch`, `/product-spec-bulk-cleanup`, `/product-spec-pdf-parser`) currently use a narrower 15-column schema. When those skills write to the master sheet, they should:

1. Map their fields to the correct columns in the 33-column layout
2. Leave Norma Jean–specific columns blank (Designer, Vendor, SKU, etc.) if the data isn't available
3. Set `Source` to their own name
4. Set `Clipped At` to the current timestamp

The `/product-spec-bulk-cleanup` skill should be able to operate on the master sheet directly — normalizing categories, materials, dimensions, and language across all rows regardless of source.
