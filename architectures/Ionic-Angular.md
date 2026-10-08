# Ionic Angular

## Purpose

Define the default architecture guidance for Ionic Angular applications.

## When To Use

- The project is an Angular application targeting mobile-style experiences through Ionic.
- The application may target iOS, Android, and web from one codebase.

## Core Principles

- Treat the app as Angular first and Ionic-aware second.
- Keep business logic independent of device and UI framework details.
- Respect mobile constraints such as latency, offline behavior, and lifecycle changes.

## Recommended Structure

- Organize by feature.
- Keep Ionic page flows, components, services, and tests aligned by feature area.
- Isolate native or Capacitor integrations behind dedicated services or adapters.

## UI and Device Boundaries

- Keep Ionic UI concerns in components and pages.
- Keep device APIs behind clear abstractions.
- Avoid scattering native plugin calls across multiple UI files.

## Data and State

- Keep API calls and persistence logic separate from pages.
- Plan explicitly for loading, connectivity, and recovery states.
- Use local storage or offline sync intentionally where the UX requires it.

## Testing

- Unit test services and domain logic.
- Component test key interactive flows.
- Run end-to-end coverage for critical mobile journeys where feasible.

## Avoid

- Treating mobile lifecycle behavior as identical to desktop web.
- Mixing device APIs directly into presentation code.
- Overloading one page component with app orchestration.
