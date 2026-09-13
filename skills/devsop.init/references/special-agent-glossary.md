# glossary.md Special Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `glossary.md` sub-agent, on top of the common prompt. When the main agent dispatches the glossary.md sub-agent, it passes this file's content along.

---

## Core Principle: Better Empty Than Sloppy

**Only record terms that are private to this project and not publicly known.** 15 precise private terms > a 60-term table polluted with public knowledge.

## Inclusion Criteria (three questions; include only if all are "yes")

1. Was this term **invented or redefined by this project**? (not a rehash of a standard definition)
2. Would a seasoned senior engineer **fail to find this project's meaning of the term even when searching for it**?
3. Without explaining this term, would an engineer **genuinely misinterpret the code's intent**?

If any of the three questions is answered "no" → **do not include**. When uncertain, default to not including.

## Must Include

- Abbreviations coined by the project (e.g. TDH = Trusted Data Hub, a project-invented service name)
- Internally combined concepts (e.g. "parent DID / child DID", "VP gateway", "dual binary from the same source")
- Team-internal shorthand (e.g. OC = Operations Center, common = enterprise admin console)
- Identifiers that appear frequently in code but whose names are not self-explanatory (e.g. EnKey, VcSyncer, compatiblev2)
- Pairs of easily-confused near-synonyms, limited to those this project needs to distinguish (e.g. Issuer VC vs Holder VC)

## Forbidden to Include (strictly enforced)

- Industry-common terms (API, SDK, CI/CD, Docker, Kubernetes, HTTP, gRPC)
- Standard programming-language concepts (goroutine, channel, interface, Promise)
- General database concepts (SQL, index, transaction, ORM)
- General design-pattern names (MVC, singleton, observer)
- **Protocol terms defined by public standards/specs** (DID, DID Document, VC, VP, W3C, OAuth2, OIDC, JWT, JSON-LD)
- **General infrastructure concepts** (KMS, HSM, SSO, DAL, DAO, MQ, CDN, LB)
- **Self-explanatory external services/organizations** (e.g. CFCA=China Financial Certification Authority, GLEIF=Global Legal Entity Identifier Foundation)
- **Standard role names** (e.g. the meaning of Issuer/Holder/Verifier in the VC ecosystem)

## Collection Steps

### 1. Identify candidate terms

Scan the following sources:
- package names, core struct/class names in the code (especially abbreviated names that cannot be searched for their meaning)
- Non-self-explanatory keys in config files
- Words that recur in team docs but are never expanded/defined

### 2. Strict filtering (discard by default; keep only on explicit pass)

| Condition | Conclusion |
|------|------|
| Searchable on Google/Wikipedia/W3C/RFC with exactly the same meaning | **Discard** |
| A term defined by some public standard (even if the project uses that standard) | **Discard** |
| A general architecture/infrastructure concept | **Discard** |
| The name is already self-explanatory (e.g. AuthService = authentication service) | **Discard** |
| Confirmed as project-invented, combined, or redefined | **Keep** |

### 3. Writing format

- Write what the term **specifically means in this project**, not an encyclopedia explanation
- If there are aliases/historical names, list them as well
- If there is an easily-confused comparison group, put it in the "Easily-Confused Terms Comparison" section

## Additional Constraints

- When uncertain whether the term is project-private → **do not include** (do not mark TODO; discard directly)
- Forbidden to pad with common terms just to "look complete"
- Forbidden to write generic explanations in the definitions of included terms (e.g. "DID is the W3C decentralized identity identifier standard" — that is encyclopedia rehashing)
- If removing a term would not cause engineers to misread the code → it does not need to be included
