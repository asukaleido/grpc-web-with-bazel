NPM_MOD_DIR := $(CURDIR)/node_modules
NPM_BIN_DIR := $(NPM_MOD_DIR)/.bin
DIST_DIR := $(CURDIR)/dist
RELEASE_DIR := $(DIST_DIR)/release
BAZEL_OUT_DIR := $(CURDIR)/bazel-out
BAZEL_BIN_DIR := $(BAZEL_OUT_DIR)/host/bin
PROTOC := ${BAZEL_BIN_DIR}/external/com_google_protobuf/protoc
PROTOC_GEN_GRPC_WEB := ${BAZEL_BIN_DIR}/external/com_grpc_grpcweb/javascript/net/grpc/web/protoc-gen-grpc-web

.DEFAULT_GOAL := help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-50s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ## Delete the output directories for all build configurations performed by Bazel.
	$(NPM_BIN_DIR)/bazel clean

.PHONY: clean_expunge
clean_expunge: ## Completely remove the entire working tree created by Bazel.
	$(NPM_BIN_DIR)/bazel clean --expunge

.PHONY: build
build: RELEASE_CHANNEL ?= development
build: ## Compile JS with Bazel.
	@rm -Rf $(RELEASE_DIR)
ifeq ($(RELEASE_CHANNEL),production)
	$(MAKE) clean
endif
	$(NPM_BIN_DIR)/bazel build //:release
	@mkdir $(DIST_DIR)/release
	@cp -Rf $(DIST_DIR)/bin/* $(DIST_DIR)/release/
	@chmod -R u+w dist/release
	# $(NPM_BIN_DIR)/prettier --write "$(DIST_DIR)/release/**/*.ts" "$(DIST_DIR)/release/**/*.js"

.PHONY: source_map_explorer
source_map_explorer: ## Analyze and debug JavaScript code bloat through source maps.
	$(NPM_BIN_DIR)/bazel build //packages/app/client:bundle.min.explore.html

.PHONY: deps_graph
create_deps_graph: ## Output the dependency graph to a svg file
	$(NPM_BIN_DIR)/bazel query 'allpaths(//:release, //packages/...)' --output graph | dot -Tsvg > deps_graph.svg

.PHONY: deps_graph_from_madge
create_deps_graph_from_madge: ## Output the dependency graph to a svg file
	$(NPM_BIN_DIR)/madge --include-npm --extensions js,ts,tsx --dot packages | dot -Tsvg > deps_graph.svg

.PHONY: run
run: build
run: ## Start service with docker.
	docker-compose up --build

.PHONY: format_proto_using_google_protobuf
format_proto_using_google_protobuf: ## Format ts proto file with prettier
	$(NPM_BIN_DIR)/prettier --write "$(CURDIR)/proto/**/*.ts" "$(CURDIR)/proto/**/*.js"

.PHONY: remove_proto_using_google_protobuf
remove_proto_using_google_protobuf: ## Remove ts proto file from workspace
	@find $(CURDIR)/proto -type f -name "*.ts" -or -name "*.js" | xargs rm -Rf

.PHONY: generate_proto_using_google_protobuf_with_bazel
generate_proto_using_google_protobuf_with_bazel: build remove_proto_using_google_protobuf
generate_proto_using_google_protobuf_with_bazel: ## Copy ts proto file to workspace
	@$(CURDIR)/tools/copy_proto_using_google_protobuf_from_release.sh
	$(MAKE) format_proto_using_google_protobuf

.PHONY: generate_proto_using_google_protobuf
generate_proto_using_google_protobuf: remove_proto_using_google_protobuf
generate_proto_using_google_protobuf: ## Generate ts proto file
	$(PROTOC) \
	-I=$(CURDIR) \
	$(shell find $(CURDIR)/proto -type f -name "*.proto") \
	--plugin=protoc-gen-grpc-web=$(PROTOC_GEN_GRPC_WEB) \
	--js_out=import_style=commonjs:$(CURDIR) \
	--grpc-web_out=import_style=typescript,mode=grpcwebtext:$(CURDIR)
	$(MAKE) format_proto_using_google_protobuf

.PHONY: remove_proto_using_protobufjs
remove_proto_using_protobufjs: ## Remove ts proto file from workspace
	@rm -Rf $(CURDIR)/packages/proto/proto.*

.PHONY: format_proto_using_protobufjs
format_proto_using_protobufjs: ## Format ts proto file with prettier
	$(NPM_BIN_DIR)/prettier --write "$(CURDIR)/packages/proto/proto.*"

.PHONY: generate_proto_using_protobufjs_with_bazel
generate_proto_using_protobufjs_with_bazel: build remove_proto_using_protobufjs
generate_proto_using_protobufjs_with_bazel: ## Copy ts proto file to workspace
	@cp -Rf $(DIST_DIR)/release/packages/proto/proto* $(CURDIR)/packages/proto/
	$(MAKE) format_proto_using_protobufjs

.PHONY: generate_proto_using_protobufjs
generate_proto_using_protobufjs: remove_proto_using_protobufjs
generate_proto_using_protobufjs: ## Generate ts proto file
	$(NPM_BIN_DIR)/pbjs \
	--path $(CURDIR) \
	--target json-module \
	--wrap commonjs \
	--out $(CURDIR)/packages/proto/proto.js \
	$(shell find $(CURDIR)/proto -type f -name "*.proto")
	$(NPM_BIN_DIR)/pbjs \
	--path $(CURDIR) \
	--target static-module \
	--wrap default \
	$(shell find $(CURDIR)/proto -type f -name "*.proto") \
	| \
	$(NPM_BIN_DIR)/pbts \
	--out $(CURDIR)/packages/proto/proto.d.ts \
	-
	$(MAKE) format_proto_using_protobufjs
