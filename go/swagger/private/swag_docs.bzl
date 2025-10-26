"""Build rule for generating Swagger documentation from Go code annotations."""

def _swag_docs_impl(ctx):
    """Implementation of swag_docs rule.
    
    Generates swagger.json, swagger.yaml, and docs.go from Go source files with swag annotations.
    """
    swag = ctx.executable._swag
    
    # Build the swag init command arguments
    args = ctx.actions.args()
    args.add("init")
    
    # General info file (main.go with API annotations)
    args.add("--generalInfo", ctx.file.general_info.path)
    
    # Output directory - use a temporary directory in bazel-bin
    output_dir = ctx.actions.declare_directory(ctx.label.name + "_docs")
    args.add("--output", output_dir.path)
    
    # Search directories
    if ctx.attr.search_dirs:
        args.add("--dir", ",".join(ctx.attr.search_dirs))
    
    # Optional flags
    if ctx.attr.parse_dependency:
        args.add("--parseDependency")
    
    if ctx.attr.parse_internal:
        args.add("--parseInternal")
    
    if ctx.attr.parse_vendor:
        args.add("--parseVendor")
    
    if ctx.attr.parse_depth:
        args.add("--parseDepth", str(ctx.attr.parse_depth))
    
    if ctx.attr.output_types:
        args.add("--outputTypes", ",".join(ctx.attr.output_types))
    
    if ctx.attr.instance_name:
        args.add("--instanceName", ctx.attr.instance_name)
    
    # Declare output files
    swagger_json = ctx.actions.declare_file(ctx.label.name + "/swagger.json")
    swagger_yaml = ctx.actions.declare_file(ctx.label.name + "/swagger.yaml")
    docs_go = ctx.actions.declare_file(ctx.label.name + "/docs.go")
    
    # Collect all source files as inputs
    srcs = []
    for src in ctx.attr.srcs:
        srcs.extend(src[DefaultInfo].files.to_list())
    
    # Run swag init
    ctx.actions.run(
        executable = swag,
        arguments = [args],
        inputs = srcs + [ctx.file.general_info],
        outputs = [output_dir],
        mnemonic = "SwagInit",
        progress_message = "Generating Swagger documentation for %s" % ctx.label.name,
    )
    
    # Copy files from output_dir to declared outputs
    ctx.actions.run_shell(
        inputs = [output_dir],
        outputs = [swagger_json, swagger_yaml, docs_go],
        command = """
        cp {dir}/swagger.json {json}
        cp {dir}/swagger.yaml {yaml}
        cp {dir}/docs.go {go}
        """.format(
            dir = output_dir.path,
            json = swagger_json.path,
            yaml = swagger_yaml.path,
            go = docs_go.path,
        ),
    )
    
    return [
        DefaultInfo(files = depset([swagger_json, swagger_yaml, docs_go])),
        OutputGroupInfo(
            json = depset([swagger_json]),
            yaml = depset([swagger_yaml]),
            go = depset([docs_go]),
            all = depset([swagger_json, swagger_yaml, docs_go]),
        ),
    ]

swag_docs = rule(
    implementation = _swag_docs_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".go"],
            doc = "Go source files to scan for Swagger annotations",
        ),
        "general_info": attr.label(
            allow_single_file = [".go"],
            mandatory = True,
            doc = "Main Go file containing general API info annotations (@title, @version, etc.)",
        ),
        "search_dirs": attr.string_list(
            doc = "Comma-separated list of directories to search for annotations (relative to workspace root)",
        ),
        "parse_dependency": attr.bool(
            default = False,
            doc = "Parse dependency in go.mod file",
        ),
        "parse_internal": attr.bool(
            default = False,
            doc = "Parse internal packages",
        ),
        "parse_vendor": attr.bool(
            default = False,
            doc = "Parse vendor folder",
        ),
        "parse_depth": attr.int(
            default = 100,
            doc = "Dependency parse depth",
        ),
        "output_types": attr.string_list(
            default = ["go", "json", "yaml"],
            doc = "Output types (go, json, yaml)",
        ),
        "instance_name": attr.string(
            doc = "Instance name for docs.go (default: swagger)",
        ),
        "_swag": attr.label(
            default = Label("@com_github_swaggo_swag_repository_tools//:swag"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = """Generates Swagger documentation from Go code with swag annotations.
    
    Example:
        swag_docs(
            name = "swagger_docs",
            srcs = glob(["**/*.go"]),
            general_info = "main.go",
            search_dirs = ["./"],
            parse_dependency = True,
            parse_internal = True,
        )
    
    This generates swagger.json, swagger.yaml, and docs.go from annotated Go source files.
    """,
)

def _swag_init_script_impl(ctx):
    """Implementation of swag_init_script rule.
    
    Creates a script that runs swag init and writes files to the source tree.
    This is useful for regenerating documentation during development.
    """
    swag = ctx.executable._swag
    
    # Create the script
    script_content = """#!/bin/bash
set -e

# Change to workspace directory
cd "$BUILD_WORKSPACE_DIRECTORY"

# Run swag init
{swag} init \\
  --generalInfo {general_info} \\
  --output {output_dir} \\
  --dir {search_dirs} \\
  {parse_flags} \\
  --outputTypes {output_types}

echo ""
echo "✓ Swagger documentation generated successfully!"
echo "  Location: $BUILD_WORKSPACE_DIRECTORY/{output_dir}"
echo ""
echo "Generated files:"
ls -1 "$BUILD_WORKSPACE_DIRECTORY/{output_dir}" 2>/dev/null || true
""".format(
        swag = swag.short_path,
        general_info = ctx.attr.general_info,
        output_dir = ctx.attr.output_dir,
        search_dirs = ",".join(ctx.attr.search_dirs) if ctx.attr.search_dirs else "./",
        parse_flags = " ".join([
            "--parseDependency" if ctx.attr.parse_dependency else "",
            "--parseInternal" if ctx.attr.parse_internal else "",
            "--parseVendor" if ctx.attr.parse_vendor else "",
        ]),
        output_types = ",".join(ctx.attr.output_types),
    )
    
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )
    
    return [
        DefaultInfo(
            executable = script,
            runfiles = ctx.runfiles(files = [swag]),
        ),
    ]

swag_init_script = rule(
    implementation = _swag_init_script_impl,
    executable = True,
    attrs = {
        "general_info": attr.string(
            mandatory = True,
            doc = "Main Go file with general API info (relative to workspace root)",
        ),
        "output_dir": attr.string(
            mandatory = True,
            doc = "Output directory for generated docs (relative to workspace root)",
        ),
        "search_dirs": attr.string_list(
            doc = "Directories to search for annotations (relative to workspace root)",
        ),
        "parse_dependency": attr.bool(
            default = False,
            doc = "Parse dependency in go.mod file",
        ),
        "parse_internal": attr.bool(
            default = False,
            doc = "Parse internal packages",
        ),
        "parse_vendor": attr.bool(
            default = False,
            doc = "Parse vendor folder",
        ),
        "output_types": attr.string_list(
            default = ["go", "json", "yaml"],
            doc = "Output types (go, json, yaml)",
        ),
        "_swag": attr.label(
            default = Label("@com_github_swaggo_swag_repository_tools//:swag"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = """Creates a script to run swag init and write to the source tree.
    
    Example:
        swag_init_script(
            name = "generate_swagger",
            general_info = "cmd/server/main.go",
            output_dir = "internal/docs",
            search_dirs = ["cmd/server", "internal/handlers"],
            parse_dependency = True,
            parse_internal = True,
        )
    
    Run with: bazel run //:generate_swagger
    """,
)

