# Validation

Verified during portfolio cleanup:

- `npm ci` and `npm run build` pass.
- `npm run type-check` passes.
- `node --test tests/ai-routes.test.cjs` passes, covering unauthenticated requests, missing provider configuration, and server-side provider-key isolation with a mocked provider.

Live database, file-storage and paid-provider end-to-end flows were not run. The new AI endpoints require the corresponding client cleanup.

This remains an academic prototype. Resume storage uses public object URLs: use synthetic PDFs for demonstrations. Before real public use, implement private storage/signed URLs, request validation, rate limits, spending limits, and review all authorization boundaries. The configuration and security changes are not a comprehensive security audit.

The uploaded PDF was removed from current branch contents, but remains in older commits. Do not mirror history to another public account without reviewing that document and deciding on history sanitization.
