"""Build rule for generating Swagger documentation from Go code annotations."""

def _swag_docs_impl(ctx):
    """Implementation of swag_docs rule.
    
    Generates Swagger artifacts (swagger.json, swagger.yaml, docs.go) from Go source files with swag annotations.
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

    # Search directories.  If the caller does not provide any explicit directories we
    # fall back to the general_info file's directory so that swag has a sensible root.
    if ctx.attr.search_dirs:
        args.add_all("--dir", ctx.attr.search_dirs)
    else:
        default_dir = ctx.file.general_info.path.rpartition("/")[0]
        if not default_dir:
            default_dir = "."
        args.add("--dir", default_dir)

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

    if ctx.attr.extra_args:
        args.add_all(ctx.attr.extra_args)

    # Declare the requested output files.
    supported_output_files = {
        "json": "swagger.json",
        "yaml": "swagger.yaml",
        "go": "docs.go",
    }
    requested_types = {}
    unknown_types = []
    for t in ctx.attr.output_types:
        normalized = t.lower()
        if normalized in supported_output_files:
            requested_types[normalized] = True
        else:
            unknown_types.append(t)

    if unknown_types:
        fail("swag_docs: unsupported output_types: %s" % ", ".join(unknown_types))
    outputs = {}
    if requested_types.get("json"):
        outputs["json"] = ctx.actions.declare_file(ctx.label.name + "/swagger.json")
    if requested_types.get("yaml"):
        outputs["yaml"] = ctx.actions.declare_file(ctx.label.name + "/swagger.yaml")
    if requested_types.get("go"):
        outputs["go"] = ctx.actions.declare_file(ctx.label.name + "/docs.go")

    if not outputs:
        fail("swag_docs requires at least one output type")

    # Collect all source files as inputs
    srcs = []
    for src in ctx.attr.srcs:
        srcs.extend(src[DefaultInfo].files.to_list())

    inputs = depset(srcs + [ctx.file.general_info])

    # Run swag init
    ctx.actions.run(
        executable = swag,
        arguments = [args],
        inputs = inputs,
        outputs = [output_dir],
        mnemonic = "SwagInit",
        progress_message = "Generating Swagger documentation for %s" % ctx.label.name,
    )

    # Copy files from output_dir to declared outputs
    copy_commands = [
        "set -euo pipefail",
    ]
    for kind, file in outputs.items():
        copy_commands.append("mkdir -p $(dirname {dest})".format(dest = file.path))
        copy_commands.append(
            "if [ -f {dir}/{filename} ]; then cp {dir}/{filename} {dest}; else echo 'Expected {filename} in {dir}' >&2; exit 1; fi".format(
                dir = output_dir.path,
                filename = supported_output_files[kind],
                dest = file.path,
            ),
        )

    ctx.actions.run_shell(
        inputs = [output_dir],
        outputs = list(outputs.values()),
        command = "\n".join(copy_commands),
    )

    output_groups = {k: depset([v]) for (k, v) in outputs.items()}
    output_groups["all"] = depset(list(outputs.values()))

    return [
        DefaultInfo(files = depset(list(outputs.values()))),
        OutputGroupInfo(**output_groups),
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
            doc = "List of directories to search for annotations (relative to workspace root)",
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
            doc = "Output types to materialize (subset of go, json, yaml)",
        ),
        "instance_name": attr.string(
            doc = "Instance name for docs.go (default: swagger)",
        ),
        "extra_args": attr.string_list(
            doc = "Additional raw flags to pass to the swag CLI.",
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
            output_types = ["json", "yaml"],
            extra_args = ["--generatedTime=false"],
        )

    This generates the requested Swagger artifacts from annotated Go source files under bazel-bin.
    """,
)

def _swag_init_script_impl(ctx):
    """Implementation of swag_init_script rule.
    
    Creates a script that runs swag init and writes files to the source tree.
    This is useful for regenerating documentation during development.
    """
    swag = ctx.executable._swag
    
    # Create the command fragments used by the shell wrapper
    parse_flags = []
    if ctx.attr.parse_dependency:
        parse_flags.append("--parseDependency")
    if ctx.attr.parse_internal:
        parse_flags.append("--parseInternal")
    if ctx.attr.parse_vendor:
        parse_flags.append("--parseVendor")

    parse_block = ""
    if parse_flags:
        parse_block = "  " + " \\\n  ".join(parse_flags) + " \\\n"

    extra_block = ""
    if ctx.attr.extra_args:
        extra_block = "  " + " \\\n  ".join(ctx.attr.extra_args) + " \\\n"

    search_dirs = ",".join(ctx.attr.search_dirs) if ctx.attr.search_dirs else "./"
    output_types = ",".join(ctx.attr.output_types)

    # Create the script
    script_content = """#!/bin/bash
set -e

# Locate the swag binary from runfiles
if [[ -z "${{RUNFILES_DIR}}" ]]; then
  # Find runfiles directory
  if [[ -d "$0.runfiles" ]]; then
    export RUNFILES_DIR="$0.runfiles"
  elif [[ -d "${{0}}.runfiles" ]]; then
    export RUNFILES_DIR="${{0}}.runfiles"
  fi
fi

SWAG="${{RUNFILES_DIR}}/_main/{swag}"
if [[ ! -x "${{SWAG}}" ]]; then
  echo "Error: Cannot find swag executable at ${{SWAG}}"
  exit 1
fi

# Change to workspace directory
cd "$BUILD_WORKSPACE_DIRECTORY"

# Run swag init
"${{SWAG}}" init \\
  --generalInfo {general_info} \\
  --output {output_dir} \\
  --dir {search_dirs} \\
{parse_block}{extra_block}  --outputTypes {output_types}

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
        search_dirs = search_dirs,
        parse_block = parse_block,
        extra_block = extra_block,
        output_types = output_types,
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
        "extra_args": attr.string_list(
            doc = "Additional flags forwarded directly to the swag CLI.",
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
            extra_args = ["--generatedTime=false"],
        )
    
    Run with: bazel run //:generate_swagger
    """,
)

