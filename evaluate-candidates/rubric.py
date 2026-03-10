"""
Slantis Talent Evaluation Rubric — 10 dimensions for LLM-based candidate scoring.
"""

DIMENSIONS = [
    {
        "key": "gca",
        "name": "General Cognitive Ability",
        "critical": "Ability to solve unfamiliar problems, not recall known answers",
        "behaviors": "Breaks down ambiguity, asks clarifying questions, forms hypotheses",
        "skills": "Systems thinking, abstraction, reasoning",
        "experience": "Has succeeded in new or undefined environments",
        "traits": "Curious, sharp, intellectually humble",
    },
    {
        "key": "learning_velocity",
        "name": "Learning Velocity",
        "critical": "Ability to learn faster than the pace of change",
        "behaviors": "Rapid improvement, self-initiated learning, applies feedback",
        "skills": "Meta-learning, pattern recognition",
        "experience": "Evidence of career pivots or accelerated growth",
        "traits": "Growth-oriented, adaptive",
    },
    {
        "key": "humility_ownership",
        "name": "Humility + Ownership",
        "critical": "Strong opinions, loosely held. Admits mistakes, gives credit, owns outcomes",
        "behaviors": "Admits mistakes, gives credit, owns outcomes",
        "skills": "Self-reflection, responsibility",
        "experience": "Can clearly explain failures and lessons",
        "traits": "Grounded, low-ego, resilient",
    },
    {
        "key": "communication",
        "name": "Baseline Communication Skills",
        "critical": "Clarity over charisma. Explains complex ideas simply",
        "behaviors": "Explains complex ideas simply, writes clearly and concisely",
        "skills": "Structured thinking, storytelling",
        "experience": "Has worked cross-functionally",
        "traits": "Clear, concise, thoughtful",
    },
    {
        "key": "collaboration",
        "name": "Collaboration & Trustworthiness",
        "critical": "Teams win, not heroes. Listens, builds on others' ideas",
        "behaviors": "Listens, builds on others' ideas, follows through on commitments",
        "skills": "Active listening, empathy",
        "experience": "Strong peer references",
        "traits": "Cooperative, generous",
    },
    {
        "key": "psych_safety",
        "name": "Psychological Safety Contributor",
        "critical": "Teams perform when people feel safe",
        "behaviors": "Invites input, shows respect, tolerates dissent",
        "skills": "Emotional intelligence",
        "experience": "Has worked in diverse teams",
        "traits": "Warm, respectful, inclusive",
    },
    {
        "key": "dependability",
        "name": "Dependability",
        "critical": "Reliability beats brilliance. Delivers consistently",
        "behaviors": "Delivers consistently, meets commitments, follows through",
        "skills": "Execution discipline",
        "experience": "Track record of follow-through",
        "traits": "Responsible, steady",
    },
    {
        "key": "meaning_purpose",
        "name": "Meaning & Purpose Orientation",
        "critical": "Work must matter. Connects work to impact",
        "behaviors": "Connects work to impact, chooses roles intentionally",
        "skills": "Purpose framing",
        "experience": "Chooses roles intentionally",
        "traits": "Values-driven",
    },
    {
        "key": "impact_focus",
        "name": "Impact Focus",
        "critical": "Outcomes over activity. Measures success by results",
        "behaviors": "Measures success by results, prioritizes high-leverage work",
        "skills": "Outcome thinking",
        "experience": "Evidence of measurable impact",
        "traits": "Results-oriented",
    },
    {
        "key": "cares",
        "name": "Cares",
        "critical": "Cares about the work, the people, and results",
        "behaviors": "Shows genuine care beyond role boundaries, acts to improve team/culture/outcomes",
        "skills": "Responsibility + empathy",
        "experience": "Acts to improve team, culture, or outcomes",
        "traits": "Human, invested, thoughtful",
    },
]

SYSTEM_PROMPT = """You are an expert talent evaluator for a remote architecture/BIM services company called Slantis. You evaluate recruitment survey responses against a 10-dimension competency rubric.

## Rubric

For each dimension, consider what is critical, what observable behaviors look like, and what personality traits indicate an A-player:

1. **General Cognitive Ability (GCA)** — Ability to solve unfamiliar problems, not recall known answers. Look for: breaks down ambiguity, forms hypotheses, systems thinking, intellectual humility. A-player: curious, sharp.

2. **Learning Velocity** — Learns faster than the pace of change. Look for: self-initiated learning, rapid improvement, applies feedback, career pivots or accelerated growth. A-player: growth-oriented, adaptive.

3. **Humility + Ownership** — Strong opinions, loosely held. Look for: admits mistakes, gives credit, owns outcomes, can explain failures. A-player: grounded, low-ego, resilient.

4. **Baseline Communication Skills** — Clarity over charisma. Look for: explains complex ideas simply, writes clearly and concisely, structured thinking. Evaluate the QUALITY of their written English across all responses.

5. **Collaboration & Trustworthiness** — Teams win, not heroes. Look for: listens, builds on others' ideas, cooperative, generous, values team success over individual glory.

6. **Psychological Safety Contributor** — Teams perform when people feel safe. Look for: invites input, shows respect, tolerates dissent, emotional intelligence, warmth, inclusiveness.

7. **Dependability** — Reliability beats brilliance. Look for: delivers consistently, execution discipline, follow-through, responsibility, steadiness.

8. **Meaning & Purpose Orientation** — Work must matter. Look for: connects work to impact, chooses roles intentionally, values-driven motivation.

9. **Impact Focus** — Outcomes over activity. Look for: measures success by results, evidence of measurable impact, results-oriented thinking.

10. **Cares** — Genuine care about work, people, and results. Look for: care beyond role boundaries, investment in team and culture, thoughtfulness, humanity.

## Scoring Scale

- **1** = Negative signal or concerning pattern
- **2** = Weak / minimal evidence
- **3** = Moderate / some positive signals
- **4** = Strong / clear positive evidence
- **5** = Exceptional / standout signals

## Confidence Levels

- **high** = 3+ relevant data points directly addressing this dimension
- **medium** = 1-2 relevant data points, or indirect evidence from adjacent responses
- **low** = No direct questions for this dimension; inference only from tone/context

## Important Instructions

- Score ONLY based on evidence in the responses. Do not assume or infer beyond what the text supports.
- For Communication, evaluate the actual quality of their English writing (grammar, clarity, vocabulary, structure) across ALL their responses, not just specific questions.
- When a candidate has very few responses or short answers, lean toward lower confidence, not lower scores.
- Be calibrated: a score of 3 should be the median candidate, 4 is genuinely above average, 5 is rare.
- Return ONLY valid JSON, no markdown, no commentary outside the JSON."""


def format_candidate(row, fieldnames):
    """Format a candidate's responses as Q&A pairs for the LLM."""
    skip_cols = {"_source_sheet", "_currency", "_form_variant", "Marca temporal",
                 "Dirección de correo electrónico"}

    meta = {
        "source_sheet": row.get("_source_sheet", ""),
        "form_variant": row.get("_form_variant", ""),
        "currency": row.get("_currency", ""),
    }

    qa_pairs = []
    for col in fieldnames:
        if col in skip_cols or col.startswith("_"):
            continue
        val = row.get(col, "").strip()
        if val and val.lower() not in ("none", "nan", ""):
            qa_pairs.append(f"Q: {col}\nA: {val}")

    name = row.get("What's your full name?", "Unknown")

    lines = [
        f"## Candidate: {name}",
        f"Form variant: {meta['form_variant']} | Salary currency: {meta['currency']} | Source: {meta['source_sheet']}",
        "",
        "## Survey Responses",
        "",
    ]
    lines.extend(qa_pairs)

    return "\n\n".join(lines)


USER_PROMPT_TEMPLATE = """{candidate_text}

---

Evaluate this candidate against all 10 dimensions. Return a JSON object with this exact structure:

{{
  "gca": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "learning_velocity": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "humility_ownership": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "communication": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "collaboration": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "psych_safety": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "dependability": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "meaning_purpose": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "impact_focus": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}},
  "cares": {{"score": <1-5>, "confidence": "<high|medium|low>", "evidence": "<1-2 sentences>"}}
}}"""

DIMENSION_KEYS = [d["key"] for d in DIMENSIONS]
