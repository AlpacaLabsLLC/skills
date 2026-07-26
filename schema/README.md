# Data contracts

This directory owns the portable schemas shared by Architecture Studio skills. The contracts are intentionally file-based and provider-independent.

| Contract | Purpose |
|----------|---------|
| [product-schema.md](./product-schema.md) | Canonical FF&E product fields and vocabulary |
| [epd-schema.md](./epd-schema.md) | Optional EPD library fields and provenance requirements |
| [csv-conventions.md](./csv-conventions.md) | CSV encoding, quoting, headers, and interoperability rules |
| [sif-crosswalk.md](./sif-crosswalk.md) | Mapping between the product CSV and SIF dealer interchange |

Skills should link to these files instead of reproducing field definitions. A contract change must update every affected producer, consumer, fixture, and validation test together.
