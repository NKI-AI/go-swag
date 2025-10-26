package main

import (
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
	fiberSwagger "github.com/swaggo/fiber-swagger"
)

// @title           Fiber Todo API
// @version         1.0
// @description     Demonstrates how to document a Fiber application with swag and Bazel.
// @termsOfService  https://example.com/terms
// @contact.name    API Support
// @contact.url     https://example.com/support
// @contact.email   support@example.com
// @license.name    MIT
// @license.url     https://opensource.org/licenses/MIT
// @host            localhost:8080
// @BasePath        /api/v1
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	app := fiber.New()

	// Swagger UI endpoint
	app.Get("/swagger/*", fiberSwagger.WrapHandler)

	registerRoutes(app)

	log.Println("Fiber server listening on :8080")
	log.Println("Run: bazel run //example/fiber:generate_docs to refresh Swagger artifacts")

	if err := app.Listen(":8080"); err != nil {
		log.Fatalf("fiber.Listen failed: %v", err)
	}
}

// Todo represents a single todo item.
type Todo struct {
	ID          int       `json:"id" example:"1"`
	Title       string    `json:"title" example:"Learn Bazel"`
	Description string    `json:"description" example:"Regenerate swagger docs with swag_docs"`
	Due         time.Time `json:"due" example:"2024-01-31T17:00:00Z"`
	Completed   bool      `json:"completed" example:"false"`
}

// ErrorResponse represents a standard error payload.
type ErrorResponse struct {
	Code    int    `json:"code" example:"404"`
	Message string `json:"message" example:"Todo not found"`
}

func registerRoutes(app *fiber.App) {
	api := app.Group("/api/v1")

	api.Get("/todos", listTodos)
	api.Get("/todos/:id", getTodo)
	api.Post("/todos", createTodo)
}

// listTodos godoc
// @Summary      List all todos
// @Description  Returns a collection of todos that require attention.
// @Tags         todos
// @Accept       json
// @Produce      json
// @Success      200  {array}   Todo
// @Failure      500  {object}  ErrorResponse
// @Router       /todos [get]
func listTodos(c *fiber.Ctx) error {
	todos := []Todo{
		{ID: 1, Title: "Learn Bazel", Description: "Understand swag_docs rule", Due: time.Now().Add(24 * time.Hour)},
		{ID: 2, Title: "Ship API", Description: "Document Fiber handlers", Due: time.Now().Add(72 * time.Hour)},
	}

	return c.Status(fiber.StatusOK).JSON(todos)
}

// getTodo godoc
// @Summary      Fetch a todo by ID
// @Description  Retrieves an individual todo using its identifier.
// @Tags         todos
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Todo ID"
// @Success      200  {object}  Todo
// @Failure      404  {object}  ErrorResponse
// @Router       /todos/{id} [get]
func getTodo(c *fiber.Ctx) error {
	todo := Todo{ID: 1, Title: "Learn Bazel", Description: "Understand swag_docs rule", Due: time.Now().Add(24 * time.Hour)}
	return c.Status(fiber.StatusOK).JSON(todo)
}

// createTodo godoc
// @Summary      Create a new todo
// @Description  Adds a todo item to the backlog.
// @Tags         todos
// @Accept       json
// @Produce      json
// @Param        todo  body      Todo  true  "Todo to create"
// @Success      201  {object}  Todo
// @Failure      400  {object}  ErrorResponse
// @Router       /todos [post]
// @Security     BearerAuth
func createTodo(c *fiber.Ctx) error {
	todo := Todo{}
	if err := c.BodyParser(&todo); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Code: 400, Message: "Invalid payload"})
	}

	todo.ID = 99
	return c.Status(fiber.StatusCreated).JSON(todo)
}
