# AI Strategy

## Tooling

- Primary assistant: GitHub Copilot (GPT-5.3-Codex)
- Workflow style: iterative design, test, synthesize, analyze, document

## Prompting Patterns That Worked

- Narrow prompts for module-level refinement
- Evidence-first prompts for PPA debugging and run comparison
- Structured audit prompts for submission compliance alignment

## Limits Encountered

- Generated documentation can drift from latest run state unless continuously refreshed
- Large-run debugging requires strict separation of historical failures vs current failure mode

## Mitigations

- Keep raw logs as source of truth
- Maintain first-pass derivative logs and refine later
- Tie docs directly to metrics.csv and run logs
