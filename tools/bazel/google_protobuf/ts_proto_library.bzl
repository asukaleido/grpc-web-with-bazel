def _rename(actions, src, out):
    actions.run_shell(
        tools = [src],
        outputs = [out],
        command = "cp -f \"$1\" \"$2\"",
        arguments = [src.path, out.path],
        mnemonic = "RenameTSProtocolFile",
        progress_message = "Renaming TS Protocol files",
    )

def _proto_path(proto):
    path = proto.path
    root = proto.root.path
    ws = proto.owner.workspace_root
    if path.startswith(root):
        path = path[len(root):]
    if path.startswith("/"):
        path = path[1:]
    if path.startswith(ws):
        path = path[len(ws):]
    if path.startswith("/"):
        path = path[1:]
    return path

def _proto_include_path(proto):
    path = proto.path[:-len(_proto_path(proto))]
    if not path:
        return "."
    if path.endswith("/"):
        path = path[:-1]
    return path

def _proto_include_paths(protos):
    return depset([_proto_include_path(proto) for proto in protos])

def _generate_grpc_web_srcs(
        actions,
        protoc,
        protoc_gen_grpc_web,
        has_service,
        import_style,
        mode,
        sources,
        transitive_sources):
    all_sources = [src for src in sources] + [src for src in transitive_sources]
    proto_include_paths = [
        "-I%s" % p
        for p in _proto_include_paths(
            [f for f in all_sources],
        )
    ]

    grpc_web_out_common_options = ",".join([
        "import_style={}".format(import_style),
        "mode={}".format(mode),
    ])

    files = []
    for src in sources:
        outputs = []
        name = "{}".format(".".join(src.path.split("/")[-1].split(".")[:-1]))
        js_file = actions.declare_file("{}_pb.js".format(name))
        files.append(js_file)
        outputs.append(js_file)
        dts_file = actions.declare_file("{}_pb.d.ts".format(name))
        files.append(dts_file)
        outputs.append(dts_file)
        if has_service:
            service_file = actions.declare_file("{}ServiceClientPb.ts".format(name))
            outputs.append(service_file)

        args = proto_include_paths + [
            "--plugin=protoc-gen-grpc-web={}".format(protoc_gen_grpc_web.path),
            "--js_out={options}:{path}".format(
                options = "import_style=commonjs,binary",
                path = js_file.path[:js_file.path.rfind(js_file.short_path)],
            ),
            "--grpc-web_out={options}:{path}".format(
                options = grpc_web_out_common_options,
                path = js_file.path[:js_file.path.rfind(js_file.short_path)],
            ),
            src.path,
        ]

        actions.run(
            tools = [protoc_gen_grpc_web],
            inputs = all_sources,
            outputs = outputs,
            executable = protoc,
            arguments = args,
            progress_message = "Generating TS Protobuf %s" % src.short_path,
        )

        if has_service:
            renamed_service_file = actions.declare_file("{}_client_pb.ts".format(name))
            _rename(actions, service_file, renamed_service_file)
            files.append(renamed_service_file)

    return files

def _ts_proto_library_impl(ctx):
    if len(ctx.attr.deps) > 1:
        fail(
            "".join([
                "'deps' attribute must contain exactly one label ",
                "(we didn't name it 'dep' for consistency). ",
                "We may revisit this restriction later.",
            ]),
            "deps",
        )

    dep = ctx.attr.deps[0]

    srcs = _generate_grpc_web_srcs(
        actions = ctx.actions,
        protoc = ctx.executable._protoc,
        protoc_gen_grpc_web = ctx.executable._protoc_gen_grpc_web,
        has_service = ctx.attr.has_service,
        import_style = ctx.attr.import_style,
        mode = ctx.attr.mode,
        sources = dep[ProtoInfo].direct_sources,
        transitive_sources = dep[ProtoInfo].transitive_imports,
    )

    files = depset(direct = srcs)
    runfiles = ctx.runfiles(files = srcs)
    return struct(
        runfiles = ctx.runfiles(files = srcs),
    )

ts_proto_library = rule(
    implementation = _ts_proto_library_impl,
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            providers = [ProtoInfo],
        ),
        "has_service": attr.bool(
            default = False,
        ),
        "import_style": attr.string(
            default = "typescript",
            values = ["closure", "commonjs", "commonjs+dts", "typescript"],
        ),
        "mode": attr.string(
            default = "grpcweb",
            values = ["binary", "base64", "grpcweb", "grpcwebtext", "jspb", "frameworks"],
        ),
        "_protoc": attr.label(
            default = Label("@com_google_protobuf//:protoc"),
            executable = True,
            cfg = "host",
        ),
        "_protoc_gen_grpc_web": attr.label(
            default = Label("@com_grpc_grpcweb//javascript/net/grpc/web:protoc-gen-grpc-web"),
            executable = True,
            cfg = "host",
        ),
    },
)
