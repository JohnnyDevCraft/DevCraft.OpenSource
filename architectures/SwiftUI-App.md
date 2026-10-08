# SwiftUI App

## Purpose

Define the default architecture guidance for SwiftUI applications.

## When To Use

- The app is built with SwiftUI for Apple platforms.
- The product needs a declarative UI architecture with native platform behavior.

## Core Principles

- Keep views focused on presentation and interaction.
- Keep state ownership explicit.
- Preserve a stable, predictable data flow.
- Use small dedicated views instead of giant composed bodies.

## Recommended Structure

- Organize by feature.
- Keep screens, supporting views, models, and services aligned by feature area.
- Keep platform services and side effects behind dedicated abstractions.

## View and State Boundaries

- Views render state and send user intent outward.
- Business logic and long-running effects should not be buried in view bodies.
- Keep state close to the feature that owns it.
- Make dependency injection explicit.

## Data and Integration

- Keep network, persistence, and platform integration outside view code.
- Map external data into app-specific models intentionally.
- Keep async workflows observable and easy to reason about.

## Testing

- Unit test domain logic and transformation code.
- Test view models or feature controllers where used.
- Add UI testing for key user journeys.

## Avoid

- Very large view files with many responsibilities.
- Side effects triggered from arbitrary rendering paths.
- Hidden global state passed implicitly through too many layers.
