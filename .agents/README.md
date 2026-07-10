# `.agents`

Agent skills, design systems, reviews, and other agentic docs live **here**.

**Rule:** the only Markdown file allowed at the repository root is `README.md`.
Everything else (DESIGN, bug reviews, architecture notes, memory, skills) goes under `.agents/`.

| Path | Purpose |
|------|---------|
| `skills/` | Agent skills (emil-design-eng, apple-design, …) |
| `memory/` | Persistent agent memory / AGENTS.md |
| `reviews/` | Bug reviews, audit writeups, and `STATUS.md` (resolution ledger) |
| `DESIGN.md` | Design system SoT (when present) |

---

# .agents (project parity)

| Path | Purpose |
|------|---------|
| `memory/` | Long-lived agent notes, AGENTS.md, decisions |
| `skills/` | Project-local skills / skill packs for agents |

Keep secrets out of this tree.

**Reviews are immutable snapshots.** Current item status lives in
`reviews/STATUS.md`; consult it before acting on any review document.

