# PHP Standards

## Purpose

Define default coding standards for PHP applications, libraries, CLI commands, jobs, and tests.

## Core Principles

- Prefer clear, maintainable code over clever shortcuts.
- Keep domain language explicit.
- Organize code so responsibilities are easy to locate.
- Push framework-agnostic logic into plain PHP classes when practical.

## Naming

- Use `PascalCase` for classes, interfaces, enums, and traits.
- Use `camelCase` for methods, variables, and properties.
- Use descriptive names that reflect business meaning.
- Suffix interfaces only when the team convention requires it; otherwise prefer behavior-based naming.

## File Organization

- Keep one primary class per file.
- Match file names to class names.
- Organize by feature or domain where possible.
- Separate framework wiring from domain logic.

## Style

- Follow PSR-12 formatting.
- Use strict typing where supported and practical.
- Prefer constructor injection over service location.
- Keep methods small and focused.
- Return early to reduce nesting.

## Design Guidance

- Keep controllers, commands, and jobs thin.
- Put reusable business logic in services, actions, or domain classes with clear responsibilities.
- Prefer value objects and small abstractions when they clarify the model.
- Validate external input at boundaries.

## Error Handling

- Throw meaningful exceptions for invalid states.
- Avoid suppressing warnings and notices.
- Log operational failures with actionable context.
- Do not leak secrets in logs or responses.

## Testing

- Write unit tests for business logic and integration tests where boundaries matter.
- Keep tests readable and scenario focused.
- Avoid over-mocking internal behavior.

## Avoid

- Fat controllers.
- Static helper sprawl.
- Mixed HTML, query logic, and domain logic in the same place.
- Generic service classes with unclear responsibilities.
