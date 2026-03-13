# Slide Deck Generator

A Claude Code skill that generates self-contained HTML slide decks with an editorial design system.

## Usage

```
/slide-deck-generator
```

Provide a topic, outline, data, or document and the skill produces a single `.html` file you can open in any browser — no dependencies, no build step.

## Design System

- **Font:** Helvetica Neue
- **Layout:** Left-aligned by default, generous whitespace, editorial feel
- **Palette:** Monochrome (black, white, greys) with a warm yellow accent (`#E8B517`) on the progress bar
- **Brand mark:** "ALPA" fixed bottom-right on every slide
- **Page numbers:** Auto-injected top-right (skips first and last slide)

### Backgrounds

| Class | Color | Use |
|-------|-------|-----|
| *(default)* | White `#fff` | Content, lists, titles |
| `grey` | Light grey `#f5f5f3` | Tables, stats, alternating rhythm |
| `dark` | Dark `#1a1a1a` | Statement slides (1–2 per deck max) |

## Slide Types

22 slide types organized into five categories:

### Title Slides
| # | Type | Description |
|---|------|-------------|
| 1 | Image + Title | Full-bleed cover image with gradient overlay, h1 + subtitle |
| 2 | Text Only Title | Left-aligned h1 + subtitle + credit on white (fallback) |

### Content Slides
| # | Type | Description |
|---|------|-------------|
| 3 | Heading + Body | Eyebrow + h2 + paragraph — the workhorse slide |
| 4 | Heading + List | Eyebrow + h2 + bullet list |
| 5 | Heading + Stats | Eyebrow + h2 + vertical stat lines |
| 12 | Insight List | Eyebrow + h2 + numbered items with bold leads |
| 15 | Two Column | Eyebrow + h2 + side-by-side text |

### Data Slides
| # | Type | Description |
|---|------|-------------|
| 6 | Stat Row | Large centered numbers in columns |
| 7 | Stat Comparison | Before/after with arrows and change indicators |
| 8 | Heading + Stat Row | Eyebrow + h2 + stat columns (centered) |
| 11 | Data Table | Eyebrow + h2 + table with dotted borders |
| 13 | Bar Chart | Eyebrow + h2 + horizontal bars |
| 14 | Timeline | Eyebrow + h2 + phased dots (centered) |
| 16 | Comparison | Eyebrow + h2 + before/after boxes with arrow |

### Statement Slides
| # | Type | Description |
|---|------|-------------|
| 9 | Statement (white) | Bold centered text on white |
| 10 | Statement (dark) | Bold centered text on dark |

### Image Slides
| # | Type | Description |
|---|------|-------------|
| 17 | Full Bleed | Single image, edge to edge |
| 18 | Full Bleed + Title | Full image with gradient + overlaid text |
| 19 | Split 2 | Two images side by side |
| 20 | Split 3 | Three images in a row |
| 21 | Split 4 | 2x2 grid |
| 22 | Split 6 | 3x2 grid |

Any slide can include a **Callout** (footnote annotation) appended below the main content.

## Navigation

The generated deck includes built-in navigation:

- **Keyboard:** Arrow keys or spacebar
- **Touch:** Swipe left/right
- **Buttons:** Arrow buttons fixed at bottom center
- **Progress bar:** Yellow accent bar at the top of the viewport

## Deck Structure Guidelines

1. **First slide** — Image + Title cover (or text-only fallback)
2. **Second slide** — Context or framing question
3. **Middle slides** — Alternate white/grey backgrounds, build the argument
4. **Penultimate slide** — Recommendations or next steps
5. **Last slide** — Closing statement or sign-off

## Writing Style

- **Headlines:** Short, declarative, opinionated — state the insight, not the topic
- **Body text:** Lightweight, factual, 2–3 lines max
- **Stats:** Pick the most dramatic number, give it context
- **Tables:** 4–6 rows max with colored change indicators
- **Lists:** Bold lead + detail after an em dash

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Full skill prompt with HTML template, CSS, JS, and all component markup |
| `sample.html` | Reference deck demonstrating all 22 slide types |
| `README.md` | This file |

## Custom Accent Colors

The default accent is warm yellow (`#E8B517`). Override `--accent` in the CSS `:root` block for brand-specific decks:

- Blue: `#2563EB`
- Teal: `#0D7377`
- Purple: `#6B21A8`
- Orange: `#C2410C`

## Related

- Fork the skill and swap fonts, colors, and the brand mark for your own design system
