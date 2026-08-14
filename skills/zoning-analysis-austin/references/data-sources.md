# Austin zoning data sources

Use this hierarchy. Prefer the most specific current official record and disclose conflicts.

## Parcel, jurisdiction, and zoning

| Purpose | Official source | Use |
|---|---|---|
| Primary property research | [City of Austin Property Profile](https://maps.austintexas.gov/GIS/PropertyProfile/) | Resolve parcel context, zoning, overlays, cases, environmental layers, and downloadable reports. |
| Zoning polygon geometry | [City zoning ArcGIS service](https://maps.austintexas.gov/gis/rest/Shared/Zoning_1/MapServer/0) | Intersect the parcel with actual zoning polygons and request geometry. |
| Address-to-zoning locator | [Zoning By Address](https://data.austintexas.gov/Building-and-Development/Zoning-By-Address/nbzi-qabm) | Locator only; the City warns that it omits some overlays and split zoning and may be out of date. |
| Available Property Profile layers | [Property Profile Layers](https://maps.austintexas.gov/GIS/Resources/Documents/PropertyProfileLayers.pdf) | Identify current parcel, case, permit, historic, environmental, and infrastructure layers. |
| Appraisal identifier and public appraisal facts | [Travis Central Appraisal District](https://traviscad.org/) | Resolve geographic/property ID and appraisal records; do not treat appraisal data as a zoning determination. |

## Regulations and ordinances

| Purpose | Official source | Use |
|---|---|---|
| Current Land Development Code | [City and Land Development Code](https://www.austintexas.gov/planning/city-and-land-development-code) | Follow links to the current official code host and applicable Titles 25 and 30. |
| Districts, uses, and site regulations | [Zoning Resources and Site Regulations](https://www.austintexas.gov/planning/zoning-resources-site-regulations) | Locate base-district definitions, permitted-use chart, and design standards. |
| Official zoning verification route | [Austin zoning FAQs](https://www.austintexas.gov/planning/frequently-asked-questions-faqs) | Follow the City's process for legal zoning verification when required. |
| Site-specific legislation | City Council ordinance record linked from Property Profile or zoning text | Retrieve the adopted ordinance, exhibits, conditions, and amendments. Do not summarize a conditional overlay from its suffix alone. |

## Permits, cases, compliance, and relief

| Purpose | Official source | Use |
|---|---|---|
| Permit and development-case search | [Austin Build + Connect and public tools](https://www.austintexas.gov/development-services/codes-resources-tools) | Search permits, plan-review cases, inspections, and public case records. |
| Complaint cases | [Austin Code Complaint Cases](https://data.austintexas.gov/Public-Safety/Austin-Code-Complaint-Cases/6wtj-zbtb) | Identify reported complaint cases; distinguish complaints from adjudicated violations. |
| Variances and appeals | [Austin Board of Adjustment](https://www.austintexas.gov/boards-commissions/board/board-adjustment) | Check agendas, backup, decisions, and applicable case records. |
| Historic status | [Historic Properties](https://www.austintexas.gov/planning/historic-preservation/historic-properties) | Check local landmarks, local districts, National Register districts, and surveyed potential resources. |

## Ownership and recorded instruments

City GIS and appraisal ownership fields are not title evidence. Use the appropriate county clerk's official public-record search for deeds, plats, easements, restrictions, and recorded instruments. Report document references and dates; do not issue a title opinion or infer that a search is complete.

## Currency rules

1. Capture the access date for every source.
2. Capture the dataset update date when exposed.
3. Prefer the adopted ordinance or current code provision over explanatory summaries.
4. If GIS, ordinance, appraisal, and address records conflict, report the conflict and do not choose silently.
5. Recommend formal City verification for acquisition, entitlement, or permit reliance.
