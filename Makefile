all: vendor dashboards_out

vendor:
	jb install

.PHONY: dashboards_out
dashboards_out: mixin.libsonnet config.libsonnet $(wildcard dashboards/*)
	@mkdir -p dashboards_out
	jsonnet -J vendor -m dashboards_out lib/dashboards.jsonnet

clean:
	rm -rf dashboards_out
