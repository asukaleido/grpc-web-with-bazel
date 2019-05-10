def _copy_files_impl(ctx):
    files = []
    for src in ctx.files.srcs:
        file = ctx.actions.declare_file(src.basename)
        ctx.actions.expand_template(
            output = file,
            template = src,
            substitutions = {},
        )
        files.append(file)
    return DefaultInfo(files = depset(files), runfiles = ctx.runfiles(files))

ATTRS = {
    "srcs": attr.label_list(allow_files = True),
}

copy_files = rule(
    implementation = _copy_files_impl,
    attrs = ATTRS,
)
