load(
    "@build_bazel_rules_nodejs//internal/rollup:rollup_bundle.bzl",
    "ROLLUP_ATTRS",
    "write_rollup_config",
    "run_rollup",
    "run_terser",
    "run_sourcemapexplorer",
)
load(
    "@build_bazel_rules_nodejs//internal/common:collect_es6_sources.bzl",
    collect_es2015_sources = "collect_es6_sources"
)

ROLLUP_OUTPUTS = {
    "build_es2015": "%{name}.js",
    "build_es2015_min": "%{name}.min.js",
    "build_es2015_min_debug": "%{name}.min.debug.js",
    "build_es2015_dev": "%{name}.dev.js",
    "build_es2015_dev_min": "%{name}.dev.min.js",
    "build_es2015_dev_min_debug": "%{name}.dev.min.debug.js",
    "explore_html": "%{name}.min.explore.html"
}

def _create_replace_plugin(node_env):
    npm = "nodejs_rollup_deps/node_modules/rollup-plugin-replace"
    config = "{'process.env.NODE_ENV': JSON.stringify('%s')}" % node_env
    plugin = "require('%s')(%s)" % (npm, config)
    return plugin

def _rollup_bundle(ctx):
    rollup_config = write_rollup_config(
      ctx,
      plugins = [_create_replace_plugin(node_env = "production")],
    )
    es2015_sourcemap = run_rollup(
        ctx,
        collect_es2015_sources(ctx),
        rollup_config,
        ctx.outputs.build_es2015
    )
    es2015_min_sourcemap = run_terser(
        ctx,
        ctx.outputs.build_es2015,
        ctx.outputs.build_es2015_min,
        config_name = "%s.min" % ctx.label.name,
        comments = False,
        in_source_map = es2015_sourcemap,
    )
    es2015_min_debug_sourcemap = run_terser(
        ctx,
        ctx.outputs.build_es2015,
        ctx.outputs.build_es2015_min_debug,
        config_name = "%s.min.debug" % ctx.label.name,
        comments = False,
        debug = True,
        in_source_map = es2015_sourcemap,
    )

    rollup_config_dev = write_rollup_config(
      ctx,
      plugins = [_create_replace_plugin(node_env = "development")],
      filename = "_%s.dev.rollup.conf.js"
    )
    es2015_dev_sourcemap = run_rollup(
        ctx,
        collect_es2015_sources(ctx),
        rollup_config_dev,
        ctx.outputs.build_es2015_dev
    )
    es2015_dev_min_sourcemap = run_terser(
        ctx,
        ctx.outputs.build_es2015_dev,
        ctx.outputs.build_es2015_dev_min,
        config_name = "%s.dev.min" % ctx.label.name,
        comments = False,
        in_source_map = es2015_dev_sourcemap,
    )
    es2015_dev_min_debug_sourcemap = run_terser(
        ctx,
        ctx.outputs.build_es2015_dev,
        ctx.outputs.build_es2015_dev_min_debug,
        config_name = "%s.dev.min.debug" % ctx.label.name,
        # comments = False,
        debug = True,
        # in_source_map = es2015_dev_sourcemap,
    )

    run_sourcemapexplorer(
        ctx,
        ctx.outputs.build_es2015_min,
        es2015_min_sourcemap,
        ctx.outputs.explore_html
    )

    files = [ctx.outputs.build_es2015_min, es2015_min_sourcemap]
    output_group = OutputGroupInfo(
        es2015 = depset([
            ctx.outputs.build_es2015,
            es2015_sourcemap,
        ]),
        es2015_min = depset([
            ctx.outputs.build_es2015_min,
            es2015_min_sourcemap,
        ]),
        es2015_min_debug = depset([
            ctx.outputs.build_es2015_min_debug,
            es2015_min_debug_sourcemap,
        ]),
        es2015_dev = depset([
            ctx.outputs.build_es2015_dev,
            es2015_dev_sourcemap,
        ]),
        es2015_dev_min = depset([
            ctx.outputs.build_es2015_dev_min,
            es2015_dev_min_sourcemap,
        ]),
        es2015_dev_min_debug = depset([
            ctx.outputs.build_es2015_dev_min_debug,
            es2015_dev_min_debug_sourcemap,
        ]),
    )

    return [
        DefaultInfo(files = depset(files), runfiles = ctx.runfiles(files)),
        output_group,
    ]

rollup_bundle = rule(
    implementation = _rollup_bundle,
    attrs = dict(ROLLUP_ATTRS, **{
        "_rollup": attr.label(
            executable = True,
            cfg = "host",
            default = Label("//tools/bazel/rollup:rollup"),
        ),
    }),
    outputs = ROLLUP_OUTPUTS,
)
