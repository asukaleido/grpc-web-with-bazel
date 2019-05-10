load(
    "@build_bazel_rules_nodejs//internal/common:node_module_info.bzl",
    "NodeModuleSources",
    "collect_node_modules_aspect",
)
load("@build_bazel_rules_nodejs//internal/common:module_mappings.bzl", "get_module_mappings")
load("@build_bazel_rules_nodejs//internal/common:collect_es6_sources.bzl", "collect_es6_sources")

def _webpack_module_mappings_aspect_impl(target, ctx):
    mappings = get_module_mappings(target.label, ctx.rule.attr)
    return struct(webpack_module_mappings = mappings)

webpack_module_mappings_aspect = aspect(
    _webpack_module_mappings_aspect_impl,
    attr_aspects = ["deps"],
)

def _filter_js_inputs(inputs):
    return [
        f
        for f in inputs
        if f.path.endswith(".js") or f.path.endswith(".json") or f.path.endswith(".map")
    ]

def create_config(ctx, output, filename = "webpack.config.js"):
    config = ctx.actions.declare_file(filename)

    root_path = "/".join(output.path.split("/")[:-1] + [ctx.label.name + ".es6"])

    node_modules_roots = []
    for d in ctx.attr.deps:
        if NodeModuleSources in d:
            node_modules_roots.append(
                "/".join(["external", d[NodeModuleSources].workspace, "node_modules"]),
            )
    webpack_node_module_sources = ctx.attr._webpack_node_modules[NodeModuleSources]
    webpack_node_modules_root = "/".join(
        ["external", webpack_node_module_sources.workspace, "node_modules"],
    )

    ctx.actions.expand_template(
        output = config,
        template = ctx.file._webpack_config_tmpl,
        substitutions = {
            "TMPL_ROOT_PATH": root_path,
            "TMPL_NODE_MODULES_ROOTS": str(node_modules_roots),
            "TMPL_WEBPACK_NODE_MODULES_ROOT": webpack_node_modules_root,
        },
    )

    return config

def _run_webpack(ctx, entry, config, sources, output):
    root_path = "/".join(output.path.split("/")[:-1] + [ctx.label.name + ".es6"])

    args = ctx.actions.args()
    args.add_all(["--config", config.path])
    args.add_all(["--output-path=%s" % "./%s" % output.path])
    args.add_joined(
        ["%s=%s" % (e[0], "./%s/%s" % (root_path, e[1])) for e in entry.items()],
        join_with = " ",
    )

    inputs = [config]

    for d in ctx.attr.deps:
        if NodeModuleSources in d:
            inputs += _filter_js_inputs(d[NodeModuleSources].sources.to_list())
    webpack_node_module_sources = ctx.attr._webpack_node_modules[NodeModuleSources]
    inputs += _filter_js_inputs(webpack_node_module_sources.sources.to_list())

    ctx.actions.run(
        executable = ctx.executable._webpack,
        inputs = depset(inputs, transitive = [sources]),
        outputs = [output],
        arguments = [args],
    )

def _webpack_bundle_impl(ctx):
    output_dir = ctx.actions.declare_directory(ctx.attr.output_dir)

    config = create_config(ctx, output_dir)

    _run_webpack(
        ctx,
        ctx.attr.entry,
        config,
        collect_es6_sources(ctx),
        output_dir,
    )

    files = [config, output_dir]

    return DefaultInfo(files = depset(files), runfiles = ctx.runfiles(files))

WEBPACK_DEPS_ASPECTS = [webpack_module_mappings_aspect, collect_node_modules_aspect]

WEBPACK_ATTRS = {
    "entry": attr.string_dict(
        mandatory = True,
    ),
    "output_dir": attr.string(
        default = "bundle",
    ),
    "deps": attr.label_list(
        aspects = WEBPACK_DEPS_ASPECTS,
        mandatory = True,
    ),
    "_webpack": attr.label(
        default = Label("//tools/bazel/webpack:webpack"),
        executable = True,
        cfg = "host",
    ),
    "_webpack_node_modules": attr.label(
        default = Label("@nodejs_webpack_deps//:node_modules"),
    ),
    "_webpack_config_tmpl": attr.label(
        default = Label("//tools/bazel/webpack:webpack.config.js"),
        allow_single_file = True,
    ),
}

webpack_bundle = rule(
    implementation = _webpack_bundle_impl,
    attrs = WEBPACK_ATTRS,
)
