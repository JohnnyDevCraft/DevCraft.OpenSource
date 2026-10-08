# Laravel Standards

## Purpose

Define Laravel-specific standards that build on the shared PHP standards.

## Scope

Apply this standard together with [PHP](./PHP.md) for Laravel applications.

## Core Principles

- Keep Laravel conventions when they improve consistency.
- Keep controllers thin and move business logic into dedicated classes.
- Favor clear request flow from route to controller to action or service to model.
- Preserve readability over framework cleverness.

## Project Structure

- Organize code by feature or bounded domain where practical.
- Keep HTTP concerns in controllers, requests, middleware, and resources.
- Keep domain workflows in actions, services, or domain classes.
- Keep Eloquent models focused on persistence concerns and model relationships.

## HTTP Layer

- Use Form Requests for request authorization and validation when appropriate.
- Use API Resources or dedicated transformers for response shaping when needed.
- Avoid placing non-trivial business logic directly in controllers.
- Keep route definitions readable and grouped logically.

## Database and Models

- Prefer explicit relationships and scopes with descriptive names.
- Avoid fat models that accumulate unrelated workflow logic.
- Use migrations that are reversible and clearly named.
- Apply new migrations promptly during development so downstream work targets the real schema.

## Queues and Jobs

- Use queued jobs for work that should not block the request cycle.
- Keep jobs focused on one responsibility.
- Pass compact, stable identifiers into jobs rather than large mutable models when practical.

## Views and Frontend Integration

- Keep Blade templates focused on presentation.
- Avoid embedding complex query or orchestration logic in views.
- Extract repeated UI fragments into components or partials.
- Keep Livewire or frontend interactions aligned with the existing UX pattern for the project.

## Testing

- Write feature tests for HTTP workflows and integration behavior.
- Write unit tests for domain logic and focused classes.
- Prefer factories and readable fixtures over large setup blocks.
- For web features, add UI coverage with Playwright where the workflow matters.

## Avoid

- Business logic in routes, Blade files, or controllers.
- Massive Eloquent models used as service containers.
- Hidden database work inside accessors and serialization paths.
- Unbounded query behavior that leads to avoidable performance issues.
