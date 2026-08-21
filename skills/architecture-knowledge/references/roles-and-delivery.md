# Roles and delivery

## AK-OWNER

- **Canonical term:** Owner
- **Aliases:** client, project owner
- **Authority class:** first-party
- **Boundaries:** The actual parties and duties are defined by the governing agreements.
- **Source IDs:** SRC-AIA-B101-2017, SRC-AIA-A201-2017
- `A1` | The owner is a principal project participant in the AIA agreement and construction-context summaries. | Sources: `SRC-AIA-B101-2017`, `SRC-AIA-A201-2017`
- `AK-OWNER` — engages → `AK-ARCHITECT` | Sources: `SRC-AIA-B101-2017`

## AK-ARCHITECT

- **Canonical term:** Architect
- **Aliases:** design professional
- **Authority class:** first-party
- **Boundaries:** This entry does not define licensure, standard of care, or project-specific services.
- **Source IDs:** SRC-AIA-B101-2017, SRC-AIA-A201-2017
- `A1` | The architect is the design professional addressed by the B101 owner-architect relationship. | Sources: `SRC-AIA-B101-2017`
- `AK-ARCHITECT` — coordinates-with → `AK-CONTRACTOR` | Sources: `SRC-AIA-A201-2017`

## AK-CONTRACTOR

- **Canonical term:** Contractor
- **Aliases:** general contractor, builder
- **Authority class:** first-party
- **Boundaries:** Contractor duties, risk, and authority are governed by the applicable agreements and delivery method.
- **Source IDs:** SRC-AIA-A201-2017, SRC-AIA-AGC-DELIVERY
- `A1` | The contractor is a construction participant described in the A201 construction-contract context. | Sources: `SRC-AIA-A201-2017`
- `AK-CONTRACTOR` — participates-in → `AK-DESIGN-BID-BUILD` | Sources: `SRC-AIA-AGC-DELIVERY`

## AK-DESIGN-BID-BUILD

- **Canonical term:** Design-bid-build
- **Aliases:** DBB
- **Authority class:** first-party
- **Boundaries:** This describes a relationship shape only; it does not recommend a method for any project.
- **Source IDs:** SRC-AIA-AGC-DELIVERY
- `A1` | Design-bid-build is a commonly described delivery method that separates design and construction contracts. | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-DESIGN-BID-BUILD` — involves → `AK-OWNER` | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-DESIGN-BID-BUILD` — involves → `AK-ARCHITECT` | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-DESIGN-BID-BUILD` — involves → `AK-CONTRACTOR` | Sources: `SRC-AIA-AGC-DELIVERY`

## AK-CM-AT-RISK

- **Canonical term:** Construction Manager at Risk
- **Aliases:** CM at Risk, CM@R, CMR
- **Authority class:** first-party
- **Boundaries:** This describes a relationship shape only; it does not provide suitability, risk-allocation, or contract advice.
- **Source IDs:** SRC-AIA-AGC-DELIVERY
- `A1` | Construction Manager at Risk is a project-delivery term covered by the AIA/AGC public primer. | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-CM-AT-RISK` — involves → `AK-OWNER` | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-CM-AT-RISK` — involves → `AK-ARCHITECT` | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-CM-AT-RISK` — involves → `AK-CONTRACTOR` | Sources: `SRC-AIA-AGC-DELIVERY`

## AK-DESIGN-BUILD

- **Canonical term:** Design-build
- **Aliases:** DB
- **Authority class:** first-party
- **Boundaries:** This describes a relationship shape only; it does not select a delivery method or contract form.
- **Source IDs:** SRC-AIA-AGC-DELIVERY
- `A1` | Design-build places design and construction under one owner-to-design-build-entity relationship. | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-DESIGN-BUILD` — involves → `AK-OWNER` | Sources: `SRC-AIA-AGC-DELIVERY`
- `AK-DESIGN-BUILD` — distinct-from → `AK-DESIGN-BID-BUILD` | Sources: `SRC-AIA-AGC-DELIVERY`
