# Python Standards

## Purpose

Define default coding standards for Python applications, services, scripts, automation, and tests.

## Core Principles

- Prefer readability and explicitness.
- Keep functions small and purposeful.
- Let code reflect the domain language clearly.
- Favor simple data flow over hidden mutation.

## Naming

- Use `PascalCase` for classes.
- Use `snake_case` for functions, methods, variables, and modules.
- Use `UPPER_SNAKE_CASE` for constants.
- Choose names that describe behavior and meaning clearly.

## File Organization

- Organize modules by feature or bounded concern where practical.
- Keep package boundaries clear.
- Keep scripts thin and move reusable logic into modules.
- Mirror package structure in tests when possible.

## Style

- Follow PEP 8 unless there is a strong local convention otherwise.
- Prefer explicit imports over wildcard imports.
- Use type hints for public functions and important internal interfaces.
- Prefer comprehensions when they are clearer than loops, not when they become dense.
- Return early to reduce nesting.

## Design Guidance

- Keep I/O at the edges and business logic in plain functions or classes.
- Use dataclasses for structured data when appropriate.
- Avoid large modules with mixed responsibilities.
- Favor dependency injection over hardcoded globals.

## Error Handling

- Catch the narrowest exception that supports the recovery path.
- Do not use bare `except`.
- Raise meaningful exceptions with useful context.
- Log failures with enough detail to diagnose the issue safely.

## Testing

- Write tests for domain behavior and edge cases.
- Keep tests isolated and deterministic.
- Prefer fixtures that are easy to understand.
- Avoid brittle assertions on incidental formatting or ordering unless it matters.

## Avoid

- Hidden global state.
- Scripts that grow into unstructured applications.
- Overusing metaprogramming when direct code is clearer.
- Catch-all helpers with unrelated responsibilities.
