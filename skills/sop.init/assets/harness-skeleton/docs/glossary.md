# Business Glossary

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

**Only terms that are private to this project and not publicly known are collected.** Industry-standard concepts (API, SDK, Docker, gRPC, ORM, etc.) and programming language standard terms are out of scope — AI and engineers already know these.

The value of this table: when a skilled senior engineer first touches this project, which words **cannot be inferred from experience**?

## Usage Rules

- When a term in this table is first used in code/docs, use the full name or annotate the abbreviation meaning in parentheses
- New abbreviations must be registered in this table first; using unregistered private abbreviations directly in code is forbidden
- When synonym mixing is found, unify the convention in the "Confusable Term Comparison" section; only one form is used thereafter
- When AI encounters an unfamiliar project-specific term, it should proactively consult this table or ask

## Glossary

| Term | English/Abbreviation | Alias (former name) | Definition (in this project's context) | Origin/Code Path |
|------|-----------|-------------|-------------------|--------------|
| {{project-private entity}} | {{abbreviation}} | {{former name}} | {{exact meaning in this project}} | {{first defined location}} |
| {{project-private action}} | | | | |
| {{project-private role}} | | | | |

> Inclusion criterion: when a senior engineer sees this word for the first time, can they understand it without looking it up? No → include. Yes → do not include.

## Project Abbreviation Quick Reference

| Abbreviation | Full Name | Description |
|------|------|------|
| {{XXX}} | {{Xxx Yyy Zzz}} | {{one sentence}} |

## Confusable Term Comparison

| Term A | Term B | Difference | Unified Form in This Project |
|--------|--------|------|-------------|
| {{word A}} | {{word B}} | {{difference}} | {{chosen word}} |

## Deprecated Terms

| Old Term | Deprecation Date | Replaced By | Reason |
|--------|----------|--------|------|
| {{old word}} | {{YYYY-MM-DD}} | {{new word}} | {{unclear semantics/conflicts with external/renamed}} |

## Do-Not-Include List (reminder)

The following types of terms should **not** be added to this table:
- Industry standards: API, SDK, CI/CD, Docker, K8s, HTTP, gRPC, REST, MQ...
- Language standards: goroutine, channel, Promise, async/await, interface...
- Common database: SQL, NoSQL, index, transaction, migration...
- Common design patterns: MVC, singleton, factory, observer...
- **Terms defined by public protocols/specifications**: DID, VC, VP, OAuth2, OIDC, JWT, JSON-LD, any concept defined in W3C standards...
- **Common infrastructure**: KMS, HSM, SSO, DAL, DAO, CDN, LB, MQ...
- **External services whose names are self-explanatory**: institutions or services understandable from the full name (e.g. CFCA, GLEIF)...
- **Standard role names**: roles defined in public specifications such as Issuer/Holder/Verifier...
- Any word any senior engineer can understand without looking it up
- Any word whose precise definition can be found with a quick web search
