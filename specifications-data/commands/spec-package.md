---
description: Run a full FF&E spec extraction pipeline — fetch specs from URLs, clean up the data, and process product images.
argument-hint: [product URLs or file path with URLs]
---

Run this three-step pipeline in sequence. Complete each step fully before moving to the next.

## Step 1: Product Spec Bulk Fetch

Invoke the `/product-spec-bulk-fetch` skill with the user's product URLs. Extract product names, dimensions, materials, pricing, and images from each page. Save the output (CSV or structured data) before proceeding.

## Step 2: Product Spec Bulk Cleanup

Invoke the `/product-spec-bulk-cleanup` skill on the fetched data from Step 1. Normalize casing, translate non-English fields, standardize dimension units, and deduplicate entries.

Save the cleaned output before proceeding.

## Step 3: Product Image Processor

Invoke the `/product-image-processor` skill on the cleaned dataset from Step 2. Download, crop, and standardize product images referenced in the spec sheet.

## Handoff

Between each step, confirm the data carried forward:
- **After Step 1:** Number of products fetched (successful / partial / failed), output file path
- **After Step 2:** Number of records cleaned, fields normalized, duplicates removed
- **After Step 3:** Number of images processed, output directory, any failed downloads
