# Fiber Swagger Example

This example mirrors the Pet Store sample but uses the [Fiber](https://github.com/gofiber/fiber) web framework
and exposes Swagger UI with [`fiber-swagger`](https://github.com/swaggo/fiber-swagger).

## Targets

```bash
# Regenerate docs directly into the source tree (convenient during development)
bazel run //example/fiber:generate_docs

# Generate docs hermetically inside bazel-bin
bazel build //example/fiber:fiber_docs
```

The outputs live in:

- `example/fiber/docs/` when running the script target
- `bazel-bin/example/fiber/fiber_docs/` when building the rule target

## Running the server

The example server depends on Fiber and fiber-swagger. To run it under Bazel add the corresponding
Go module dependencies to your project (e.g. via the `go_deps` extension or `go_repository` rules) and
create a simple `go_binary` target:

```python
load("@rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "fiber_example_lib",
    srcs = glob(["*.go"]),
    importpath = "github.com/tnarg/rules_go_swagger/example/fiber",
)

go_binary(
    name = "fiber_example",
    embed = [":fiber_example_lib"],
)
```

After generating docs you can expose them in Fiber using:

```go
import (
    fiberSwagger "github.com/swaggo/fiber-swagger"
    _ "github.com/tnarg/rules_go_swagger/example/fiber/docs"
)

app.Get("/swagger/*", fiberSwagger.WrapHandler)
```

This keeps the documentation workflow identical to the standard `net/http` example while demonstrating a
Fiber-native setup.
