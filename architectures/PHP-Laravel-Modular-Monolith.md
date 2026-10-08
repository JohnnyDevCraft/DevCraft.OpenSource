# PHP Laravel Modular Monolith

## Purpose

Define the default architecture guidance for a Laravel modular monolith.

## When To Use

- The team wants one Laravel application with strong internal module boundaries.
- A single deployment artifact is preferred.
- The product has multiple business areas that should not collapse into one large app folder.

## Core Principles

- Keep Laravel as the host framework, not the architecture.
- Organize by business module.
- Keep module boundaries explicit even though the app is deployed as one unit.
- Allow modules to evolve independently inside the same application.

## Runtime Baseline

- Default PHP version: **PHP 8.3**.
- When creating a new Laravel project or running `composer install` / `composer update`, use PHP 8.3 so dependency resolution matches our baseline.
- In `composer.json`, set `config.platform.php` to an 8.3 patch version (for example `8.3.0`) unless the project has an explicit reason to target a different runtime.

## Recommended Structure

- One Laravel application as the host.
- A clear module structure under a shared modules area or a feature-first app structure.
- Each module owns controllers, requests, actions, domain logic, models, policies, views, and tests where practical.
- Shared infrastructure should stay thin and intentional.

## Module Boundaries

- Avoid direct use of another module's internals.
- Prefer explicit services, actions, events, or contracts for cross-module collaboration.
- Keep routes and UI concerns aligned to the owning module.
- Cross-module references should cross boundaries by record id, not by direct model coupling.
- If one module must display or preserve another module's label text, persist a local snapshot such as `RemoteId` and `RemoteLabel` rather than reaching across the boundary during reads.
- Exception: a modular monolith may define one intentional shared module/package for reusable cross-cutting code that all modules can consume.
- That one shared module/package may expose reusable public APIs by design, but it must not absorb module-owned business rules or module-owned persistence concerns.

## Data and Integration

- Prefer module-owned tables and model workflows.
- Do not let one module become the shared dump site for unrelated data.
- Use events, queued jobs, and actions for cross-module workflows when that improves separation.
- Apply new migrations immediately after creating them during development so downstream implementation targets the real schema state.
- When a source module changes data that other modules mirror or display, emit an event with the updated state so dependent modules can refresh their local snapshots and read models.
- Treat successful data-changing commands as event sources by default when their state matters outside the owning module.

## Testing

- Unit test module business logic.
- Feature test HTTP workflows per module.
- Add UI testing for key web flows.
- Add boundary tests if module contracts are easy to violate accidentally.
- Add boundary tests for id-only references, emitted events, and local snapshot refresh when modules mirror remote labels.

## Avoid

- A giant `app/Services` folder as a catch-all for every module.
- Direct cross-module model mutation without an explicit workflow.
- Blade views or controllers containing business orchestration.
