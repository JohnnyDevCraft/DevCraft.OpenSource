# TypeScript Standards

## Purpose

Define default coding standards for TypeScript applications, libraries, frontend code, backend code, and tests.

## Baseline

Microsoft does not publish one universal TypeScript standard for every team, so this standard starts from Microsoft's public TypeScript practices in Visual Studio Code and the Azure SDK, then adds local defaults where needed.

### Microsoft Published Baseline

- Visual Studio Code coding guidelines from the Microsoft `vscode` repository
- Azure SDK for TypeScript design and implementation guidance from Microsoft
- TypeScript usage patterns in Microsoft-maintained repos and configs

## Core Principles

- Follow established TypeScript and JavaScript conventions before introducing project-specific patterns.
- Prefer type safety over convenience shortcuts.
- Optimize for maintainability and refactor safety.
- Keep runtime behavior simple and types honest.
- Model the domain clearly instead of over-generalizing too early.

## Naming

- Use `PascalCase` for components, classes, types, interfaces, and enums.
- Use `camelCase` for variables, functions, methods, and object properties unless an external API requires otherwise.
- Use `UPPER_SNAKE_CASE` for true constants.
- Use whole words in names when practical.
- Name types based on business meaning, not transport shape when possible.

## File Organization

- Keep files focused and easy to navigate.
- Group code by feature or domain when practical.
- Keep type definitions close to the code that owns them.
- Split files before they become difficult to scan.
- Keep shared utilities narrow and well named.

## Type Usage

- Prefer specific types over `any`.
- Use `unknown` instead of `any` when a value must be narrowed safely.
- Prefer discriminated unions for branching state.
- Avoid unnecessary type assertions.
- Do not export types, values, or helpers more broadly than needed.
- Keep public function signatures explicit.
- Use readonly data structures where mutation is not intended.

## Style

- Prefer `const` by default, then `let` when reassignment is needed.
- Use single quotes unless a framework or localization pattern requires otherwise.
- Use arrow functions over anonymous function expressions unless a named function improves stack traces or readability.
- Prefer `export function foo()` at top level over `export const foo = () =>` when exporting a normal function.
- Always use braces for loop and conditional bodies.
- Use small, focused functions.
- Return early to reduce nesting.
- Prefer explicit null and undefined handling.
- Keep async flows readable and predictable.

## Layout

- Keep imports grouped and ordered consistently.
- Put exported types and functions near the top of the file when that improves scanning.
- Keep internal helpers below the main exported API when practical.
- Separate UI strings from implementation logic when the platform requires localization.

## Design Guidance

- Separate API, domain, and UI concerns.
- Keep validation at boundaries such as requests, forms, and external inputs.
- Prefer pure functions for transformations.
- Avoid large generic abstractions unless they clearly reduce duplication.
- Avoid introducing globals.
- Externalize user-visible strings when the host platform expects localization support.

## Testing

- Cover domain logic and edge cases with automated tests.
- Test user-facing behavior for UI code.
- Mock external systems thoughtfully and minimally.
- Keep fixtures small and readable.

## Avoid

- `any` in production code without a documented reason.
- Overloaded utility modules with unrelated helpers.
- Type assertions used to silence legitimate type errors.
- Deeply nested object access without guards.

## Notes

- If a repository already defines ESLint, Prettier, or project-level TypeScript conventions, that repository configuration takes precedence over this shared baseline.
