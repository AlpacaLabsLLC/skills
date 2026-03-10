#!/usr/bin/env python3
"""
Slantis Talent Evaluation Pipeline
Evaluates 432 candidates against 10-dimension competency rubric using Claude API.
"""

import asyncio
import csv
import json
import os
import sys
import time
from pathlib import Path

import anthropic
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

from rubric import (
    SYSTEM_PROMPT,
    USER_PROMPT_TEMPLATE,
    DIMENSION_KEYS,
    DIMENSIONS,
    format_candidate,
)

TALENT_DIR = Path(__file__).parent
INPUT_CSV = TALENT_DIR / "candidates_all.csv"
OUTPUT_CSV = TALENT_DIR / "evaluations.csv"
OUTPUT_REPORT = TALENT_DIR / "evaluation_report.md"
RAW_JSON_DIR = TALENT_DIR / "eval_raw"

MODEL = "claude-haiku-4-5-20251001"
MAX_CONCURRENT = 10
MAX_RETRIES = 3


def load_candidates():
    with open(INPUT_CSV, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    return rows, fieldnames


async def evaluate_candidate(client, row, fieldnames, semaphore, idx, total):
    """Evaluate a single candidate via Claude API."""
    name = row.get("What's your full name?", "Unknown")

    async with semaphore:
        candidate_text = format_candidate(row, fieldnames)
        user_prompt = USER_PROMPT_TEMPLATE.format(candidate_text=candidate_text)

        for attempt in range(MAX_RETRIES):
            try:
                response = await asyncio.to_thread(
                    client.messages.create,
                    model=MODEL,
                    max_tokens=1024,
                    system=SYSTEM_PROMPT,
                    messages=[{"role": "user", "content": user_prompt}],
                )

                text = response.content[0].text.strip()
                # Clean potential markdown wrapping
                if text.startswith("```"):
                    text = text.split("\n", 1)[1]
                    if text.endswith("```"):
                        text = text[:-3]
                    text = text.strip()

                result = json.loads(text)

                # Validate structure
                for key in DIMENSION_KEYS:
                    if key not in result:
                        raise ValueError(f"Missing dimension: {key}")

                composite = sum(result[k]["score"] for k in DIMENSION_KEYS)
                result["_composite"] = composite
                result["_name"] = name

                print(f"  [{idx+1}/{total}] {name}: composite={composite}")
                return result

            except json.JSONDecodeError as e:
                print(f"  [{idx+1}/{total}] {name}: JSON parse error (attempt {attempt+1}): {e}")
                if attempt == MAX_RETRIES - 1:
                    return make_error_result(name, f"JSON parse error: {e}")

            except anthropic.RateLimitError:
                wait = 2 ** (attempt + 1)
                print(f"  [{idx+1}/{total}] {name}: Rate limited, waiting {wait}s...")
                await asyncio.sleep(wait)

            except Exception as e:
                print(f"  [{idx+1}/{total}] {name}: Error (attempt {attempt+1}): {e}")
                if attempt == MAX_RETRIES - 1:
                    return make_error_result(name, str(e))

    return make_error_result(name, "Max retries exceeded")


def make_error_result(name, error):
    result = {"_name": name, "_composite": 0, "_error": error}
    for key in DIMENSION_KEYS:
        result[key] = {"score": 0, "confidence": "none", "evidence": f"Error: {error}"}
    return result


async def run_evaluations(candidates, fieldnames):
    client = anthropic.Anthropic()
    semaphore = asyncio.Semaphore(MAX_CONCURRENT)
    total = len(candidates)

    print(f"Evaluating {total} candidates with {MODEL}...")
    print(f"Concurrency: {MAX_CONCURRENT}")
    start = time.time()

    tasks = [
        evaluate_candidate(client, row, fieldnames, semaphore, i, total)
        for i, row in enumerate(candidates)
    ]

    results = await asyncio.gather(*tasks)

    elapsed = time.time() - start
    print(f"\nDone in {elapsed:.0f}s ({elapsed/total:.1f}s per candidate)")

    return results


def write_csv(results, candidates):
    """Write evaluation results to CSV."""
    header = ["name", "email", "source_sheet", "form_variant", "currency", "composite"]
    for key in DIMENSION_KEYS:
        header.extend([f"{key}_score", f"{key}_confidence", f"{key}_evidence"])
    header.append("error")

    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)

        for res, cand in zip(results, candidates):
            row = [
                res.get("_name", ""),
                cand.get("Dirección de correo electrónico", ""),
                cand.get("_source_sheet", ""),
                cand.get("_form_variant", ""),
                cand.get("_currency", ""),
                res.get("_composite", 0),
            ]
            for key in DIMENSION_KEYS:
                d = res.get(key, {})
                row.extend([d.get("score", 0), d.get("confidence", ""), d.get("evidence", "")])
            row.append(res.get("_error", ""))
            writer.writerow(row)

    print(f"Results written to: {OUTPUT_CSV}")


def write_raw_json(results):
    """Save raw JSON results for debugging."""
    RAW_JSON_DIR.mkdir(exist_ok=True)
    for res in results:
        name = res.get("_name", "unknown").replace(" ", "_").replace("/", "_")[:50]
        path = RAW_JSON_DIR / f"{name}.json"
        with open(path, "w", encoding="utf-8") as f:
            json.dump(res, f, indent=2, ensure_ascii=False)


def write_report(results):
    """Generate summary report."""
    valid = [r for r in results if not r.get("_error")]
    errors = [r for r in results if r.get("_error")]

    lines = []
    a = lines.append

    a("# Talent Evaluation Report")
    a("")
    a(f"**Model:** {MODEL}")
    a(f"**Candidates evaluated:** {len(valid)} successful, {len(errors)} errors")
    a(f"**Dimensions:** {len(DIMENSION_KEYS)}")
    a("")

    # Distribution per dimension
    a("## Score Distribution")
    a("")
    a("| Dimension | Avg | Median | 1 | 2 | 3 | 4 | 5 |")
    a("|-----------|-----|--------|---|---|---|---|---|")

    for dim in DIMENSIONS:
        key = dim["key"]
        scores = [r[key]["score"] for r in valid if r.get(key, {}).get("score")]
        if not scores:
            continue
        avg = sum(scores) / len(scores)
        scores_sorted = sorted(scores)
        median = scores_sorted[len(scores_sorted) // 2]
        dist = {i: scores.count(i) for i in range(1, 6)}
        a(f"| {dim['name']} | {avg:.1f} | {median} | {dist.get(1,0)} | {dist.get(2,0)} | {dist.get(3,0)} | {dist.get(4,0)} | {dist.get(5,0)} |")

    # Confidence distribution
    a("")
    a("## Confidence Distribution")
    a("")
    a("| Dimension | High | Medium | Low |")
    a("|-----------|------|--------|-----|")

    for dim in DIMENSIONS:
        key = dim["key"]
        confs = [r[key]["confidence"] for r in valid if r.get(key, {}).get("confidence")]
        high = sum(1 for c in confs if c == "high")
        med = sum(1 for c in confs if c == "medium")
        low = sum(1 for c in confs if c == "low")
        a(f"| {dim['name']} | {high} | {med} | {low} |")

    # Top 20 candidates
    a("")
    a("## Top 20 Candidates (by composite)")
    a("")
    a("| Rank | Name | Composite | GCA | Learn | Humble | Comm | Collab | Safety | Depend | Purpose | Impact | Cares |")
    a("|------|------|-----------|-----|-------|--------|------|--------|--------|--------|---------|--------|-------|")

    ranked = sorted(valid, key=lambda r: -r.get("_composite", 0))
    for i, r in enumerate(ranked[:20], 1):
        scores = " | ".join(str(r.get(k, {}).get("score", 0)) for k in DIMENSION_KEYS)
        a(f"| {i} | {r['_name']} | {r['_composite']} | {scores} |")

    # Bottom 20
    a("")
    a("## Bottom 20 Candidates")
    a("")
    a("| Rank | Name | Composite | GCA | Learn | Humble | Comm | Collab | Safety | Depend | Purpose | Impact | Cares |")
    a("|------|------|-----------|-----|-------|--------|------|--------|--------|--------|---------|--------|-------|")

    for i, r in enumerate(ranked[-20:], len(ranked) - 19):
        scores = " | ".join(str(r.get(k, {}).get("score", 0)) for k in DIMENSION_KEYS)
        a(f"| {i} | {r['_name']} | {r['_composite']} | {scores} |")

    if errors:
        a("")
        a("## Errors")
        a("")
        for r in errors:
            a(f"- {r['_name']}: {r.get('_error', 'unknown')}")

    with open(OUTPUT_REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Report written to: {OUTPUT_REPORT}")


def main():
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("Error: ANTHROPIC_API_KEY not set")
        sys.exit(1)

    candidates, fieldnames = load_candidates()
    print(f"Loaded {len(candidates)} candidates from {INPUT_CSV}")

    results = asyncio.run(run_evaluations(candidates, fieldnames))

    write_csv(results, candidates)
    write_raw_json(results)
    write_report(results)

    # Quick summary
    valid = [r for r in results if not r.get("_error")]
    composites = sorted([r["_composite"] for r in valid], reverse=True)
    print(f"\nComposite score range: {composites[-1]} – {composites[0]}")
    print(f"Median composite: {composites[len(composites)//2]}")


if __name__ == "__main__":
    main()
