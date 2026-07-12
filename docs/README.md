# docs/

`CLAUDE.md` treats these as the source of truth. If you already have the suite we built
earlier, drop those files in here. If starting clean, create them before Claude Code
implements the features they describe (cardinal rule C-4).

Expected files:

- `ARCHITECTURE.md` — kernel seam, layer diagram, `GeometryKernel` protocol, C-facade
  rationale, render/input abstraction.
- `ROADMAP.md` — phases with concrete exit tests.
- `USER_JOURNEYS.md` — J1–J5 step tables, feature-graph states, success criteria, edges.
- `TEST_PLAN.md` — test areas, the `GeometryKernel` conformance suite, phase gates G0/G1/G2.
- `SRS.md` — numbered FR/NFR "shall" requirements, traced to journeys/tests/roadmap.
- `UI_SPEC.md` — design tokens, Liquid Glass usage rules, component inventory, state-flow (§6).
- `PHASES.md` — the standalone phase briefing Claude Code reads to know current scope
  (cardinal rules C-1…C-7, exit gates, deferred scope, guardrails against out-of-scope work).
