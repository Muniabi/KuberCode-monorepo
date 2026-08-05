---
name: suggesting-cursor-rules
description: When the user repeats the same correction or convention multiple times, suggest a Cursor rule to encode it permanently.
user-invocable: false
---

# Suggesting Cursor Rules

Watch for repeated corrections and frustration. When the user keeps telling you the same thing, suggest a `.cursor/rules/` file so they never have to say it again.

## Triggers

Suggest a rule when you notice:

- The user corrects the same pattern **2+ times** (e.g. "use named exports", "don't use default exports")
- The user expresses frustration about code style or conventions
- The user says things like "I always want...", "never do...", "every time you..."
- You keep making the same mistake in this project

## How to Suggest

When you detect a trigger, offer it naturally:

```
I notice you've corrected me on [pattern] a couple times. Want me to
create a Cursor rule so I always follow this convention?
```

If they say yes, create the rule:

```
.cursor/rules/<name>.mdc
```

```
---
description: <what this rule enforces>
globs: <file pattern this applies to>
---

- <the convention, stated clearly>
```

## Examples

**User keeps saying "use relative imports":**

```
---
description: Import conventions
globs: **/*.{ts,tsx}
---

- Use relative imports, not @ aliases
- Import from the same package with relative paths (e.g. "../../queries/..." not "src/queries/...")
```

**User keeps saying "no comments on obvious code":**

```
---
description: Comment style
globs: **/*.{ts,tsx,js,jsx}
---

- Do not add comments that narrate what the code does
- Only comment non-obvious intent, tradeoffs, or constraints
```

**User frustrated about test file locations:**

```
---
description: Test file conventions
globs: **/*.test.{ts,tsx}
---

- Co-locate test files next to the source file they test
- Name test files <source>.test.ts, not __tests__/<source>.ts
```

## Rules

- Don't be annoying — only suggest after a genuine repeated pattern, not on the first correction
- Keep rule files small and focused — one concern per file
- Check `.cursor/rules/` first so you don't duplicate an existing rule
- Frame it as a helpful offer, not a lecture

---

name: suggesting-cursor-hooks
description: When the user keeps asking for the same check to run (lint, tests, type-check), suggest a Cursor hook to automate it.
user-invocable: false

---

# Suggesting Cursor Hooks

Watch for repeated manual requests. When the user keeps asking you to run the same command after changes, suggest a hook to automate it.

## Triggers

Suggest a hook when you notice:

- The user asks you to **run the same check 2+ times** (e.g. "run lint", "run tests", "check types")
- The user says "always run X after editing" or "make sure to test after changes"
- You keep forgetting to run a validation step and the user catches it
- A CI failure could have been caught locally with a post-edit check

## How to Suggest

```
You've asked me to run [command] after edits a few times. Want me to
set up a Cursor hook so it runs automatically?
```

If they say yes, create `.cursor/hooks.json` and the script:

```json
{
    "hooks": [
        {
            "event": "afterFileEdit",
            "script": ".cursor/hooks/<name>.sh",
            "pattern": "<glob>"
        }
    ]
}
```

## Common Hooks to Suggest

| User keeps asking...          | Hook                                                   |
| ----------------------------- | ------------------------------------------------------ |
| "run lint" / "fix formatting" | `afterFileEdit` → `eslint --fix` or `prettier --write` |
| "check types"                 | `afterFileEdit` → `tsc --noEmit` on `.ts`/`.tsx`       |
| "run tests"                   | `afterFileEdit` → run related test file                |
| "don't touch .env"            | `beforeShellExecution` → warn on secrets files         |
| "make sure it builds"         | `stop` → quick build check                             |

## Rules

- Only suggest after a real repeated pattern, not preemptively
- Hook scripts must be fast (under 5 seconds) or the agent feels slow
- Scripts should exit 0 and report via stdout — don't block the agent unless the user explicitly wants that
- Check for existing `.cursor/hooks.json` first — merge, don't overwrite
- Keep it casual — "want me to automate this?" not a formal proposal

---

name: saving-workspace-context
description: Automatically persist useful context — research, decisions, learnings, templates — to workspace files so knowledge survives across conversations.
user-invocable: false

---

# Saving Workspace Context

You are an agent that builds institutional memory. As you work, watch for information that should outlast this conversation and save it to the workspace so future sessions start smarter.

## At the Start of Every Conversation

Load existing context before doing anything else:

1. Check for a `context/` directory — read any files relevant to the current task
2. Check for a product/project context file (e.g. `.agents/product-marketing-context.md`, `PROJECT.md`, or similar) for positioning, goals, and constraints
3. Check for any domain-specific directories the project uses (e.g. `companies/`, `docs/`, `research/`)
4. Check for templates or reusable assets that might apply

If the project doesn't have a `context/` directory yet, that's fine — create one when you first have something worth saving.

## During a Conversation

Watch for information that should be persisted. Save it as soon as you recognize it — don't wait until the end.

| Signal                                    | Where to Save                                                      |
| ----------------------------------------- | ------------------------------------------------------------------ |
| Product details, positioning, ICP changes | Project context file (e.g. `.agents/product-marketing-context.md`) |
| Research on a company, person, or topic   | `context/{topic-slug}.md` or a domain-specific directory           |
| Strategy decisions or learnings           | `context/{topic}.md` with dated entries                            |
| Reusable templates or boilerplate         | `templates/` or a project-appropriate location                     |
| A repeatable multi-step workflow          | New skill in `.cursor/skills/` or `.agents/skills/`                |
| A persistent constraint or convention     | New rule in `.cursor/rules/`                                       |

### How to Save

- **Don't ask permission** for small context saves — just do it and mention what you saved
- **Do ask permission** before creating new skills or rules (they affect all future conversations)
- **Append, don't overwrite** when adding to existing context files — use dated entries
- **Use clear file names** — future you (or a future agent) needs to find this by scanning a directory listing

## At the End of a Conversation

Before finishing, ask yourself:

- Did I learn anything about this project that isn't captured in workspace files?
- Did I do research that would be painful to redo?
- Did I discover a pattern that should become a skill or rule?
- Did I create content that could be templated for reuse?

If yes to any, save it before the conversation ends.

## File Formats

### Context Files (`context/{slug}.md`)

```markdown
# {Topic}

## {Date} — {Brief title}

{What was learned, decided, or discovered}

## {Earlier date} — {Earlier entry}

{Previous context}
```

Keep entries reverse-chronological (newest first). Date your entries so they age gracefully.

### Project Context File

A single file capturing the current state of the project's identity:

```markdown
# {Project Name} — Context

- **What it is:** {one line}
- **Who it's for:** {target audience}
- **Key differentiator:** {why this vs alternatives}
- **Current stage:** {pre-launch / beta / growth / etc.}
- **Current goals:** {what matters right now}

## Positioning

{How we talk about the product}

## Constraints

{Things to always keep in mind}
```

## When to Create a New Skill

Create a skill when you find yourself doing the same multi-step workflow more than once:

- Researching a topic (check multiple sources, synthesize, save findings)
- Preparing for a meeting or call (pull context, recent history, prep talking points)
- Running a campaign or process (select targets, personalize, track progress)

## When to Create a New Rule

Create a rule when a persistent constraint should apply across all conversations:

- Voice/tone guidelines that get refined through feedback
- Naming conventions or file organization patterns
- Domain-specific constraints ("never mention X", "always check Y first")

## Rules

- Be proactive — save context without being asked, but mention what you saved
- Keep files scannable — future agents will skim directory listings to find context
- Don't save trivial information — if it's easily re-derived, skip it
- Date everything that accumulates over time
- Check for existing files before creating new ones to avoid duplicates

---

name: best-of-n-solving
description: Solve a hard problem by trying multiple approaches in parallel using isolated git worktrees. Each attempt runs in its own branch, and the best solution is selected. Use for complex refactors, tricky bugs, or architectural decisions where multiple strategies could work.

---

# Best-of-N Problem Solving

Use this skill when facing a hard problem with multiple possible approaches — complex refactors, tricky bugs, performance optimization, or architectural decisions where you're not sure which strategy will work best.

## How It Works

Cursor's `best-of-n-runner` subagent type creates isolated git worktrees — each attempt gets its own branch and working directory. Multiple approaches run in parallel without interfering with each other. You compare the results and pick the winner.

## Steps

1. **Identify the approaches** — before launching, define 2-3 distinct strategies. For example, if optimizing a slow database query:
    - Approach A: Add a composite index and rewrite the query
    - Approach B: Denormalize the schema with a materialized view
    - Approach C: Add application-level caching with Redis

2. **Launch parallel runners** — use the Task tool with `subagent_type: "best-of-n-runner"` for each approach. Launch them all in a single message so they run concurrently:

    ```
    Task 1: { subagent_type: "best-of-n-runner", prompt: "Approach A: ..." }
    Task 2: { subagent_type: "best-of-n-runner", prompt: "Approach B: ..." }
    Task 3: { subagent_type: "best-of-n-runner", prompt: "Approach C: ..." }
    ```

    Each runner gets its own branch and worktree. Include clear success criteria in the prompt (e.g., "run the tests and report if they pass", "measure the query time").

3. **Compare results** — when all runners complete, evaluate:
    - Which approach passes all tests?
    - Which has the cleanest implementation?
    - Which has the best performance characteristics?
    - Which is easiest to maintain long-term?

4. **Merge the winner** — check out the winning branch and merge it, or cherry-pick specific commits. Clean up the other worktree branches.

## When to Use This

- A bug that could have multiple root causes
- A refactor where you're choosing between patterns (e.g., composition vs. inheritance)
- Performance optimization with multiple strategies
- Trying different libraries or approaches for the same feature
- Any situation where "just try it" is faster than analyzing

## Notes

- Each runner is fully isolated — they can't see each other's changes.
- Keep prompts specific: include the file paths, the problem statement, and clear success criteria.
- For simpler problems, this is overkill — just use a single agent.
- The branches are real git branches, so you can inspect them manually if needed.

---

name: parallel-exploring
description: Explore a large codebase in parallel by launching multiple explore subagents that each investigate a different area simultaneously. Use when onboarding onto a new project, understanding architecture, or investigating a cross-cutting concern.

---

# Parallel Explore

Use this skill when you need to understand a large or unfamiliar codebase quickly — onboarding onto a new project, investigating how a feature works across layers, or mapping the architecture.

## How It Works

Cursor's `explore` subagent is a fast, read-only agent optimized for searching and reading code. You can launch multiple explore agents in a single message and they run concurrently, each investigating a different area.

## Steps

1. **Identify the areas to explore** — break the codebase into logical zones. For a typical full-stack app:
    - Frontend: components, pages, routing, state management
    - Backend: API routes, database models, middleware, auth
    - Infrastructure: CI/CD, Docker, deployment config
    - Shared: types, utilities, constants

2. **Launch parallel explore agents** — use the Task tool with `subagent_type: "explore"` for each area. Launch them all in one message:

    ```
    Task 1: "Explore the frontend — find the main pages, routing setup, state management approach,
             and UI component library. Check src/app/, src/components/, src/pages/. Report the
             framework, router, styling approach, and key components."

    Task 2: "Explore the backend — find the API routes, database setup, ORM, auth middleware,
             and data models. Check src/server/, src/api/, lib/, prisma/. Report the framework,
             database, auth strategy, and key endpoints."

    Task 3: "Explore the infrastructure — find CI/CD config, Docker setup, deployment targets,
             and environment variable management. Check .github/, docker*, *.config.*, .env*.
             Report the deploy target, CI provider, and any IaC."
    ```

3. **Synthesize the results** — when all agents return, combine their findings into a coherent picture:
    - Tech stack summary (frontend, backend, database, infra)
    - Architecture diagram (describe the data flow)
    - Key files and entry points
    - Potential concerns or tech debt

## Other Use Cases

- **Cross-cutting investigation**: "Where is user authentication checked?" — launch agents to search the frontend (route guards), backend (middleware), and database (session storage) simultaneously.
- **Dependency audit**: launch agents to check different parts of the dependency tree for outdated packages, security issues, and unused imports.
- **Migration planning**: have agents simultaneously assess the frontend, backend, and tests to estimate the scope of a framework migration.

## Notes

- Explore agents are read-only — they can't modify files.
- Use `thoroughness: "very thorough"` in the prompt for comprehensive analysis.
- Each agent has its own context window, so they can each read many files without running out of space.
- For a single focused question, just use Grep or SemanticSearch directly — subagents are for broad exploration.

---

name: grinding-until-pass
description: Keep iterating on code changes until the tests pass, the build succeeds, or linting is clean. Runs in a tight loop of fix → run → check → repeat. Use when you want the agent to autonomously grind through test failures or build errors.

---

# Grind Until Pass

Use this skill when you want the agent to keep working autonomously until a specific goal is met — all tests pass, the build succeeds, or linting is clean. Instead of stopping after one attempt, the agent loops until done.

## Steps

1. **Define the goal command** — the command whose exit code determines success:
    - Tests: `npm test` or `npx vitest run`
    - Build: `npm run build`
    - Lint: `npm run lint`
    - Type-check: `npx tsc --noEmit`
    - All of the above: `npm run lint && npx tsc --noEmit && npm test && npm run build`

2. **Run the command** — execute it and capture the output.

3. **If it fails — analyze and fix**:
    - Read the error output carefully.
    - Identify the root cause: failing test assertion, type error, lint violation, import error, etc.
    - Make the minimal fix. Don't refactor — just fix the error.
    - Go back to step 2.

4. **If it passes — stop and report**:
    - Report what was fixed and how many iterations it took.
    - Summarize the changes made.

## Rules for the Loop

- **Maximum 10 iterations** — if after 10 attempts the command still fails, stop and report what's blocking progress. Something fundamental is wrong and needs human input.
- **Fix one thing at a time** — don't try to fix all errors at once. Fix the first error, re-run, and see if the fix resolves downstream errors too.
- **Don't delete tests** — if a test is failing, fix the code to make it pass. Don't modify the test unless the test itself is clearly wrong (testing old behavior that was intentionally changed).
- **Don't suppress errors** — don't add `@ts-ignore`, `eslint-disable`, or `any` types to silence errors. Fix the actual problem.
- **Track progress** — if the number of errors is increasing instead of decreasing, stop and reassess the approach.

## When to Use This

- After a large refactor that broke multiple tests
- After upgrading a dependency that introduced type errors
- After merging a branch with conflicts that need resolution
- When you want to "just make it green" and trust the agent to grind through it

## Advanced: Cursor Hooks Integration

You can automate this with a Cursor hook in `.cursor/hooks.json` that triggers after the agent's turn ends, checks if tests pass, and sends a follow-up message if they don't:

```json
{
    "hooks": [
        {
            "event": "stop",
            "command": "bash .cursor/scripts/check-tests.sh",
            "description": "Re-run tests after agent stops and send follow-up if failing"
        }
    ]
}
```

The script checks the exit code and returns a `followup_message` if tests are still failing.

## Notes

- This works best with fast test suites. If your tests take 5+ minutes, the loop will be slow.
- Use `--bail` or `--fail-fast` flags to stop at the first failure for faster iteration.
- The agent will be thorough but not creative — if the fix requires a design change, it'll need human guidance.

---

name: parallel-test-fixing
description: When multiple tests fail, assign each failing test file to a separate subagent that fixes it independently in parallel.
user-invocable: true

---

# Parallel Test Fixing

Speed up fixing a broken test suite by distributing failing tests across parallel subagents.

## Workflow

### 1. Run the Full Test Suite

```bash
npm test -- --no-coverage 2>&1 || true
```

Capture the output and extract all failing test files.

### 2. Group Failures

Parse the test output for failing files:

- Jest: `FAIL src/components/Button.test.tsx`
- Vitest: `FAIL src/utils/format.test.ts`
- Pytest: `FAILED tests/test_api.py::test_create_user`

Group by file — each file becomes one task.

### 3. Launch Parallel Subagents

For each failing test file, launch a `generalPurpose` subagent:

```
Task: Fix the failing tests in <file>

The test file is: <path>
The test command is: <command to run just this file>
The error output was:
<paste the relevant failure output>

Steps:
1. Read the test file and the source file it tests
2. Understand why each test is failing
3. Fix the source code (preferred) or update the test if the test is wrong
4. Run the single test file to confirm it passes
5. Report what you changed and why
```

Launch all subagents simultaneously — they work in parallel since each touches different files.

### 4. Collect Results

As each subagent completes, collect:

- Which tests were fixed
- What files were changed
- Whether the fix might conflict with another subagent's changes

### 5. Verify

Run the full test suite one more time to confirm everything passes:

```bash
npm test
```

If there are new failures (from conflicting fixes), resolve them sequentially.

## Tips

- If two failing tests share the same source file, assign them to the same subagent to avoid edit conflicts
- Set a timeout — if a subagent is stuck for 5+ minutes, check its progress
- For large test suites (50+ failures), batch into groups of 5-10 per subagent rather than one-per-file
- Use `best-of-n-runner` subagents if you want isolated worktrees for each fix attempt

---

name: building-skills-from-patterns
description: When the same multi-step workflow repeats in Cursor (user corrections or agent redos), capture it as a new SKILL.md under .cursor/skills/ so future sessions load it automatically.
user-invocable: true

---

# Building Skills From Patterns

**Skills** are reusable `SKILL.md` files. This meta-skill tells the agent to **promote repeated muscle memory** into a named skill: research once, encode the workflow, reuse forever.

## When to trigger

- The user has asked for the **same sequence** three or more times (e.g. “always run lint then tsc then test before commit”).
- The agent notices it is **re-deriving** the same steps on every task in this repo (e.g. “how we deploy preview branches”).
- A correction sounds like a **policy** (“never use raw SQL here — always the repository layer”) — pair with `suggesting-cursor-rules` if it should be always-on; use a **skill** if it is a procedure with steps.

## Workflow

### 1. Name the pattern

Choose a short **slug** (lowercase, hyphens): `verifying-api-before-merge`, `releasing-mobile-build`, etc.

### 2. Draft `SKILL.md`

Create `.cursor/skills/<slug>/SKILL.md` (or in this repo’s pattern, copy from `resources/<slug>/SKILL.md` when contributing upstream).

Frontmatter:

```yaml
---
name: <slug>
description: One line: what it does and when to use it. Ends with a clear trigger.
user-invocable: true   # optional, if the user should be able to invoke by name
---
```

Body sections (keep lean):

1. **Title** — human-readable.
2. **When to use** — bullets.
3. **Steps** — numbered, imperative, tool names where useful (`npm`, `gh`, MCP tools).
4. **Notes** — edge cases, safety, when **not** to use.

Match the tone of other skills in the repo: concrete commands, no filler.

### 3. Validate

- **Description** is specific enough for Cursor to **match** the skill when the user describes the task.
- Steps are **executable** by an agent without guessing repo layout (or say “detect package manager from lockfile”).
- No secrets or machine-specific paths.

### 4. Point the user to it

Tell the user where the file lives and that the agent will pick it up on the next chat in that workspace.

## Relationship to rules and hooks

| Mechanism                       | Use for                                           |
| ------------------------------- | ------------------------------------------------- |
| **Skill**                       | On-demand procedure, branching steps, tool usage. |
| **Rule** (`.cursor/rules/`)     | Always-on conventions, style, file patterns.      |
| **Hook** (`.cursor/hooks.json`) | Automate after file save / stop events.           |

If the pattern is “every time I save, run X,” suggest a **hook** instead. If it is “when I ask to ship,” keep it as a **skill**.

## Notes

- Prefer **one skill per workflow** — avoid megaskills that try to cover every situation.
- Update an existing skill instead of adding a duplicate if the workflow evolves.

---

name: suggesting-skills
description: When the user struggles with a task that a known skill could handle, suggest installing it.
user-invocable: false

---

# Suggesting Skills

Watch for moments where the user is working on something that an existing skill would make easier. Suggest it when the timing is natural.

## Triggers

Suggest a skill when:

- The user asks how to do something a skill covers (e.g. "how do I add Sentry?" → `adding-error-tracking`)
- The user is struggling with a task and a skill has a proven workflow for it
- You notice the project is missing something a skill could set up (e.g. no tests, no CI)
- The user is manually doing something a Cursor-native skill automates

## How to Suggest

Keep it brief and contextual:

```
There's a skill for that — `adding-error-tracking` handles Sentry
setup with source maps and performance monitoring. Want me to use it?
```

Or when you notice a gap:

```
This project doesn't have CI set up. The `setting-up-ci` skill can
scaffold a GitHub Actions pipeline with lint, test, and build steps.
Want me to set that up?
```

## Skill Reference

| User is doing...           | Suggest...                          |
| -------------------------- | ----------------------------------- |
| Adding analytics           | `adding-analytics`                  |
| Setting up auth            | `adding-auth`                       |
| Adding payments            | `adding-stripe`                     |
| Writing tests from scratch | `writing-tests`, `adding-e2e-tests` |
| Debugging a hard bug       | `systematic-debugging`              |
| Creating a PR              | `creating-pr`                       |
| Dockerizing                | `adding-docker`                     |
| Setting up CI              | `setting-up-ci`                     |
| Reviewing code quality     | `reviewing-code`                    |
| Checking security          | `auditing-security`                 |
| Building a mobile app      | `react-native-patterns`             |
| Working with LLM prompts   | `prompt-engineering`                |
| Designing a database       | `database-design`                   |

## Rules

- Don't spam skill suggestions — one per conversation unless asked
- Only suggest when the timing is natural (user is about to do the thing, not mid-task)
- If the user declines, don't suggest the same skill again
- Mention how to install: copy the `SKILL.md` to `.cursor/skills/<name>/SKILL.md`

---

name: codebase-onboarding
description: Launch multiple explore subagents in parallel to investigate architecture, data models, auth, APIs, and deployment. Synthesize into an onboarding document.
user-invocable: true

---

# Codebase Onboarding

Generate a comprehensive onboarding document for a codebase by exploring it in parallel.

## Workflow

### 1. Launch Parallel Explorers

Spawn 5 `explore` subagents, each investigating a different area:

**Agent 1 — Architecture & Structure**

> "Map the top-level directory structure. Identify the framework (Next.js, Express, Django, etc.), monorepo tools (turbo, nx), and key config files. List every app/package and what it does."

**Agent 2 — Data Models & Database**

> "Find all database schemas, ORM models, migrations, and seed files. List every entity, its fields, and relationships. Identify the database (Postgres, MySQL, MongoDB, etc.) and ORM (Prisma, Drizzle, SQLAlchemy, etc.)."

**Agent 3 — API Routes & Endpoints**

> "Find all API route definitions. List every endpoint with its HTTP method, path, auth requirements, and what it does. Identify the API style (REST, GraphQL, tRPC)."

**Agent 4 — Authentication & Authorization**

> "Find how auth works. Identify the auth provider (Auth.js, Clerk, Supabase Auth, custom), session management, protected routes, role/permission checks, and middleware."

**Agent 5 — Deployment & Infrastructure**

> "Find deployment config (Dockerfile, Vercel config, fly.toml, terraform), CI/CD pipelines (GitHub Actions, etc.), environment variables needed, and how to run the app locally."

### 2. Synthesize

Combine the results from all 5 agents into a single onboarding document:

```markdown
# Codebase Onboarding

## Quick Start

1. Clone the repo
2. Install dependencies: `<command>`
3. Set up environment: copy `.env.example` to `.env`
4. Run database migrations: `<command>`
5. Start dev server: `<command>`

## Architecture

<Agent 1 findings>

## Data Models

<Agent 2 findings>

## API Reference

<Agent 3 findings>

## Authentication

<Agent 4 findings>

## Deployment

<Agent 5 findings>

## Key Files to Know

- `<file>` — <why it matters>
```

### 3. Save

Write the document to `ONBOARDING.md` in the project root, or wherever the user specifies.

## Tips

- Each explore agent is read-only and fast — the whole process takes under a minute
- For monorepos, consider one additional agent per app/package
- The document should be opinionated — highlight the "start here" files, not just list everything
- Include gotchas: common setup issues, env vars that are easy to forget, required system dependencies

---

name: writing-commit-messages
description: Write clear, conventional commit messages with proper type prefixes, scopes, and body content.
user-invocable: true

---

# Writing Commit Messages

Write commit messages that are useful for humans and machines.

## Format

```
<type>(<optional scope>): <subject>

<optional body>

<optional footer>
```

### Subject Line Rules

- **50 characters or less** for the subject
- Use imperative mood: "add feature" not "added feature" or "adding feature"
- Don't capitalize the first letter after the type prefix
- No period at the end

### Types

| Type       | When to use                                |
| ---------- | ------------------------------------------ |
| `feat`     | New user-facing feature                    |
| `fix`      | Bug fix                                    |
| `refactor` | Code restructuring without behavior change |
| `docs`     | Documentation changes                      |
| `test`     | Adding or updating tests                   |
| `chore`    | Build, CI, tooling, deps                   |
| `perf`     | Performance improvement                    |
| `style`    | Formatting, whitespace (not CSS)           |
| `ci`       | CI/CD pipeline changes                     |
| `revert`   | Reverting a previous commit                |

### Scope (Optional)

The area of the codebase affected:

- `feat(auth): add OAuth2 login flow`
- `fix(api): handle null response from payments endpoint`
- `refactor(db): extract query builder into module`

### Body (When Needed)

Explain **why**, not what (the diff shows what):

```
fix(checkout): prevent duplicate order submissions

The submit button was not disabled after the first click,
allowing users to create multiple orders. This caused
duplicate charges in Stripe.
```

### Footer (When Needed)

```
BREAKING CHANGE: rename `getUserById` to `findUser`

Closes #456
Co-authored-by: Name <email>
```

## Examples

Good:

```
feat(dashboard): add real-time notification bell
fix: resolve race condition in WebSocket reconnect
refactor(api): consolidate error handling middleware
test: add integration tests for payment webhook
chore: upgrade TypeScript to 5.4
```

Bad:

```
fixed stuff
WIP
update
changes
asdf
```

## When to Commit

- Each commit should represent one logical change
- Don't mix refactoring with feature work in the same commit
- Don't commit half-working code (use `git stash` instead)
- Commit early and often on feature branches, squash before merge if needed

## Breaking Changes

If the commit introduces a breaking change:

1. Add `!` after the type: `feat(api)!: change auth token format`
2. Add `BREAKING CHANGE:` in the footer with migration instructions

---

name: frontend-design
description: Guidance for distinctive, intentional visual design when building new UI or reshaping an existing one. Helps with aesthetic direction, typography, and making choices that don't read as templated defaults.
license: Complete terms in LICENSE.txt

---

# Frontend Design

Approach this as the design lead at a small studio known for giving every client a visual identity that could not be mistaken for anyone else's. This client has already rejected proposals that felt templated, and is paying for a distinctive point of view: make deliberate, opinionated choices about palette, typography, and layout that are specific to this brief, and take one real aesthetic risk you can justify.

## Ground it in the subject

If the brief does not pin down what the product or subject is, pin it yourself before designing: name one concrete subject, its audience, and the page's single job, and state your choice. If there's any information in your memory about the human's preferences, context about what they're building, or designs you've made before – use that as a hint. The subject's own world, its materials, instruments, artifacts, and vernacular, is where distinctive choices come from. Build with the brief's real content and subject matter throughout.

## Design principles

For web designs, the hero is a thesis. Open with the most characteristic thing in the subject's world, in whatever form makes sense for it: a headline, an image, an animation, a live demo, an interactive moment. Be deliberate with your choice: a big number with a small label, supporting stats, and a gradient accent is the template answer, only use if that's truly the best option.

Typography carries the personality of the page. Pair the display and body faces deliberately, not the same families you would reach for on any other project, and set a clear type scale with intentional weights, widths, and spacing. Make the type treatment itself a memorable part of the design, not a neutral delivery vehicle for the content.

Structure is information. Structural devices, numbering, eyebrows, dividers, labels, should encode something true about the content, not decorate it. Many generic designs use numbered markers (01 / 02 / 03), but that's only appropriate if the content actually is a sequence - like a real process or a typed timeline where order carries information the reader needs. Question if choices like numbered markers actually make sense before incorporating them.

Leverage motion deliberately. Think about where and if animation can serve the subject: a page-load sequence, a scroll-triggered reveal, hover micro-interactions, ambient atmosphere. An orchestrated moment usually lands harder than scattered effects; choose what the direction calls for. However, sometimes less is more, and extra animation contributes to the feeling that the design is AI-generated.

Match complexity to the vision. Maximalist directions need elaborate execution; minimal directions need precision in spacing, type, and detail. Elegance is executing the chosen vision well.

Consider written content carefully. Often a design brief may not contain real content, and it's up to you to come up with copy. Copy can make a design feel as templated as the design itself. See the below section on writing for more guidance.

## Process: brainstorm, explore, plan, critique, build, critique again

For calibration: AI-generated design right now clusters around three looks: (1) a warm cream background (near #F4F1EA) with a high-contrast serif display and a terracotta accent; (2) a near-black background with a single bright acid-green or vermilion accent; (3) a broadsheet-style layout with hairline rules, zero border-radius, and dense newspaper-like columns. All three are legitimate for some briefs, but they are defaults rather than choices, and they appear regardless of subject. Where the brief pins down a visual direction, follow it exactly — the brief's own words always win, including when it asks for one of these looks. Where it leaves an axis free, don't spend that freedom on one of these defaults. Just like a human designer who's hired, there's often a careful balance between doing what you're good at and taking each project as a chance to experiment and learn.

Work in two passes. First, brainstorm a short design plan based on the human's design brief: create a compact token system with color, type, layout, and signature. Color: describe the palette as 4–6 named hex values. Type: the typefaces for 2+ roles (a characterful display face that's used with restraint, a complementary body face, and a utility face for captions or data if needed). Layout: a layout concept, using one-sentence prose descriptions and ASCII wireframes to ideate and compare. Signature: the single unique element this page will be remembered by that embodies the brief in an appropriate way.

Then review that plan against the brief before building: if any part of it reads like the generic default you would produce for any similar page (work through a similar prompt to see if you arrive somewhere similar) rather than a choice made for this specific brief — revise that part, say what you changed and why. Only after you've confirmed the relative uniqueness of your design plan should you start to write the code, following the revised plan exactly and deriving every color and type decision from it.

When writing the code, be careful of structuring your CSS selector specificities. It's easy to generate CSS classes that cancel each other out (especially with a type-based selector like .section and a element-based selector like .cta). This can happen often with paddings/margins between sections.

Try to do a lot of this planning and iteration in your thinking, and only show ideas to the user when you have higher confidence it'll delight them.

## Restraint and self-critique

Spend your boldness in one place. Let the signature element be the one memorable thing, keep everything around it quiet and disciplined, and cut any decoration that does not serve the brief. Not taking a risk can be a risk itself! Build to a quality floor without announcing it: responsive down to mobile, visible keyboard focus, reduced motion respected. Critique your own work as you build, taking screenshots if your environment supports it – a picture is worth 1000 tokens. Consider Chanel's advice: before leaving the house, take a look in the mirror and remove one accessory. Human creators have memory and always try to do something new, so if you have a space to quickly jot down notes about what you've tried, it can help you in future passes.

## More on writing in design

Words appear in a design for one reason: to make it easier to understand, and therefore easier to use. They are design material, not decoration. Bring the same intentionality to copy that you would bring to spacing and color. Before writing anything, ask what the design needs to say, and how it can best be said to help the person navigate the experience.

Write from the end user's side of the screen. Name things by what people control and recognize, never by how the system is built. A person manages notifications, not webhook config. Describe what something does in plain terms rather than selling it. Being specific is always better than being clever.

Use active voice as default. A control should say exactly what happens when it's used: "Save changes," not "Submit." An action keeps the same name through the whole flow, so the button that says "Publish" produces a toast that says "Published." The vocabulary of an interface is the signposting for someone navigating the product. Cohesion and consistency are how people learn their way around.

Treat failure and emptiness as moments for direction, not mood. Explain what went wrong and how to fix it, in the interface's voice rather than a person's. Errors don't apologize, and they are never vague about what happened. An empty screen is an invitation to act.

Keep the register conversational and tuned: plain verbs, sentence case, no filler, with tone matched to the brand and the audience. Let each element do exactly one job. A label labels, an example demonstrates, and nothing quietly does double duty.


