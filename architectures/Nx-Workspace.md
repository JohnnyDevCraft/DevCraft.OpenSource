# Nx Workspace

## Purpose

Define the default architecture guidance for an Nx workspace.

## When To Use

- A repo contains multiple apps and shared libraries.
- Teams want explicit dependency control and reusable workspace tooling.
- Frontend or full-stack projects need a monorepo structure.

## Core Principles

- The workspace is a dependency graph, not just a folder tree.
- Shared code must have clear ownership and purpose.
- Libraries should exist to support stable boundaries, not convenience dumping.

## Recommended Structure

- Apps remain thin composition roots.
- Libraries are organized by scope and type, such as feature, ui, data-access, domain, or util.
- Tags and lint rules enforce dependency direction.

## Boundary Rules

- Features should not bypass approved dependency paths.
- Shared utilities should stay narrow and generic.
- Avoid creating a common library that everything depends on.
- Use Nx project boundaries intentionally to reflect architecture decisions.

## Data and Integration

- Keep API and integration code in dedicated libraries.
- Keep domain logic separate from framework-heavy UI code when possible.
- Version internal contracts carefully when multiple apps depend on them.

## Testing

- Test libraries close to where the logic lives.
- Keep app-level integration tests focused on composition and workflows.
- Use Nx affected tooling to keep validation fast.

## Avoid

- A monorepo with no meaningful dependency rules.
- Shared libraries that become hidden back doors.
- Moving code to libraries before ownership and reuse are clear.
