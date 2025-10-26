"""Repository rules for downloading swag tool."""

_SWAG_REPOSITORY_TOOLS_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "swag",
    srcs = ["swag"],
)
"""

def _swag_repository_tools_impl(ctx):
    """Downloads the appropriate swag binary for the current platform."""
    
    # Using swag v1.16.6
    version = "v1.16.6"
    base_url = "https://github.com/swaggo/swag/releases/download/{}/swag_{}_".format(version, version[1:])
    
    if ctx.os.name == "linux":
        if ctx.os.arch == "amd64" or ctx.os.arch == "x86_64":
            swag_url = base_url + "Linux_amd64.tar.gz"
        elif ctx.os.arch == "arm64" or ctx.os.arch == "aarch64":
            swag_url = base_url + "Linux_arm64.tar.gz"
        else:
            fail("Unsupported Linux architecture: " + ctx.os.arch)
    elif ctx.os.name == "mac os x" or ctx.os.name == "darwin":
        if ctx.os.arch == "amd64" or ctx.os.arch == "x86_64":
            swag_url = base_url + "Darwin_x86_64.tar.gz"
        elif ctx.os.arch == "arm64" or ctx.os.arch == "aarch64":
            swag_url = base_url + "Darwin_arm64.tar.gz"
        else:
            fail("Unsupported macOS architecture: " + ctx.os.arch)
    else:
        fail("Unsupported operating system: " + ctx.os.name)

    ctx.download_and_extract(swag_url, "", "")
    ctx.file("BUILD.bazel", _SWAG_REPOSITORY_TOOLS_BUILD_FILE, False)

swag_repository_tools = repository_rule(
    implementation = _swag_repository_tools_impl,
    doc = "Downloads the swag binary for generating Swagger documentation from Go code annotations.",
)

def swag_repositories():
    """Registers the swag tool repository.
    
    This should be called from WORKSPACE or MODULE.bazel setup.
    """
    swag_repository_tools(name = "com_github_swaggo_swag_repository_tools")
