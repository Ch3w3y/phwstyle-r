---
name: schedule
description: >-
  Orders scheduler. Reads .noodle/mise.json and writes .noodle/orders-next.json.
  Turns backlog items into order pipelines built from the registered task types.
  Use when orders are empty, after backlog changes, when the loop re-evaluates,
  or when /schedule is invoked.
schedule: "When orders are empty, after backlog changes, or when recent events or session history suggest re-evaluation"
---

# Schedule

Read `.noodle/mise.json`. Write `.noodle/orders-next.json`. The loop promotes it to `orders.json`; never write `orders.json` yourself.

`noodle schema mise` and `noodle schema orders` are the source of truth for both shapes. Read them before writing output if you are unsure of a field.

Run autonomously. Never ask the user to choose or confirm anything. If an item needs a human decision, put its ID in `action_needed` and move on.

## Inputs

From mise, use:

- `backlog`: items with `id`, `title`, `status`, and optionally `plan`. Other fields depend on the issue source the adapter syncs from (for example `tags`, `section`, `estimate`, `milestone`, `url`, `body`). Treat them all as context.
- `task_types`: every schedulable skill and its `schedule` hint. Only these keys are valid `do` values.
- Active orders and sessions: never schedule an item that is already in flight.
- `recent_history` and `recent_events`: failures, merges, conflicts.

## Building orders

One order per backlog item. Use the item ID (as a string) for the order `id`. Each order is a pipeline of stages; stages run in group order, and stages sharing a `group` run in parallel.

Skip items whose `status` is `done`.

**Item with a `plan`:** read the plan overview and its phase files. Add one `execute` stage per unchecked `- [ ]` phase, in dependency order. Put phases that touch independent areas in the same `group`; keep anything that consumes another phase's output in a later group. When unsure, keep them sequential. Set `order.plan` to the plan path, and use `extra_prompt` on each stage for that phase's brief and any cross-phase contract.

**Item without a plan, small:** one change with clear scope (an estimate of `small`, or obviously a single concern). Schedule a single `execute` stage. Its `prompt` is the item title plus the context from its other fields (description `body`, `url`, labels).

**Item without a plan, complex:** multi-file, cross-cutting, or ambiguous enough that you would want a design first. Schedule one prompt-only stage (no `do`) whose prompt tells the agent to:

1. Write a phased plan to `brain/plans/<item-id>-<slug>/overview.md`, with one `- [ ]` line per phase, each phase small enough to verify on its own. Use the `plan` skill if it is installed. Skip any "ask the user to review" step, because this runs unattended.
2. Commit the plan in a worktree and merge it (`noodle worktree create`, then `noodle worktree merge`).
3. Stop without writing implementation code.

The directory name must start with the item ID. That is the link: every backlog adapter attaches `brain/plans/<item-id>-*/overview.md` as the item's `plan`, whatever tracker the item came from. Do not use `"do": "execute"` for this stage. On a later cycle the item will have a `plan` and gets scheduled as above.

**Standalone orders:** shared infrastructure that several items need can be its own order with a slug ID (for example `infra-<topic>`). Schedule it before the orders that depend on it.

**Follow-up stages:** if `task_types` contains more skills than `execute` (for example a review or reflect skill added later), read each one's `schedule` hint and append it as a stage where the hint says it belongs. Do not invent task types that are not registered.

## Priorities

- Finish one plan before starting another. If the current plan is blocked, schedule nothing for it rather than spreading work across plans. Unrelated small items may still run.
- An item that failed 2 or more times in `recent_history` gets split into a planning stage or left in `action_needed`. Do not retry it unchanged.
- After `merge.conflict`, do not reschedule the affected order straight away; list it in `action_needed`.
- Every order needs a `rationale` naming the rule above that placed it.

## Routing

Leave `with` and `model` unset so `routing.defaults` in `.noodle.toml` applies, unless a stage clearly needs something else. Set `"runtime": "process"` on every stage.

## Output

Write valid JSON matching `noodle schema orders`. If nothing is actionable, still write:

```json
{"orders": []}
```

An empty file tells the loop scheduling ran and found nothing, which stops it from respawning the scheduler in a hot loop.

Example shape, with placeholder content:

```json
{
  "orders": [
    {
      "id": "<item-id>",
      "title": "<item title>",
      "rationale": "Item without a plan, small: single execute stage",
      "stages": [
        {"do": "execute", "prompt": "<item title and context>", "runtime": "process"}
      ]
    }
  ]
}
```
