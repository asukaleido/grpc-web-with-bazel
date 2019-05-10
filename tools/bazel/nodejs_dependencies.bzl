load("@build_bazel_rules_nodejs//:defs.bzl", "yarn_install")

def nodejs_dependencies():

    yarn_install(
        name = "nodejs_protobufjs_deps",
        package_json = "//tools/bazel/protobufjs:package.json",
        yarn_lock = "//tools/bazel/protobufjs:yarn.lock",
    )

    yarn_install(
        name = "nodejs_rollup_deps",
        package_json = "//tools/bazel/rollup:package.json",
        yarn_lock = "//tools/bazel/rollup:yarn.lock",
    )

    yarn_install(
        name = "nodejs_webpack_deps",
        package_json = "//tools/bazel/webpack:package.json",
        yarn_lock = "//tools/bazel/webpack:yarn.lock",
    )
