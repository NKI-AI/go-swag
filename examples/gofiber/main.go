package main

import (
	"fmt"
	"strconv"

	"github.com/gofiber/fiber/v2"
	fiberSwagger "github.com/swaggo/fiber-swagger"

	_ "github.com/NKI-AI/rules-go-swag/examples/gofiber/docs"
)

// @title           Pet Store API
// @version         1.0
// @description     This is a sample Pet Store server demonstrating Swagger annotation generation.
// @termsOfService  http://swagger.io/terms/

// @contact.name   API Support
// @contact.url    http://www.swagger.io/support
// @contact.email  support@swagger.io

// @license.name  Apache 2.0
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html

// @host      localhost:3000
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	app := fiber.New()

	// Swagger UI endpoint
	app.Get("/swagger/*", fiberSwagger.WrapHandler)

	// Register API routes
	api := app.Group("/api/v1")
	api.Get("/pets", listPets)
	api.Get("/pets/:id", getPet)
	api.Post("/pets", createPet)

	fmt.Println("Server starting on :3000")
	fmt.Println("This is a demo showing Swagger annotation usage with Fiber.")
	fmt.Println("Run: bazel run //examples/gofiber:generate_docs to generate swagger.json/yaml")
	fmt.Println("")
	fmt.Println("API Endpoints:")
	fmt.Println("  - http://127.0.0.1:3000/api/v1/pets")
	fmt.Println("  - http://127.0.0.1:3000/api/v1/pets/{id}")
	fmt.Println("")
	fmt.Println("Swagger Documentation:")
	fmt.Println("  - http://127.0.0.1:3000/swagger/index.html")

	if err := app.Listen(":3000"); err != nil {
		fmt.Printf("Failed to start server: %s\n", err)
	}
}

// Pet represents a pet in the store
type Pet struct {
	ID   int64  `json:"id" example:"1"`
	Name string `json:"name" example:"Fluffy"`
	Tag  string `json:"tag" example:"cat"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Code    int    `json:"code" example:"400"`
	Message string `json:"message" example:"Bad request"`
}

// listPets godoc
// @Summary      List all pets
// @Description  Get a list of all pets in the store
// @Tags         pets
// @Accept       json
// @Produce      json
// @Success      200  {array}   Pet
// @Failure      500  {object}  ErrorResponse
// @Router       /pets [get]
func listPets(c *fiber.Ctx) error {
	pets := []Pet{
		{ID: 1, Name: "Fluffy", Tag: "cat"},
		{ID: 2, Name: "Buddy", Tag: "dog"},
	}
	return c.JSON(pets)
}

// getPet godoc
// @Summary      Get a pet by ID
// @Description  Get details of a specific pet by ID
// @Tags         pets
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Pet ID"
// @Success      200  {object}  Pet
// @Failure      404  {object}  ErrorResponse
// @Router       /pets/{id} [get]
func getPet(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{
			Code:    400,
			Message: "Invalid ID",
		})
	}

	// Return example pet
	pet := Pet{ID: id, Name: "Fluffy", Tag: "cat"}
	return c.JSON(pet)
}

// createPet godoc
// @Summary      Create a new pet
// @Description  Add a new pet to the store
// @Tags         pets
// @Accept       json
// @Produce      json
// @Param        pet  body      Pet  true  "Pet to create"
// @Success      201  {object}  Pet
// @Failure      400  {object}  ErrorResponse
// @Router       /pets [post]
// @Security     BearerAuth
func createPet(c *fiber.Ctx) error {
	var pet Pet
	if err := c.BodyParser(&pet); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{
			Code:    400,
			Message: "Invalid request",
		})
	}
	pet.ID = 3 // Assign new ID
	return c.Status(fiber.StatusCreated).JSON(pet)
}

