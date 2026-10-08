# JavaScript Standards

## Purpose

Define default coding standards for JavaScript code in browser, server, scripting, and test environments.

## Core Principles

- Favor clarity and predictable behavior.
- Keep modules focused and easy to reason about.
- Prefer modern language features when they improve readability.
- Validate inputs at boundaries.

## Naming

- Use `PascalCase` for classes and constructor-like components.
- Use `camelCase` for variables, functions, methods, and object properties.
- Use descriptive names that communicate intent.

## File Organization

- Organize by feature when practical.
- Keep modules small and cohesive.
- Avoid dumping unrelated helpers into broad utility files.

## Style

- Prefer `const` by default and `let` only when reassignment is needed.
- Avoid `var`.
- Use strict equality unless loose equality is specifically required and justified.
- Return early to reduce nesting.
- Prefer async/await over promise chains when it improves readability.

## Design Guidance

- Keep side effects explicit.
- Separate DOM, transport, and business logic where practical.
- Wrap external integrations behind clear interfaces or adapter modules.
- Keep configuration centralized and discoverable.

## Error Handling

- Handle async failures intentionally.
- Surface actionable error messages.
- Avoid silent failures.
- Do not expose secrets in logs or browser output.

## Testing

- Write automated tests for critical logic.
- Test real user behavior for UI workflows.
- Keep tests independent and readable.
- Keep each test focused on one use case and one responsibility.
- Do not pack multiple unrelated behaviors into one large browser or integration test.
- Reuse helpers for setup and navigation, but keep each test's assertions aligned to a single business outcome.

## Avoid

- Implicit globals.
- Mutation-heavy code paths without a clear reason.
- Large files mixing UI, API calls, validation, and state management.
- Clever one-liners that reduce readability.
