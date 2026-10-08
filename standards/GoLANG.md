# Go Standards

## Purpose

Define default coding standards for Go services, CLIs, libraries, and tests.

## Core Principles

- Keep code simple, explicit, and easy to maintain.
- Prefer straightforward control flow.
- Let package boundaries communicate architecture.
- Design for readability by the next engineer.

## Naming

- Follow standard Go naming conventions.
- Use short names in tight local scopes and descriptive names at package boundaries.
- Avoid stutter in package and type names.
- Name interfaces by behavior when they are small and meaningful.

## File Organization

- Organize by package responsibility, not by broad technical buckets alone.
- Keep packages cohesive and focused.
- Avoid circular dependencies.
- Keep `cmd/` thin and push reusable logic into internal or package code as appropriate.

## Style

- Use `gofmt` as the source of truth for formatting.
- Keep functions small and focused.
- Prefer early returns for error handling.
- Keep interfaces minimal and consumer-driven.
- Avoid unnecessary abstraction.

## Design Guidance

- Return concrete types from constructors when practical.
- Accept interfaces where behavior substitution is needed.
- Keep concurrency explicit and well scoped.
- Use contexts correctly for cancellation, deadlines, and request scoping.

## Error Handling

- Check errors immediately.
- Add context when returning errors upward.
- Do not panic for expected runtime failures.
- Keep logging and error propagation responsibilities clear.

## Testing

- Write table-driven tests when they improve clarity.
- Test exported behavior and important edge cases.
- Keep tests fast and deterministic.
- Prefer simple fakes over overly magical test setups.

## Avoid

- Large interfaces created before real consumers exist.
- Package names that are too generic to carry meaning.
- Concurrency used for style instead of actual need.
- Hidden side effects in initialization logic.
