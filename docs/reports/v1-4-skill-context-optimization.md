# v1.4 skill context optimization

Measured with `scripts/audit-skill-context.sh`. Characters, words, and lines are exact local counts. Estimated tokens use the explicitly approximate formula `ceil(characters / 4)`; they are not provider token counts and no external service is called.

| Measure | Baseline | Final | Delta |
|---|---:|---:|---:|
| Skills discovered | 46 | 46 | 0 |
| Description characters | 12,990 | 10,683 | -2,307 (-17.8%) |
| Description estimated tokens | 3,266 | 2,691 | -575 (-17.6%) |
| Skill-body characters | 387,881 | 408,326 | +20,445 (+5.3%) |

The standing-description reduction preserves distinguishing positive and negative routes in high-risk pairs: workplace programming versus code occupancy, EPD write versus parse/find/compare, product research versus image matching/pairing, and NYC base zoning versus BSA relief/3D visualization.

Progressive disclosure in this pass extracted the 120-line inline image processor into `skills/resize-images/scripts/resize_images.py` and changed the slide-deck startup from a 22-row table dump to loading the existing `slide-types.md` reference when needed. The larger zoning, EPD, workplace, occupancy, and SIF bodies still need deeper output-parity fixtures before bulk movement; they were intentionally left in place rather than moved without enough verification.

The final column is the integrated checkout measurement, including correctness, interface, and cross-harness compatibility changes merged after the initial optimization lane. The body increase comes from the concise Codex/Claude invocation and path-resolution contract added to every bundled skill. `tests/test-context-audit.sh` reconciles these retained totals with a fresh local audit so later changes cannot silently make the evidence stale.
