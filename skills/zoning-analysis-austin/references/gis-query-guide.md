# Austin GIS query guide

Use `scripts/austin_property_lookup.py` for the repeatable first-pass lookup. It returns JSON from official City services and requires only Python's standard library.

```bash
python3 scripts/austin_property_lookup.py "3232 E CESAR CHAVEZ ST" --pretty
```

Run it from the skill directory or use its absolute path. Treat its output as screening evidence, not a zoning verification letter.

## Interpretation rules

- The City address locator supplies the point, place ID, jurisdiction, and normalized address.
- The appraisal layer supplies screening parcel geometry and identifiers. Its calculated area is not a survey or legal acreage.
- Zoning must be read from all returned GIS features. The Socrata Zoning By Address response is corroboration only.
- `ordinances_at_address_point` is a retrieval list. Open every linked ordinance and amendment, identify the applicable tract or exhibit, and extract use and site-development conditions.
- Environmental checks use the parcel bounding envelope because ArcGIS polygon-ring orientation is fragile across clients. This deliberately may over-report edge intersections. Confirm positive results against the parcel polygon and controlling maps; describe negative results as “no mapped intersection returned,” never “none exists.”
- If a service fails, report that layer as `Not verified`; do not convert a failed or absent response to zero.

## Known follow-up gaps

The script does not determine permitted uses, interpret ordinances, retrieve site-plan documents, evaluate compatibility, locate protected trees, search recorded instruments, or establish vested rights. Those require the regulatory workflow in `SKILL.md`.
