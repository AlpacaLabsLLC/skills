# PLUTO Field Reference

NYC's Primary Land Use Tax Lot Output (PLUTO) dataset contains extensive data for every tax lot in the city. This reference covers the fields most relevant to zoning analysis.

## API Access

**Endpoint:** `https://data.cityofnewyork.us/resource/64uk-42ks.json`

### Query Examples

By BBL (10-digit):
```
?bbl=1005670032
```

By address:
```
?$where=address='350 5 AVENUE' AND zipcode='10118'
```

By block and lot in a borough:
```
?borocode=1&block=00567&lot=0032
```

With field selection (faster):
```
?bbl=1005670032&$select=bbl,address,zonedist1,overlay1,spdist1,lotarea,residfar,commfar,facilfar,builtfar,numfloors,splitzone,landmark,histdist,ltdheight
```

### Response Format

JSON array. A single lot returns an array with one object. Empty array means no match.

## Key Fields

### Identification
| Field | Description | Example |
|-------|-------------|---------|
| `bbl` | Borough-Block-Lot (10 digits) | `1005670032` |
| `borocode` | Borough: 1=MN, 2=BX, 3=BK, 4=QN, 5=SI | `1` |
| `block` | Tax block (5 digits, zero-padded) | `00567` |
| `lot` | Tax lot (4 digits, zero-padded) | `0032` |
| `address` | Street address | `350 5 AVENUE` |
| `zipcode` | ZIP code | `10118` |

### Zoning Districts
| Field | Description | Example |
|-------|-------------|---------|
| `zonedist1` | Primary zoning district | `C5-3` |
| `zonedist2` | Secondary district (split lots) | `R8` |
| `zonedist3` | Third district (rare) | |
| `zonedist4` | Fourth district (very rare) | |
| `overlay1` | Commercial overlay 1 | `C1-5` |
| `overlay2` | Commercial overlay 2 | |
| `spdist1` | Special purpose district 1 | `MiD` |
| `spdist2` | Special purpose district 2 | |
| `spdist3` | Special purpose district 3 | |
| `ltdheight` | Limited height district | `LH-1` |
| `splitzone` | Split across multiple zones | `Y` |
| `zonemap` | Zoning map sheet number | `8d` |

### Lot Dimensions
| Field | Description | Unit |
|-------|-------------|------|
| `lotarea` | Total lot area | SF |
| `lotfront` | Lot frontage | Feet |
| `lotdepth` | Lot depth | Feet |
| `lottype` | Lot configuration | See codes |

Lot type codes:
- `5` = Inside lot
- `1` = Corner
- `2` = Through (front and rear streets)
- `3` = Waterfront
- `4` = Irregular

### Building Data
| Field | Description | Unit |
|-------|-------------|------|
| `bldgarea` | Total gross building area | SF |
| `numbldgs` | Number of buildings on lot | Count |
| `numfloors` | Number of floors | Count |
| `bldgfront` | Building frontage | Feet |
| `bldgdepth` | Building depth | Feet |
| `bldgclass` | DOF building class (2-char) | e.g., `O4` |
| `yearbuilt` | Year built (or 0 if unknown) | Year |
| `yearalter1` | Most recent alteration year | Year |
| `yearalter2` | Second most recent alteration | Year |

### FAR (Floor Area Ratio)
| Field | Description |
|-------|-------------|
| `builtfar` | Current as-built FAR |
| `residfar` | Max permitted residential FAR |
| `commfar` | Max permitted commercial FAR |
| `facilfar` | Max permitted community facility FAR |

**Note:** These FAR values are from DCP's zoning calculations and generally reflect as-of-right maximums. They may not account for bonuses (inclusionary housing, landmark transfer, etc.).

### Land Use
| Field | Description |
|-------|-------------|
| `landuse` | Two-digit land use code |

Land use codes:
| Code | Use |
|------|-----|
| 01 | One & Two Family Buildings |
| 02 | Multi-Family Walk-Up Buildings |
| 03 | Multi-Family Elevator Buildings |
| 04 | Mixed Residential & Commercial |
| 05 | Commercial & Office Buildings |
| 06 | Industrial & Manufacturing |
| 07 | Transportation & Utility |
| 08 | Public Facilities & Institutions |
| 09 | Open Space & Recreation |
| 10 | Parking Facilities |
| 11 | Vacant Land |

### Designations
| Field | Description | Example |
|-------|-------------|---------|
| `landmark` | Individual landmark name | `EMPIRE STATE BUILDING` |
| `histdist` | Historic district name | `TRIBECA EAST` |
| `edesignat` | Environmental designation | `E-342` |

### Geographic
| Field | Description |
|-------|-------------|
| `cd` | Community district number |
| `ct2010` | Census tract (2010) |
| `cb2010` | Census block (2010) |
| `council` | City council district |
| `schooldist` | School district |
| `firecomp` | Fire company |
| `policeprct` | Police precinct |
| `latitude` | Lot centroid latitude |
| `longitude` | Lot centroid longitude |

## Interpreting Split-Zone Lots

When `splitzone = Y`, the lot straddles two or more zoning districts.

- `zonedist1` is the primary district (covers the largest portion)
- `zonedist2` through `zonedist4` are additional districts
- PLUTO does not indicate what percentage of the lot is in each district
- The `residfar`, `commfar`, and `facilfar` values reflect the HIGHEST applicable FAR
- For accurate analysis of split lots, recommend the user check ZoLa to see the zone boundary on the lot

## Common Queries

**All lots in a zoning district:**
```
?zonedist1=R7A&borocode=3&$limit=50
```

**Vacant lots in an area:**
```
?landuse=11&zipcode=11201&$limit=50
```

**Lots with unused FAR:**
```
?$where=residfar > builtfar AND borocode='1'&$limit=50&$select=bbl,address,lotarea,builtfar,residfar,numfloors
```
