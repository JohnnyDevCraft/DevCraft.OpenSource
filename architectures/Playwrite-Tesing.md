# Playwright Testing

## Purpose

Define the default architecture guidance for building Playwright end-to-end and workflow-focused UI tests.

## When To Use

- The project needs browser-based tests for real user workflows.
- The team wants repeatable coverage for critical page actions and business use cases.
- The application needs confidence that saved state, rendered state, and reload behavior stay aligned.

## Default Language

- Default Playwright test language is JavaScript unless a project has an explicit reason to standardize on another supported language.
- Apply the shared [JavaScript Standards](../standards/Javascript.md) alongside this document.

## Community Baseline

Base the suite on established Playwright guidance and common community practice:

- Test user-visible behavior instead of implementation details.
- Prefer resilient locators based on roles, labels, text, and intentional test ids.
- Use Playwright's built-in isolation, fixtures, locators, and web-first assertions.
- Keep tests independent, readable, and maintainable as the suite grows.

## Core Principles

- Organize tests around a specific use case, not around arbitrary page coverage.
- Keep each test focused on one responsibility and one business outcome.
- Reuse repeated workflow steps through helper functions, fixtures, or page objects.
- Validate happy paths, edge cases, and failure paths for important workflows.
- Verify the final page state after actions complete, not only that a click or submit occurred.
- Treat end-state validation as mandatory, especially for save, update, delete, upload, and authorization flows.
- Prefer observable user outcomes over internal implementation knowledge.

## Recommended Test Scope

Each Playwright test should target a clear use case such as:

- user logs in and lands on the expected dashboard
- user creates a record and sees it rendered immediately
- user edits a record and sees the updated state after reload
- user submits invalid data and sees the correct validation or failure state

Do not create broad "test everything on this page" specs that mix unrelated behaviors into one large flow.

Treat this as a hard rule:

- one test per use case
- one responsibility per test

If a scenario needs to cover create, edit, delete, validation, and persistence-after-reload, that should usually be multiple tests, not one giant test.

## Recommended Project Structure

Use a structure that keeps test intent, page interaction, and reusable workflow logic separate.

```text
/playwright
  /fixtures
  /helpers
  /pages
  /specs
    /<feature-name>
```

Recommended responsibilities:

- `specs`: use-case-focused tests and assertions
- `pages`: page objects or page-level interaction models
- `helpers`: reusable workflow tasks such as login, logout, seed navigation, and data cleanup
- `fixtures`: shared environment setup, authenticated contexts, and test configuration

## Reusable Workflow Functions

When a task is repeated across multiple tests, extract it into a reusable function or page object method.

Common examples:

- login
- logout
- navigate to a feature area
- create a common record fixture
- open modal or drawer workflows

For modal and drawer workflows, reusable helpers should make it easy to validate both the opened surface and the surrounding chrome state.

Do not duplicate fragile UI sequences across many tests when a single reusable abstraction can own that behavior.

## Responsibility Boundaries

Follow SOLID principles with an emphasis on Single Responsibility:

- test files should express the scenario, business intent, and assertions
- helper modules should perform reusable workflow steps
- page objects should encapsulate page interactions and locator ownership
- fixtures should prepare context, not hide business assertions

Avoid "god" page objects or giant helper files that own unrelated workflows across the whole application.

## Assertion Strategy

Every important use case should cover:

- happy path behavior
- edge cases
- failure paths that prove the application fails properly

Assertions should prove user-observable outcomes such as:

- correct URL or route state
- visible success or error messaging
- expected control state such as enabled, disabled, checked, or hidden
- expected saved values rendered on screen
- expected data still present after reload when persistence is part of the workflow

Do not stop at "the submit button was clicked" or "the API returned 200" if the user-visible state was not verified.

## Page State Validation

When a test completes an action, verify the page state that should exist afterward.

Examples:

- after save, the saved data is visible on screen
- after reload, the saved data is still visible
- after delete, the deleted item is gone from the UI
- after validation failure, the form stays in a recoverable state and the user sees actionable feedback
- after logout, protected content is no longer accessible

For workflows that write to the database, validate the persisted result through the UI whenever the use case depends on the user seeing that state.

Minimum expectation for persistence-sensitive workflows:

- perform the action
- assert the resulting rendered state immediately
- reload or revisit when persistence matters
- assert the rendered state again after reload

Minimum expectation for modal and overlay workflows:

- assert the modal or drawer is visible
- assert the backdrop visually or structurally covers the surrounding page
- assert elevated chrome such as navbars, sticky headers, floating action buttons, and toasts do not render above the backdrop or focused surface
- if stacking is wrong, inspect parent stacking contexts instead of only comparing the modal element's own `z-index`
- assert modal overflow stays inside the surface on shorter viewports when large content is expected

Do not consider a save or upload flow covered if the test stops before the post-action and post-reload state checks.

## Screenshot Review

- For UI-affecting changes, capture screenshots during validation.
- Review the screenshots to confirm the rendered UI looks correct, not just that selectors passed.
- End each coding cycle with a final screenshot review of the affected UI before closing the task.
- If the screenshot reveals layout, visibility, spacing, or visual-state issues, continue refining instead of closing the work.

## Isolation And Data Handling

- Keep each test independent and safe to run alone or in parallel.
- Prefer creating or resetting the required state per test or per describe block through intentional setup.
- Do not make one test depend on another test to create data.
- Keep cleanup predictable when tests create durable records.

## Locator And Waiting Guidance

- Prefer `getByRole`, `getByLabel`, `getByText`, and well-defined test ids over CSS or XPath selectors.
- Use Playwright locators and web-first assertions instead of manual sleeps.
- Let Playwright auto-wait for actionable elements and expected states.
- Use explicit assertions for readiness and completion when the user experience depends on them.

## Common Risks And Anti-Patterns

- tests coupled to CSS classes or brittle DOM structure
- large end-to-end tests with too many unrelated assertions
- duplicated login and navigation flows across the suite
- helpers that hide the meaning of the test
- tests that verify transport behavior but not user-visible state
- tests that save data without proving the saved state is rendered correctly after reload
- tests that stop after an upload or save action without proving the new asset or data is actually being used in the UI
- closing UI work without reviewing screenshots of the final rendered state
- serial test chains where one test depends on another test's side effects

## Delivery Expectation

A strong Playwright suite should read like business workflows, stay maintainable as pages evolve, and prove that the application behaves correctly for successful, invalid, and failing user paths.
