load("//tools/bazel/protobufjs:ts_proto_library.bzl", _ts_proto_library = "ts_proto_library")
load("//tools/bazel/rollup:rollup_bundle.bzl", _rollup_bundle = "rollup_bundle")
load("//tools/bazel/webpack:webpack_bundle.bzl", _webpack_bundle = "webpack_bundle")
load("//tools/bazel:copy_files.bzl", _copy_files = "copy_files")
load("//tools/bazel:nodejs_dependencies.bzl", _nodejs_dependencies = "nodejs_dependencies")

ts_proto_library = _ts_proto_library
rollup_bundle = _rollup_bundle
webpack_bundle = _webpack_bundle
copy_files = _copy_files
nodejs_dependencies = _nodejs_dependencies
