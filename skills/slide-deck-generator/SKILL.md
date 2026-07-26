---
name: slide-deck-generator
description: Generate a self-contained HTML slide deck from a topic, outline, report, or data. Use for presentations and slide decks; not for editing PowerPoint files.
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# Presentation Generator

You generate self-contained HTML slide presentations using the ALPA (Alpaca Labs) design system — editorial layout with Helvetica, left-aligned typography, generous whitespace, and a clean monochrome palette. The user provides a topic, outline, data, or document — you produce a complete `.html` file they can open in any browser.

## Reference Files

This skill keeps its bulk material in reference files in this directory. Load them on demand:

- **[slide-types.md](slide-types.md)** — read when composing slides: the exact HTML markup for every component (eyebrow, stat rows, tables, timelines, image grids, callout, etc.). Copy these structures verbatim.
- **[html-template.md](html-template.md)** — read before writing the output file: the exact CSS/JS template the deck is built on, plus slide-structure examples. Only the slide `<div>`s inside `<body>` change.
- **[image-handling.md](image-handling.md)** — read when the user provides local images (or ran `/as:resize-images`): base64 embedding workflow, placeholder convention, file-size warnings.

## On Start

When invoked, read [slide-types.md](slide-types.md), then give the user its compact numbered list of page-type names. Do not dump the layout/background table unless the user asks for those details. Any slide can include a callout footnote.

A sample deck demonstrating every type is at `sample.html` in this skill's directory.

## Workflow

1. **Understand the input.** The user may provide:
   - A topic or title (you research/generate content)
   - An outline or bullet points (you expand into slides)
   - A document or report (you distill into a deck)
   - Data or analysis results (you visualize as stats/tables/charts)
   - Local image files or a folder (use as image slides — see [image-handling.md](image-handling.md))

2. **Plan the deck.** Before writing HTML, decide:
   - How many slides (aim for 10-20, never fewer than 6)
   - Which slide type and components each slide uses
   - The narrative arc: setup -> insight -> evidence -> recommendation -> close

3. **Embed local images.** If the user provides local image paths, encode them as base64 before writing the HTML (see [image-handling.md](image-handling.md)). This keeps the deck self-contained and portable.

4. **Write the HTML file.** Use the template in [html-template.md](html-template.md) as the foundation, with component markup from [slide-types.md](slide-types.md). Customize only the slide content inside `<body>`.

5. **Save the file.** Write to the path the user specifies, or default to `./presentation.html`. Tell the user the path so they can open it.

## Design System

### Layout Philosophy
- **Left-aligned by default.** Content is flush-left with generous left padding. Only statement slides center text.
- **Massive whitespace.** Content should breathe. Never fill the slide — leave at least 40% empty.
- **Eyebrow top-left.** Small bold monospace text in the top-left corner identifies the section.
- **Brand mark bottom-right.** A small "ALPA" wordmark sits fixed in the bottom-right corner of every slide, with two exceptions: the full-bleed image slide (type 17) and the image-grid slides (types 19-22) omit it so nothing overlaps the photography. The full-bleed + title slide (type 18) keeps it.
- **No decorative boxes or cards.** Stats, lists, and content stand on their own — no background panels or rounded containers.

### Slide Types (background classes on `.slide` div)
| Class | Background | Text | Use for |
|-------|-----------|------|---------|
| *(none)* | White (#ffffff) | Dark | Title, content, lists, tables — the default |
| `grey` | Light grey (#f5f5f3) | Dark | Tables, stat comparisons, alternating rhythm |
| `dark` | Dark (#1a1a1a) | White | Statement slides — bold centered declarations |

### Components

The exact HTML markup for every component (eyebrow, heading + body/list/stats, stat row, stat comparison, statement, data table, insight list, bar chart, timeline, two column, comparison, callout, and all image slides) is in [slide-types.md](slide-types.md). Read it before composing slides and copy the structures verbatim.

### Composition Rules
- Every content slide (not statements) should have a `eyebrow` top-left
- **Title slide**: full-bleed image with `.image-title-slide` — h1 + subtitle over gradient overlay. Falls back to white text-only title if no image is available.
- **Content slides**: white (default), left-aligned — `eyebrow` + `.content` with heading + body/list/stats
- **Statement slides**: centered text, no eyebrow — white bg for regular statements, `dark` for dramatic ones
- **Stat slides**: white or grey, centered stat-row or stat-comparison layout
- **Table slides**: white or grey, left-aligned heading + data-table
- **Dark slides**: use sparingly — at most 1-2 per deck for maximum emphasis
- **Closing slide**: white, left-aligned or centered — bold statement or summary
- Use `<span class="emphasis">` for bold inline text
- Never put more than one major component per slide (one table OR one stat-row OR one list)
- Alternate slide backgrounds for visual rhythm — never use the same type 3x in a row
- **Centered content**: Use `.slide.centered` (class on the slide div) for slides with a heading + grid, timeline, stat-row, or comparison below. These read better centered. Left-align is for heading + body text, lists, tables, and insight lists.
- Leave generous whitespace — content should occupy at most 60% of the slide

### Writing Style
- Headlines: short, declarative, opinionated. State the insight, not the topic.
  - Good: "We have 18 huddle rooms. At peak, 29 groups need one."
  - Bad: "Huddle Room Analysis"
- Subtitles and descriptions: lightweight, factual, no jargon
- Stats: pick the most dramatic number, give it context with the label
- Tables: 4-6 rows max. Use colored indicators for changes (`--negative` red for negative, `--positive` blue for positive — see Accent Color below).
- Lists: lead with the bold action/finding, follow with the detail after an em dash

## Accent Color

The default accent is `--accent: #E8B517` (warm yellow — used only on the progress bar). The design is primarily monochrome — black, white, and greys. Change indicators use `--negative: #D92B2B` (red) and `--positive: #2563EB` (blue) for data.

If the presentation is for a different brand or context, change `--accent`. Common alternatives:
- Blue: `#2563EB`
- Teal: `#0D7377`
- Purple: `#6B21A8`
- Orange: `#C2410C`

Ask the user if they want a specific accent color. If the topic suggests a brand, try to match.

## Slide Structure Rules

1. **First slide**: Always `active` — use `.image-title-slide` with a relevant cover image, h1 + subtitle over gradient. If no image is available, fall back to white text-only title (h1 + `.subtitle` + credit).
2. **Second slide**: Context or framing question — what we need to answer, what this is about.
3. **Middle slides**: Alternate between white and grey backgrounds. Use statement slides (white or dark) to break rhythm and emphasize key points. Build the argument.
4. **Stat slides**: Use `<div class="slide centered">` to center the stat-row on the page. No eyebrow needed.
5. **Statement slides**: Center the `.statement` div. No eyebrow. Use dark bg sparingly (1-2 per deck).
6. **Penultimate slide**: The ask / recommendations / next steps
7. **Last slide**: White — closing statement or summary, left-aligned or centered.

## Output

Write the complete HTML file using the Write tool, built on the exact CSS/JS in [html-template.md](html-template.md). The first slide must have class `active`. Every slide must be a direct child `<div class="slide ...">` inside body, before the `<nav>`. Add `<div class="brand-mark">ALPA</div>` to every slide except full-bleed image (`.image-slide`) and image-grid (`.image-grid`) slides, which omit it (see Layout Philosophy).
