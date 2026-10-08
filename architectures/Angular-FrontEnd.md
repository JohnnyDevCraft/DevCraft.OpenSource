# Angular FrontEnd

## Purpose

Define the default architecture guidance for Angular frontend applications.

## When To Use

- The project is an Angular web application or portal.
- The UI requires structured state, routing, and component composition.

## Core Principles

- Organize by feature, not only by technical artifact type.
- Keep components focused on presentation and interaction.
- Keep state and data access explicit.
- Preserve a clear distinction between UI, orchestration, and API integration code.

## Recommended Structure

- Feature areas own their routes, pages, components, services, and tests.
- Shared UI libraries should contain reusable components, directives, and pipes only when reuse is real.
- Core application concerns such as auth, shell, and app-wide services should be centralized and small.

## Component Boundaries

- Smart container components coordinate state and workflows.
- Presentational components focus on rendering and user interaction.
- Avoid large components that fetch data, manage state, transform models, and render complex views all in one file.

## Data and State

- Keep API calls in dedicated services or data-access layers.
- Keep domain mapping close to the boundary where API data enters the app.
- Choose state management based on complexity, not fashion.

## Testing

- Unit test components, services, and domain transformations.
- Test routing and user workflows where behavior matters.
- Add end-to-end testing for critical journeys.

## Avoid

- Massive shared modules full of unrelated exports.
- Components with too many responsibilities.
- Direct API logic scattered across UI files.
