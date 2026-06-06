# AGENTS.md

## Project

MarketLab is a fake-money Yes/No market app for a 2-hour Cursor workshop.

Keep changes small, clear, teachable, and easy to review.

## Stack

Use the existing stack:

- Next.js App Router
- React Server Components by default
- Server Actions for data changes
- Supabase Auth and Database
- Bun, TypeScript, Tailwind CSS, Biome, Vitest, and Task

Do not add dependencies or replace the stack unless asked.

## Skills and Docs

Use relevant installed skills for framework-specific work.

For Next.js-specific uncertainty, prefer the installed docs in `node_modules/next/dist/docs/`.

## Project Map

- `src/app/`: routes, layouts, and global styles
- `src/components/`: reusable UI components
- `src/lib/`: shared utilities and Supabase clients
- `supabase/`: migrations, config, and seed data
- `Taskfile.yml`: project commands

## Commands

Use `task` when a task exists.

- Setup: `task setup`
- Dev server: `task dev`
- Check formatting/linting: `task check`
- Typecheck: `task typecheck`
- Run tests once: `task test:run`
- Full verification: `task verify`
- List commands: `task --list`

If `task` is unavailable, activate mise in the current shell, then retry the `task` command. Do not use `mise exec -- task`.

## How to Work

- Build one small feature slice at a time.
- Reuse existing components and utilities before creating new ones.
- Add focused Vitest tests for important logic.
- Run the smallest useful check while iterating, and finish with `task verify` when practical.
- Explain the important diff and any remaining risk.

## Supabase Rules

- Migrations are the schema source of truth.
- Every Server Action must verify authentication and authorization before mutating data.
- Prefer RLS and Supabase RPC functions for balance-changing operations.
- Public market data may be readable.
- Profiles, positions, and ledger entries must stay owner-scoped.
- After changing migrations or seed data, run `task db:push` and `task db:types` once the repo is linked to Supabase.

## Validation

- Code changes: run `task verify` when practical.
- Hook changes: run `task hooks:validate` and `task hooks:run`.
- If a required check cannot run, report why and what risk remains.
