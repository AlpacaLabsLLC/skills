---
name: product-research
description: FF&E product research companion — captures, structures, and organizes products into a persistent library as the designer browses. Works continuously across sessions.
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

A persistent research companion for FF&E product discovery. Walks alongside the designer as they browse, capturing products, materials, and vendors into a growing library that the whole firm can draw from.

This is **not a transactional tool** — there is no start or finish. The designer drops things in whenever they find something interesting, and the library grows over time.

## How It Works

The designer can drop any of these into the conversation at any time:

| Input | What happens |
|-------|-------------|
| **URL** | Fetch the page, extract product specs, add to library |
| **PDF** | Parse the spec sheet or catalog page, extract products |
| **Screenshot** | Read the image, extract whatever is visible (name, brand, materials) |
| **Verbal note** | "Remember that walnut bench from Hem" — create a partial entry with what's known |
| **Search request** | "Find me sustainable acoustic panels" — search the web, present options to capture |
| **Tag/organize** | "Tag the last 3 as 'project-oak'" or "Move those to the lighting collection" |
| **Recall** | "What acoustic panels do we have?" — search and filter the library |

Every interaction adds to or queries from a **persistent product library**.

## The Library

### Location

The library is stored at the path the user specifies when first invoked. If no path is given, ask:

> "Where should I keep your product library? A few options:"
> - `~/Documents/Work-Docs/product-library.json` (personal)
> - A project-specific path (e.g., `./product-library.json`)
> - A shared team path

Once set, remember the path for the session. If a `product-library.json` already exists in the working directory or `~/Documents/Work-Docs/`, load it automatically.

### Schema

Each library entry extends the standard FF&E schema with research metadata:

```json
{
  "id": "plb_20260313_001",
  "added": "2026-03-13T14:30:00Z",
  "source": "url|pdf|screenshot|note|search",
  "source_ref": "https://example.com/product-page",

  "product_name": "Outline Sofa 3-Seater",
  "brand": "Muuto",
  "collection": "Outline",
  "category": "Seating",
  "w": 220,
  "d": 84,
  "h": 71,
  "unit": "cm",
  "materials": "Aluminum, fabric",
  "colors_finishes": "Black/Fiord 151, Black/Remix 163",
  "price": 4895.00,
  "currency": "USD",
  "lead_time": "8-12 weeks",
  "url": "https://example.com/outline-sofa",
  "image_url": "https://example.com/outline-sofa.jpg",

  "tags": ["lounge", "soft-seating", "scandinavian"],
  "collections": ["reception-inspo"],
  "notes": "Great scale for smaller lobbies. Check COM options.",
  "status": "saved",
  "sustainability": {
    "certifications": ["GREENGUARD Gold"],
    "materials_notes": "FSC wood frame option available"
  }
}
```

**Field rules:**
- All standard FF&E fields follow the same conventions as `/product-spec-bulk-fetch` (Title Case names, controlled category vocabulary, separate dimension fields, etc.)
- `id` is auto-generated: `plb_YYYYMMDD_NNN`
- `tags` are freeform, lowercase, hyphenated
- `collections` are named groups — a product can belong to multiple
- `status` is one of: `saved`, `shortlisted`, `rejected`, `ordered`
- `sustainability` is optional — populated when the info is available
- Partial entries are fine — a verbal note might only have `product_name`, `brand`, and `notes`

### ID Generation

Generate IDs using the format `plb_YYYYMMDD_NNN` where:
- `YYYYMMDD` is the date the entry was added
- `NNN` is a zero-padded sequence number, incrementing from the highest existing ID for that date

## Core Behaviors

### 1. Capture

When the designer drops a URL, PDF, screenshot, or note:

1. **Extract** what you can — use WebFetch for URLs, read PDFs directly, read images visually
2. **Structure** into the schema — map to standard fields, normalize per cleanup rules
3. **Fill gaps** — if you recognize the brand/product, fill in known specs from general knowledge
4. **Present** the entry back to the designer in a compact card:

```
## Added: Outline Sofa 3-Seater
**Muuto** · Seating · 220 × 84 × 71 cm
Materials: Aluminum, fabric
Price: $4,895 USD · Lead: 8-12 weeks
Tags: —
Notes: —

Want to add tags, notes, or assign to a collection?
```

5. **Save** to the library immediately — don't wait for confirmation to save. The designer can edit after.

### 2. Quick Capture Mode

If the designer is dropping multiple URLs rapidly (browsing mode), switch to a compact output:

```
✓ Outline Sofa 3-Seater — Muuto · Seating · $4,895
✓ Aeron Chair — Herman Miller · Seating · $1,395
✓ Tip Lamp — Muuto · Lighting · $295
⚠ https://example.com/page — not a product page, skipped

4 captured. Tag these? Add to a collection?
```

Detect rapid-fire mode when the designer sends 3+ URLs without conversational text between them.

### 3. Search & Recall

When the designer asks about what's in the library:

- **"What chairs do we have?"** → Filter by category: Seating
- **"Show me everything from Muuto"** → Filter by brand
- **"Sustainable options under $500"** → Filter by price + sustainability fields
- **"What did I save last week?"** → Filter by date
- **"Show the reception-inspo collection"** → Filter by collection
- **"Anything in walnut?"** → Search materials and colors_finishes fields

Present results as a table:

```
## Library: Seating (12 items)

| Product | Brand | Dims | Price | Tags |
|---------|-------|------|-------|------|
| Outline Sofa 3-Seater | Muuto | 220×84×71cm | $4,895 | lounge, scandi |
| Aeron Chair | Herman Miller | — | $1,395 | task, ergonomic |
| ...
```

### 4. Organize

The designer can organize at any time:

- **Tag**: "Tag the Muuto sofa as 'client-project-x'" → adds tag
- **Collect**: "Create a collection called 'reception-inspo' with the Outline and the Tip Lamp" → creates/adds
- **Note**: "Note on the Aeron — check if we can get Grade B fabric" → appends to notes
- **Status**: "Shortlist the Outline" → changes status to `shortlisted`
- **Remove**: "Remove the Aeron from the library" → deletes the entry
- **Edit**: "Update the Outline price to $4,500" → edits field

When the designer references a product by partial name ("the Muuto sofa", "that walnut bench"), match against the library. If ambiguous, show options and ask.

### 5. Compare

When asked to compare products:

```
## Comparison: Task Chairs

| | Aeron | Cosm | Steelcase Leap |
|--|-------|------|----------------|
| Brand | Herman Miller | Herman Miller | Steelcase |
| Price | $1,395 | $1,195 | $1,289 |
| W×D×H | 27×27×41 in | 26×24×39 in | 27×25×40 in |
| Materials | Mesh, aluminum | Mesh, die-cast | Fabric, steel |
| Sustainability | — | GREENGUARD Gold | Level 2, C2C |
| Tags | task, ergonomic | task, minimal | task, ergonomic |
| Notes | Check Grade B | — | Best lumbar |
```

### 6. Web Search

When the designer asks to find products (not just capture existing ones):

1. **Search** the web using WebSearch for relevant products
2. **Present** findings as candidates — don't auto-add to library
3. **Let the designer pick** which to capture
4. **Fetch full specs** from selected URLs and add to library

Example: "Find me sustainable acoustic panels under $300"
→ Search, present 5-8 options with key specs, let designer say "save #1, #3, #5"

### 7. Export & Handoff

When the designer wants to use the library data downstream:

- **"Export the reception-inspo collection"** → Write as CSV in the standard FF&E schema (compatible with `/product-spec-bulk-cleanup`)
- **"Clean up my shortlist"** → Export shortlisted items, then suggest running `/product-spec-bulk-cleanup`
- **"Get images for everything in the lighting collection"** → Export image URLs, suggest `/product-image-processor`
- **"Export to Google Sheets"** → Write to a specified sheet using the MCP tools

Export CSV uses the same format as `/product-spec-bulk-fetch`:
```
Product Name,Brand,Collection,Category,W,D,H,Unit,Materials,Colors/Finishes,Price,Currency,Lead Time,URL,Image URL
```

Additional fields (tags, notes, collections, status, sustainability) are appended as extra columns.

## Library Management

### Stats

When asked "how's the library?" or "library stats":

```
## Product Library — 47 items
Last updated: 2026-03-13

By category: Seating (14), Lighting (11), Tables (8), Storage (6), Acoustic (4), Other (4)
By status: Saved (38), Shortlisted (7), Ordered (2)
Collections: reception-inspo (6), home-office (4), project-oak (12)
Top brands: Muuto (8), HAY (6), Herman Miller (5), Steelcase (4)

5 items missing dimensions · 3 items missing price
```

### Merge & Dedup

If the designer adds a product that matches an existing entry (same product name + brand, or same URL):

> "This looks like the **Outline Sofa** already in your library (added Mar 10). Update it with new info, or save as a separate entry?"

### Backup

When the library grows past 50 items, suggest a backup:

> "Your library has 52 items now. Want me to export a backup CSV?"

## Conversation Style

This skill runs in companion mode. Keep responses **short and natural**:

- After a capture: show the card, move on
- After a search: show results, wait for picks
- After a recall: show the table, offer next actions
- Don't over-explain — the designer knows what they're looking for

When the conversation is clearly about product research, stay in this mode. Don't re-introduce yourself or explain the library concept each time.

If the designer asks something unrelated to product research, respond normally — this skill doesn't take over the whole conversation.

## First Run

On first invocation, if no library file is found:

1. Ask where to store the library
2. Create an empty library file: `{"version": 1, "items": [], "collections": []}`
3. Brief intro:

> "Product library created. Drop URLs, PDFs, or screenshots anytime and I'll capture them. You can also ask me to search for products or recall what's saved."

That's it — don't over-explain. Let the designer start browsing.
