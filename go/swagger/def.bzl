"""Public API for swag Bazel rules."""

load(
    "//go/swagger/private:repositories.bzl",
    _swag_repositories = "swag_repositories",
)
load(
    "//go/swagger/private:swag_docs.bzl",
    _swag_docs = "swag_docs",
    _swag_init_script = "swag_init_script",
)

swag_repositories = _swag_repositories
swag_docs = _swag_docs
swag_init_script = _swag_init_script
