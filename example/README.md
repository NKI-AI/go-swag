# Pet Store API Example

This example demonstrates how to use the Swag Bazel rules to generate Swagger/OpenAPI documentation from Go code annotations.

## Overview

The example implements a simple Pet Store API using the standard library with three endpoints:
- `GET /api/v1/pets` - List all pets
- `GET /api/v1/pets/{id}` - Get a specific pet
- `POST /api/v1/pets` - Create a new pet

The focus is on **generating Swagger documentation from Go code**, not on the web framework.

## Generating Swagger Documentation

To generate the Swagger documentation, run:

```bash
bazel run //example:generate_docs
```

This will create three files in the `example/docs/` directory:
- `swagger.json` - OpenAPI specification in JSON format
- `swagger.yaml` - OpenAPI specification in YAML format
- `docs.go` - Go code with embedded Swagger spec

## Running the Example Server (Optional)

The example also includes a simple HTTP server to demonstrate that it's real working code:

```bash
bazel run //example:example
```

The server will start on `http://localhost:8080` and accept the documented API calls.

## How It Works

1. **Annotations**: The Go code includes Swag annotations in comments:
   - General API info in `main.go` (`@title`, `@version`, etc.)
   - Endpoint documentation on handler functions (`@Summary`, `@Router`, etc.)

2. **Generation**: The `swag_init_script` rule in `BUILD.bazel` scans the Go files and generates documentation:
   ```python
   swag_init_script(
       name = "generate_docs",
       general_info = "example/main.go",
       output_dir = "example/docs",
       search_dirs = ["example"],
   )
   ```

3. **Output**: Three files are created in `example/docs/` that can be:
   - Served with Swagger UI
   - Used with API clients
   - Committed to version control
   - Published as API documentation

## Annotations Reference

### General Info (in main function)
```go
// @title           Pet Store API
// @version         1.0
// @description     This is a sample Pet Store server.
// @host            localhost:8080
// @BasePath        /api/v1
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
```

### Endpoint Documentation
```go
// @Summary      List all pets
// @Description  Get a list of all pets in the store
// @Tags         pets
// @Accept       json
// @Produce      json
// @Success      200  {array}   Pet
// @Failure      500  {object}  ErrorResponse
// @Router       /pets [get]
func listPets(w http.ResponseWriter, r *http.Request) {
    // ...
}
```

### Model Documentation
```go
// Pet represents a pet in the store
type Pet struct {
    ID   int64  `json:"id" example:"1"`
    Name string `json:"name" example:"Fluffy"`
    Tag  string `json:"tag" example:"cat"`
}
```

## Using with Your Framework

While this example uses `net/http`, you can use these rules with any Go web framework:

- **Fiber**: Use with [fiber-swagger](https://github.com/swaggo/fiber-swagger)
- **Gin**: Use with [gin-swagger](https://github.com/swaggo/gin-swagger)
- **Echo**: Use with [echo-swagger](https://github.com/swaggo/echo-swagger)

The Swagger generation is framework-agnostic - it only reads the annotations!

## Next Steps

1. Copy this pattern to your own project
2. Add swag annotations to your handlers
3. Run `bazel run //your:generate_docs`
4. Commit the generated docs or serve them with Swagger UI

For more details on Swag annotations, see the [Swag documentation](https://github.com/swaggo/swag#declarative-comments-format).

