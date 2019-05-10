def _run_pbjs(
    actions,
    executable,
    output_name,
    proto_files,
    suffix = ".js",
    target = "json-module",
    wrap = "default",
    amd_name = "",
):
    js_file = actions.declare_file(output_name + suffix)

    args = actions.args()
    args.add_all(["--target", target])
    args.add_all(["--wrap", wrap])
    args.add("--strict-long");

    if wrap == "default":
        js_tmpl_file = actions.declare_file(output_name + suffix + ".tmpl")
        args.add_all(["--out", js_file.path + ".tmpl"])
        args.add_all(proto_files)

        actions.run(
            executable = executable._pbjs,
            inputs = proto_files,
            outputs = [js_tmpl_file],
            arguments = [args],
        )

        actions.expand_template(
            template = js_tmpl_file,
            output = js_file,
            substitutions = {
                "define([": "define('%s/%s', [" % (amd_name, output_name),
            },
        )
    else:
        args.add_all(["--out", js_file.path])
        args.add_all(proto_files)

        actions.run(
            executable = executable._pbjs,
            inputs = proto_files,
            outputs = [js_file],
            arguments = [args],
        )

    return js_file

def _run_pbts(actions, executable, output_name, proto_files, amd_name):
    ts_file = actions.declare_file(output_name + ".d.ts")

    js_file = _run_pbjs(
        actions,
        executable,
        output_name,
        proto_files,
        suffix = ".static.js",
        target = "static-module",
        amd_name = amd_name,
    )

    args = actions.args()
    args.add_all(["--out", ts_file.path])
    args.add(js_file.path)

    actions.run(
        executable = executable._pbts,
        inputs = [js_file],
        outputs = [ts_file],
        arguments = [args],
    )
    return ts_file

def _ts_proto_library(ctx):
    sources = depset()
    for dep in ctx.attr.deps:
        if not hasattr(dep, "proto"):
            fail("ts_proto_library dep %s must be a proto_library rule" % dep.label)

        sources = depset(transitive = [sources, dep.proto.transitive_sources])

    output_name = ctx.attr.output_name or ctx.label.name

    js_es5 = _run_pbjs(
        ctx.actions,
        ctx.executable,
        output_name,
        sources,
        amd_name = "/".join([p for p in [
            ctx.workspace_name,
            ctx.label.package,
        ] if p]),
    )
    js_es6 = ctx.actions.declare_file(output_name + ".closure.js")
    js_es6_tmpl = _run_pbjs(
        ctx.actions,
        ctx.executable,
        output_name,
        sources,
        suffix = ".closure.js.tmpl",
        wrap = "es6",
    )
    ctx.actions.expand_template(
        template = js_es6_tmpl,
        output = js_es6,
        substitutions = {
            "import * as $protobuf": "import $protobuf",
            "});": "}).nested;",
        },
    )
    dts = _run_pbts(
        ctx.actions,
        ctx.executable,
        output_name,
        sources,
        amd_name = "/".join([p for p in [
            ctx.workspace_name,
            ctx.label.package,
        ] if p]),
    )

    return struct(
        files = depset([dts]),
        typescript = struct(
            declarations = depset([dts]),
            es5_sources = depset([js_es5]),
            es6_sources = depset([js_es6]),
            transitive_declarations = depset([dts]),
            transitive_es5_sources = depset(),
            transitive_es6_sources = depset([js_es6]),
            type_blacklisted_declarations = depset(),
        ),
    )

ts_proto_library = rule(
    implementation = _ts_proto_library,
    attrs = {
        "output_name": attr.string(),
        "deps": attr.label_list(),
        "_pbjs": attr.label(
            default = Label("//tools/bazel/protobufjs:pbjs"),
            executable = True,
            cfg = "host",
        ),
        "_pbts": attr.label(
            default = Label("//tools/bazel/protobufjs:pbts"),
            executable = True,
            cfg = "host",
        ),
    },
)
