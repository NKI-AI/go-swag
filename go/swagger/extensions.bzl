"""Module extension for swag toolchain."""

load("//go/swagger/private:repositories.bzl", "swag_repository_tools")

def _swag_extension_impl(module_ctx):
    """Implementation of the swag module extension.
    
    This extension registers the swag tool repository.
    """
    # Register the swag repository tools
    swag_repository_tools(name = "com_github_swaggo_swag_repository_tools")
    
    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = ["com_github_swaggo_swag_repository_tools"],
        root_module_direct_dev_deps = [],
    )

swag_extension = module_extension(
    implementation = _swag_extension_impl,
    doc = "Extension to register the swag tool repository.",
)

