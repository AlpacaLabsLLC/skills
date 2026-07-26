# Professional Disclaimer

These rules govern how skill outputs are framed relative to professional practice.

## Required Disclaimer

Every skill output that includes code analysis, structural assumptions, zoning interpretations, or life-safety calculations must end with the canonical disclaimer block followed by a machine-readable marker. Both lines, in this order, with one blank line between them:

```markdown
> **Disclaimer:** This is an AI-generated analysis for preliminary planning purposes. All findings must be verified by a licensed professional before use in design, permitting, or regulatory submissions.

<!-- architecture-studio:requires-disclaimer -->
```

The HTML-comment marker is invisible in rendered Markdown but is parsed by the `post-write-disclaimer-check` hook to verify the canonical block is present. Do not place the marker anywhere else in the document — it is a single end-of-file sentinel.

## Language Rules

- **Never say** "this complies with [code]" — say "this appears consistent with [code section]"
- **Never say** "this is code-compliant" — say "based on [code section], this appears to meet the requirement"
- **Never say** "no violations" — say "no violations were identified in the data reviewed"
- **Never present** AI analysis as a substitute for stamped drawings, engineering calculations, or professional review
- **Never claim** completeness — say "based on available data" or "from the sources reviewed"

## When to Include

Include the disclaimer on:
- Zoning envelope calculations
- Occupancy load calculations
- Code compliance checks
- Structural or MEP assumptions
- Environmental risk assessments (flood, seismic, soil)
- Any output the user might submit to a client or authority
- Site visit reports that are client-facing, authority-facing, issued externally,
  or contain regulated analysis or professional conclusions

Omit the disclaimer on:
- Product research and FF&E schedules (informational, not regulatory)
- Presentation decks (aesthetic output)
- Color palettes
- Data formatting and conversion tasks (CSV, SIF)
- Purely internal administrative site-visit drafts that contain only observations,
  logistics, photo/file references, limitations, and follow-up coordination, with
  no regulated conclusion

Omission never permits a site report to claim concealed-condition certainty,
compliance, completeness, or professional verification. If intended use is
uncertain, include the disclaimer.
