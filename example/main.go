package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
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

// @host      localhost:8080
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	// Register HTTP handlers
	http.HandleFunc("/api/v1/pets", handlePets)
	http.HandleFunc("/api/v1/pets/", handlePetByID)

	fmt.Println("Server starting on :8080")
	fmt.Println("This is a demo showing Swagger annotation usage.")
	fmt.Println("Run: bazel run //example:generate_docs to generate swagger.json/yaml")

	if err := http.ListenAndServe(":8080", nil); err != nil {
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

// handlePets handles /api/v1/pets endpoint
func handlePets(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		listPets(w, r)
	case http.MethodPost:
		createPet(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// handlePetByID handles /api/v1/pets/{id} endpoint
func handlePetByID(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		getPet(w, r)
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
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
func listPets(w http.ResponseWriter, r *http.Request) {
	pets := []Pet{
		{ID: 1, Name: "Fluffy", Tag: "cat"},
		{ID: 2, Name: "Buddy", Tag: "dog"},
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(pets)
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
func getPet(w http.ResponseWriter, r *http.Request) {
	// Extract ID from URL path
	idStr := r.URL.Path[len("/api/v1/pets/"):]
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ErrorResponse{Code: 400, Message: "Invalid ID"})
		return
	}

	// Return example pet
	pet := Pet{ID: id, Name: "Fluffy", Tag: "cat"}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(pet)
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
func createPet(w http.ResponseWriter, r *http.Request) {
	var pet Pet
	if err := json.NewDecoder(r.Body).Decode(&pet); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ErrorResponse{Code: 400, Message: "Invalid request"})
		return
	}
	pet.ID = 3 // Assign new ID
	w.WriteHeader(http.StatusCreated)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(pet)
}
