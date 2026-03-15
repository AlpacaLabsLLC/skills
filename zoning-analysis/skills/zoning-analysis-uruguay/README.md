# /zoning-analysis-uruguay

Zoning envelope analyzer for lots in Maldonado, Uruguay as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill. Paste GIS JSON from the [Maldonado cadastral portal](https://ide.maldonado.gub.uy/) and get a full building envelope analysis based on the TONE (Texto Ordenado de Normas de Edificación) regulations.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

## Install

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/zoning-analysis
```

## Usage

```
/zoning-analysis-uruguay
```

Then paste the GIS JSON from the Maldonado ArcGIS cadastral portal. The skill:

1. **Parses GIS data** — extracts lot geometry from EPSG:3857 Web Mercator coordinates
2. **Calculates dimensions** — converts to real-world meters, verifies against reported area
3. **Determines the zone** — matches locality + block to TONE sector/zone (asks for confirmation when ambiguous)
4. **Calculates the envelope** — height, setbacks, occupation factors (FOS/FOT), permitted building types
5. **Presents the analysis** — structured markdown with tables and ASCII buildable-zone sketch

## Sample Output

```
# Zoning Envelope Analysis — Padrón 17640, La Barra

## Lot Data
| Parameter    | Value              |
|--------------|--------------------|
| Padrón       | 17640              |
| Manzana      | 42                 |
| Location     | La Barra           |
| Area         | 1,535 m²           |
| Regime       | Propiedad Común    |
| Dimensions   | ~35 m × 44 m      |

## Applicable Zone
**Zona 1.3** — Predios frentistas a la Ruta 10 (Art. D.265)

## Building Envelope

### Occupation Factors
| Factor | %    | m²      |
|--------|------|---------|
| FOS SS | 50%  | 768 m²  |
| FOS    | 40%  | 614 m²  |
| FOS V  | 20%  | 307 m²  |
| FOT    | 105% | 1,613 m²|

### Height
| Parameter  | Value      |
|------------|------------|
| Max height | 9 m        |
| Floors     | PB+PA+PH   |

### Setbacks
| Direction  | Distance | Notes                    |
|------------|----------|--------------------------|
| Front      | 5 m      | Ruta 10 frontage         |
| Lateral 1  | 3 m      |                          |
| Lateral 2  | 3 m      |                          |
| Rear       | 3 m      |                          |

## Buildable Envelope Sketch
    ┌───────────────────────────┐
    │         3m rear           │
    ├───┬───────────────────┬───┤
    │   │                   │   │
    │ 3m│   BUILDABLE ZONE  │3m │
    │   │     614 m² FOS    │   │
    │   │                   │   │
    ├───┴───────────────────┴───┤
    │     5m front (Ruta 10)    │
    └───────────────────────────┘
```

## Coverage

Normativa files are bundled for the following localities:

| Locality | TONE Section | Zones | Status |
|----------|-------------|-------|--------|
| La Barra | Título III, Cap. II, Sector 1 | 1.1–1.6 | Complete |
| Manantiales | Título III, Cap. II, Sector 1 | 1.1–1.6 | Complete |
| Maldonado | Título II, Cap. II, Sector 2 | 2.1–2.5 (14 subzones) | Complete |
| San Carlos | Título V, Cap. I, Sector 1 | 1.1–1.5 | Complete |
| Garzón | Título V, Cap. II, Sector 2 | 2.1 (3 subzones) | Complete |
| Aiguá | Título V, Cap. II, Sector 2 | 2.2 (4 subzones) | Complete |
| Pan de Azúcar | Título V, Cap. II, Sector 2 | 2.3 | Complete |
| José Ignacio | Título III, Cap. III | — | Partial |
| Punta del Este | Título II, Cap. II, Sector 1 | 1.1–1.3 (Faro, Centro, La Pastora) | Complete |
| Piriápolis | Título IV, Cap. II | — | Not yet |

For unmapped localities, the skill fetches regulations from the [Digesto Departamental](https://digesto.maldonado.gub.uy/) and offers to save them locally for future use.

## File Structure

```
zoning-analysis-uruguay/
├── SKILL.md                              # Skill instructions and workflow
└── normativa/
    ├── location-map.md                   # nomloccat → TONE sector/zone mapping
    ├── titulo-ii-cap-ii-sector-2.md      # Maldonado (5 zones, 14 subzones)
    ├── titulo-iii-cap-ii-sector-1.md     # La Barra & Manantiales (6 zones)
    ├── titulo-ii-cap-ii-sector-1.md      # Punta del Este (3 zones)
    ├── titulo-iii-cap-iii-sector-2.md    # José Ignacio (partial)
    ├── titulo-v-cap-i-sector-1.md        # San Carlos (5 zones)
    └── titulo-v-cap-ii-sector-2.md       # Garzón, Aiguá, Pan de Azúcar
```

## Customization

- **Add a locality** — create a new `normativa/titulo-*.md` file with the zone regulations, and add the mapping in `normativa/location-map.md`
- **Update regulations** — edit the normativa files when TONE amendments are published in the Digesto
- **Change output format** — edit the presentation section in `SKILL.md`

## Data Source

All normativa content is public regulatory text from the [Digesto Departamental de Maldonado](https://digesto.maldonado.gub.uy/), Volume V — TONE. No warranty of completeness or accuracy — always verify with the Intendencia de Maldonado for permit applications.

## License

MIT
