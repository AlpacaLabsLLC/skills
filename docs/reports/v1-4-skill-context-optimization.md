# v1.4 skill context optimization

Measured with `scripts/audit-skill-context.sh`. Characters, words, and lines are exact local counts. Estimated tokens use the explicitly approximate formula `ceil(characters / 4)`; they are not provider token counts and no external service is called.

| Measure | Baseline | Final | Delta |
|---|---:|---:|---:|
| Skills discovered | 46 | 50 | +4 |
| Description characters | 12,990 | 12,081 | -909 (-7.0%) |
| Description estimated tokens | 3,266 | 3,041 | -225 (-6.9%) |
| Skill-body characters | 387,881 | 445,191 | +57,310 (+14.8%) |

The standing-description reduction preserves distinguishing positive and negative routes in high-risk pairs: workplace programming versus code occupancy, EPD write versus parse/find/compare, product research versus image matching/pairing, and NYC base zoning versus BSA relief/3D visualization.

Progressive disclosure in this pass extracted the 120-line inline image processor into `skills/resize-images/scripts/resize_images.py` and changed the slide-deck startup from a 22-row table dump to loading the existing `slide-types.md` reference when needed. The larger zoning, EPD, workplace, occupancy, and SIF bodies still need deeper output-parity fixtures before bulk movement; they were intentionally left in place rather than moved without enough verification.

The final column is the integrated checkout measurement, including correctness, interface, and cross-harness compatibility changes merged after the initial optimization lane, the three commercial-records skills (proposal, agreement, invoice), and the read-only architecture-knowledge skill added afterwards. The body increase has three causes: the concise Codex/Claude invocation and path-resolution contract added to every bundled skill, the three commercial-record skill bodies, and the architecture-knowledge instruction surface; its detailed source corpus stays in on-demand reference files. `tests/test-context-audit.sh` reconciles these retained totals with a fresh local audit so later changes cannot silently make the evidence stale.
