---
name: research-ledger
description: Use whenever research happens, asked for ("look this up", "validate this", "is this true", "find sources", "what do people say about") or started by Claude itself (web searches, research subagents), including picking a library, API or dataset, and checking a claim or number for the pitch.
---

# Research ledger

Research is one step, never deferred: gather the sources, give each a verdict, and save them to
`research/ledger.md`, all in the same pass. Findings handed back without the ledger entry aren't done.

## Sourcing
- **Peer-reviewed papers, reputable journals, official docs and engineering sources** (vendor docs, changelogs,
  package registries). Not blogs or SEO pages.
- **Recency:** prefer the last 1–2 years. Go back 3–4 only when recent good work is scarce, and say so.
- **Quality beats locality:** a stronger source from anywhere beats a weaker local one.
- **Verify existence before citing.** Actually open the source. Never cite from memory or a bare ID. For libraries
  and APIs, check the current version's docs or registry entry (context7 if installed), not training memory.

## Consensus (never trust one source)
- Every **load-bearing claim or number** needs **≥2 independent** corroborating sources.
- **Hunt for refutations.** If several credible sources refute a claim, mark it **DO NOT USE**, list the refuting
  sources, move it to the bottom of its section, and strip its numbers from active use. Leave a short tombstone so
  nobody re-litigates it.
- **Verdict per source:** KEEP (corroborated) · WEAK (thin support) · DO NOT USE (refuted).

## Community consensus
Mine Reddit, Hacker News, StackExchange and GitHub issues. Weight by agreement (upvotes, agreeing replies) and by
repetition across threads. Note the contrasting view and which side wins. **The final call = professional consensus
+ community consensus, aggregated; state both.** If the community sources are unreachable, say so.

## Writing it up
- **One file:** `research/ledger.md`. Never start a second research file.
- **Each pass is a labelled section** (the template is in the file's comment), plus a row in its CATEGORY INDEX.
- **KEEP sits at the top of the section; DO NOT USE is quarantined at the bottom.** Breezy and skimmable.
- **Publish it** (`bash scripts/publish-context.sh "research: <topic>"`). Anyone may publish `research/**`. If it's
  refused, a teammate published research in the meantime: sync, re-apply your section, publish again.

## Hackathon budget
Agree a time box with the user before starting (15–30 minutes is typical). Report what you have when it runs out.
If several questions are independent, research them in parallel.

## Report to the user
The final call in 2–4 lines, then `saved: research/ledger.md § <n> <topic>`.

## Common mistakes
- Handing back a summary and "I'll add it to the ledger later".
- One source behind a number that goes into the pitch.
- Citing a library API from memory, for a version that has since changed.
