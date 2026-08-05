# go-zero framework specialization instructions

> When `$FRAMEWORK = go-zero`, sub-agents for the files below must follow the requirements in the corresponding sections of this file in addition to the common prompt.

---

## Additional requirements for the coding-style.md sub-agent

- Directory layering conventions: must follow the go-zero standard layering `handler → logic → svc → model`
- Naming conventions: handler files named `xxxHandler`; logic files named `xxxLogic`
- ServiceContext usage conventions: all dependencies are injected via `svc.ServiceContext`; instantiating external dependencies directly in logic is forbidden
- Configuration management: config structs defined in `internal/config/`, loaded via `etc/*.yaml`
- Middleware definition location and registration method
- error handling: use `errorx` for unified error codes; returning bare `error` to the frontend is forbidden

## Additional requirements for the api-standards.md sub-agent

- API definition: must be defined via `.api` files, with code generated using `goctl api go`
- Route grouping: usage conventions for the `group`, `prefix`, and `middleware` attributes of the `@server` annotation
- Request/response structs: define `type` in `.api` files; hand-writing handler-layer structs is forbidden
- JWT authentication: declared via `jwt: Auth` in `.api` files; hand-writing a JWT middleware is forbidden
- Version management: API versions are controlled via `prefix: /api/v1`
- Error code conventions: uniformly use `httpx.ErrorCtx` + custom error structs
- RPC service calls: connect via `zrpc.MustNewClient`, initialized in ServiceContext

## Additional requirements for the unittest.md sub-agent

- Unit testing focus: the logic layer is the core test target; the handler layer is usually not tested separately
- Mock strategy: abstract dependencies in `svc.ServiceContext` into interfaces, then mock
- Integration testing: use `testcontainers` or a local docker-compose to spin up dependencies
- API testing: `httptest` can be used to test the full handler chain
- Test file location: same directory as the file under test, named `xxx_test.go`
- goctl-generated code is not tested (generated code is not tested); only the business logic in logic is tested

## Additional requirements for the development.md sub-agent

- goctl tool version requirements and installation method
- Development flow: `.api` file definition → `goctl api go` generation → fill in business logic in logic
- RPC development flow: `.proto` definition → `goctl rpc protoc` generation → fill in logic
- Local run dependencies: etcd (service discovery), Redis (cache), MySQL/PostgreSQL, etc.
- Config files: explanation of the `etc/xxx-api.yaml` local development configuration
- Multi-service joint debugging: service registration/discovery mechanism, local hosts configuration

---

## Identification characteristics

The main agent confirms the project uses go-zero via the following characteristics:

- `go.mod` contains `github.com/zeromicro/go-zero`
- `.api` or `.proto` definition files exist
- Directories contain `internal/{handler,logic,svc,types}`

## Other frameworks

When `$FRAMEWORK` has another value or is unrecognized, process per the generic template without injecting this file's content.

> Extending a new framework: create `references/framework-<name>.md`, and the main agent will automatically match and load it based on the `$FRAMEWORK` value.
