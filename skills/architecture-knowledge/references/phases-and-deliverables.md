# Phases and deliverables

## AK-BASIC-SERVICES

- **Canonical term:** Basic Services
- **Aliases:** basic architectural services
- **Authority class:** first-party
- **Boundaries:** This is national orientation, not a statement of any project's contracted scope.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | AIA describes Basic Services as the core architectural services organized around project phases. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `AK-BASIC-SERVICES` — includes → `AK-SCHEMATIC-DESIGN` | Sources: `SRC-AIA-B101-2017`
- `AK-BASIC-SERVICES` — includes → `AK-DESIGN-DEVELOPMENT` | Sources: `SRC-AIA-B101-2017`
- `AK-BASIC-SERVICES` — includes → `AK-CONSTRUCTION-DOCUMENTS` | Sources: `SRC-AIA-B101-2017`
- `AK-BASIC-SERVICES` — includes → `AK-PROCUREMENT` | Sources: `SRC-AIA-B101-2017`
- `AK-BASIC-SERVICES` — includes → `AK-CONSTRUCTION-PHASE` | Sources: `SRC-AIA-B101-2017`

## AK-SCHEMATIC-DESIGN

- **Canonical term:** Schematic Design
- **Aliases:** SD
- **Authority class:** first-party
- **Boundaries:** The agreement, project type, and client requirements determine the actual work product.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | Schematic Design is an early Basic Services phase used to develop and communicate an initial design direction. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `AK-SCHEMATIC-DESIGN` — phase-of → `AK-BASIC-SERVICES` | Sources: `SRC-AIA-B101-2017`

## AK-DESIGN-DEVELOPMENT

- **Canonical term:** Design Development
- **Aliases:** DD
- **Authority class:** first-party
- **Boundaries:** It does not prescribe a universal drawing count, percentage, or issue package.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | Design Development advances the selected design with additional coordination and definition. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `AK-DESIGN-DEVELOPMENT` — phase-of → `AK-BASIC-SERVICES` | Sources: `SRC-AIA-B101-2017`

## AK-CONSTRUCTION-DOCUMENTS

- **Canonical term:** Construction Documents
- **Aliases:** construction-document phase
- **Authority class:** first-party
- **Boundaries:** Construction Documents are design-phase services and are not automatically the legally defined Contract Documents. The abbreviation CD is context-dependent and must be disambiguated when the surrounding usage is unclear.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | Construction Documents is a Basic Services phase in which the architect develops documents that communicate the project for its next uses. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `A2` | Exact deliverables and completion criteria remain agreement and project-specific. | Sources: `SRC-AIA-BASIC-SERVICES`
- `AK-CONSTRUCTION-DOCUMENTS` — phase-of → `AK-BASIC-SERVICES` | Sources: `SRC-AIA-B101-2017`
- `AK-CONSTRUCTION-DOCUMENTS` — distinct-from → `AK-CONTRACT-DOCUMENTS` | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-A201-2017`

## AK-PROCUREMENT

- **Canonical term:** Procurement
- **Aliases:** bidding and negotiation, procurement phase
- **Authority class:** first-party
- **Boundaries:** Procurement method and responsibilities depend on the agreement and delivery approach.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | Procurement follows development of the design information and concerns obtaining construction services through the chosen project process. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `AK-PROCUREMENT` — phase-of → `AK-BASIC-SERVICES` | Sources: `SRC-AIA-B101-2017`

## AK-CONSTRUCTION-PHASE

- **Canonical term:** Construction phase services
- **Aliases:** CA, construction administration
- **Authority class:** first-party
- **Boundaries:** This reference does not decide the architect's actual site, review, or administration duties.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | Construction phase services describe architectural services during construction under the project agreement. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `AK-CONSTRUCTION-PHASE` — phase-of → `AK-BASIC-SERVICES` | Sources: `SRC-AIA-B101-2017`

## AK-SUPPLEMENTAL-SERVICES

- **Canonical term:** Supplemental Services
- **Aliases:** supplemental service
- **Authority class:** first-party
- **Boundaries:** Whether a service is included is determined by the agreement, not by this label alone.
- **Source IDs:** SRC-AIA-B101-2017
- `A1` | B101 describes Supplemental Services as identified services that may supplement the Basic Services arrangement. | Sources: `SRC-AIA-B101-2017`
- `AK-SUPPLEMENTAL-SERVICES` — supplements → `AK-BASIC-SERVICES` | Sources: `SRC-AIA-B101-2017`

## AK-ADDITIONAL-SERVICES

- **Canonical term:** Additional Services
- **Aliases:** additional service
- **Authority class:** first-party
- **Boundaries:** This term does not establish entitlement, authorization, or payment for a particular project.
- **Source IDs:** SRC-AIA-B101-2017
- `A1` | B101 uses Additional Services for services that are addressed separately from the initial Basic Services scope. | Sources: `SRC-AIA-B101-2017`
- `AK-ADDITIONAL-SERVICES` — distinct-from → `AK-SUPPLEMENTAL-SERVICES` | Sources: `SRC-AIA-B101-2017`

## AK-CD-SET

- **Canonical term:** CD set
- **Aliases:** construction documents set, CD package
- **Authority class:** industry-shorthand
- **Boundaries:** A CD set is not a universal fixed-content package and is not a synonym for Contract Documents.
- **Source IDs:** SRC-AIA-BASIC-SERVICES
- `A1` | CD set is common shorthand for a coordinated package associated with the Construction Documents phase. | Sources: `SRC-AIA-BASIC-SERVICES`
- `A2` | Its drawings, specifications, issue purpose, and completeness remain agreement and project-specific. | Sources: `SRC-AIA-BASIC-SERVICES`
- `AK-CD-SET` — related-to → `AK-CONSTRUCTION-DOCUMENTS` | Sources: `SRC-AIA-BASIC-SERVICES`
- `AK-CD-SET` — distinct-from → `AK-CONTRACT-DOCUMENTS` | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-A201-2017`

## AK-CONTRACT-DOCUMENTS

- **Canonical term:** Contract Documents
- **Aliases:** contract document set
- **Authority class:** first-party
- **Boundaries:** The governing owner-contractor agreement and conditions determine the applicable documents; this entry does not interpret them. The abbreviation CD is context-dependent and must not be resolved without surrounding usage.
- **Source IDs:** SRC-AIA-A201-2017
- `A1` | Contract Documents are a contractual category whose applicable contents are established by the governing construction agreement and conditions. | Sources: `SRC-AIA-A201-2017`
- `AK-CONTRACT-DOCUMENTS` — distinct-from → `AK-CONSTRUCTION-DOCUMENTS` | Sources: `SRC-AIA-A201-2017`

## AK-50-PERCENT-CD

- **Canonical term:** 50% CDs
- **Aliases:** 50 percent CDs, fifty percent CD, 50% construction documents
- **Authority class:** project-or-firm-specific
- **Boundaries:** This is a project or firm milestone, not a universal B101 phase or a fixed measure of completeness.
- **Source IDs:** SRC-AIA-BASIC-SERVICES, SRC-AIA-B101-2017
- `A1` | 50% CDs is a common project or firm milestone used within Construction Documents, rather than an AIA Basic Services phase name. | Sources: `SRC-AIA-BASIC-SERVICES`, `SRC-AIA-B101-2017`
- `A2` | Its required deliverables, review purpose, and percentage meaning are agreement and project-specific. | Sources: `SRC-AIA-BASIC-SERVICES`
- `AK-50-PERCENT-CD` — milestone-within → `AK-CONSTRUCTION-DOCUMENTS` | Sources: `SRC-AIA-BASIC-SERVICES`
