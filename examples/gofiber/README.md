# Pet Store API Example (Fiber)

This example demonstrates how to use the Swag Bazel rules to generate Swagger/OpenAPI documentation from Go code annotations using the [Fiber](https://gofiber.io/) web framework.

## Overview

This implements the same Pet Store API as the `examples/http` but using the Fiber framework instead of the standard library. The API has three endpoints:
- `GET /api/v1/pets` - List all pets
- `GET /api/v1/pets/{id}` - Get a specific pet
- `POST /api/v1/pets` - Create a new pet

The focus is on **generating Swagger documentation from Go code**, showing that it works with any Go web framework.

## Generating Swagger Documentation

To generate the Swagger documentation, run:

```bash
bazel run //examples/gofiber:generate_docs
```

This will create three files in the `examples/gofiber/docs/` directory:
- `swagger.json` - OpenAPI specification in JSON format
- `swagger.yaml` - OpenAPI specification in YAML format
- `docs.go` - Go code with embedded Swagger spec

## Running the Example Server

The example includes a Fiber-based HTTP server to demonstrate that it's real working code:

```bash
bazel run //examples/gofiber:example
```

The server will start on `http://localhost:3000` and accept the documented API calls.

You can view the Swagger UI at `http://localhost:3000/swagger/index.html`.

## How It Works

1. **Annotations**: The Go code includes the same Swag annotations as the `examples/http`:
   - General API info in `main.go` (`@title`, `@version`, etc.)
   - Endpoint documentation on handler functions (`@Summary`, `@Router`, etc.)

2. **Generation**: The `swag_init_script` rule in `BUILD.bazel` scans the Go files and generates documentation:
   ```python
   swag_init_script(
       name = "generate_docs",
       general_info = "main.go",  # Relative to search_dirs
       output_dir = "examples/gofiber/docs",  # Relative to workspace root
       search_dirs = ["examples/gofiber"],  # Relative to workspace root
   )
   ```

3. **Output**: Three files are created in `examples/gofiber/docs/` that can be:
   - Served with Swagger UI (which this example demonstrates)
   - Used with API clients
   - Committed to version control
   - Published as API documentation

## Framework-Specific Code

The Fiber-specific handler code is cleaner and more concise:

```go
// @Summary      List all pets
// @Router       /pets [get]
func listPets(c *fiber.Ctx) error {
    pets := []Pet{
        {ID: 1, Name: "Fluffy", Tag: "cat"},
        {ID: 2, Name: "Buddy", Tag: "dog"},
    }
    return c.JSON(pets)
}
```

But the **Swagger annotations are identical** across frameworks! This demonstrates that Swag is framework-agnostic.

## Swagger UI Integration

This example demonstrates serving Swagger UI using the [fiber-swagger](https://github.com/swaggo/fiber-swagger) middleware:

```go
import (
    fiberSwagger "github.com/swaggo/fiber-swagger"
    _ "github.com/NKI-AI/rules-go-swag/examples/gofiber/docs"
)

app.Get("/swagger/*", fiberSwagger.WrapHandler)
```

The middleware automatically serves the Swagger UI at `http://localhost:3000/swagger/index.html`.

## Comparison with net/http Example

Both examples (`examples/http` and `examples/gofiber`) implement the same API with identical Swagger annotations, demonstrating that:

1. **Swag is framework-agnostic** - Only the handler code changes, not the annotations
2. **Documentation generation is the same** - Same `swag_init_script` rule configuration
3. **Output is identical** - Both produce the same OpenAPI specification

## Next Steps

1. Choose your preferred framework (or use the standard library)
2. Add Swag annotations to your handlers
3. Run `bazel run //your:generate_docs`
4. Use the generated docs with Swagger UI or API clients

For more details on Swag annotations, see the [Swag documentation](https://github.com/swaggo/swag#declarative-comments-format).

