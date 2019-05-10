load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "1db950bbd27fb2581866e307c0130983471d4c3cd49c46063a2503ca7b6770a4",
    url = "https://github.com/bazelbuild/rules_nodejs/releases/download/0.29.0/rules_nodejs-0.29.0.tar.gz",
)
http_archive(
    name = "com_google_protobuf",
    sha256 = "f1748989842b46fa208b2a6e4e2785133cfcc3e4d43c17fecb023733f0f5443f",
    url = "https://github.com/google/protobuf/archive/v3.7.1.tar.gz",
    strip_prefix = "protobuf-3.7.1",
)
http_archive(
    name = "io_bazel_rules_closure",
    sha256 = "075c898cb535437e821c00e6d104060213fc02464876f9f8e088d798caa1e19c",
    url = "https://github.com/bazelbuild/rules_closure/archive/87b9b7cefe57f9dea04c5e8518862af17cdfba2e.tar.gz",
    strip_prefix = "rules_closure-87b9b7cefe57f9dea04c5e8518862af17cdfba2e",
)
http_archive(
    name = "com_grpc_grpcweb",
    sha256 = "06ffa689758498fa7a0d1dfa426cb7136fea9387bb2a458d3421fca0754f6d5a",
    url = "https://github.com/grpc/grpc-web/archive/1.0.4.tar.gz",
    strip_prefix = "grpc-web-1.0.4",
)

load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories", "yarn_install")

node_repositories(
    node_version = "12.2.0",
    yarn_version = "1.16.0",
    node_repositories = {
      "12.2.0-darwin_amd64": ("node-v12.2.0-darwin-x64.tar.gz", "node-v12.2.0-darwin-x64", "c72ae8a2b989138c6e6e9b393812502df8c28546a016cf24e7a82dd27e3838af"),
      "12.2.0-linux_amd64": ("node-v12.2.0-linux-x64.tar.xz", "node-v12.2.0-linux-x64", "ba6afb9967ea6934d0807e0f79da80e063601d91c98da12bda3cf4675720bfb2"),
      "12.2.0-windows_amd64": ("node-v12.2.0-win-x64.zip", "node-v12.2.0-win-x64", "c1e7fb3c1c15d8f2ab5c1db9c9662097f9c682164b3f7397955ccce946442c97"),
    },
    yarn_repositories = {
      "1.16.0": ("yarn-v1.16.0.tar.gz", "yarn-v1.16.0", "df202627d9a70cf09ef2fb11cb298cb619db1b958590959d6f6e571b50656029"),
    },
    node_urls = ["https://nodejs.org/dist/v{version}/{filename}"],
    yarn_urls = ["https://github.com/yarnpkg/yarn/releases/download/v{version}/{filename}"],
    package_json = ["//:package.json"]
)

yarn_install(
    name = "npm",
    package_json = "//:package.json",
    yarn_lock = "//:yarn.lock",
)

load("@io_bazel_rules_closure//closure:defs.bzl", "closure_repositories")

closure_repositories()

load("@npm//:install_bazel_dependencies.bzl", "install_bazel_dependencies")

install_bazel_dependencies()

load("@npm_bazel_typescript//:index.bzl", "ts_setup_workspace")

ts_setup_workspace()

load("//tools/bazel:defs.bzl", "nodejs_dependencies")

nodejs_dependencies()
