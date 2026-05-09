TLC  = $(HOME)/tla2tools.jar
CM   = $(HOME)/CommunityModules-deps.jar
JAVA = java -XX:+UseParallelGC -cp $(TLC):$(CM) tlc2.TLC
TLC_FLAGS = -config TraceValidation.cfg -deadlock -workers auto

build:
	go build -o shutdown_demo .

trace-bug: build
	./shutdown_demo > trace.ndjson & sleep 0.3; kill -TERM $$!; wait $$! 2>/dev/null || true

trace-correct: build
	./shutdown_demo --correct > trace.ndjson & sleep 0.3; kill -TERM $$!; wait $$! 2>/dev/null || true

validate:
	$(JAVA) $(TLC_FLAGS) TraceValidation.tla

demo-bug: trace-bug validate

demo-correct: trace-correct validate

check-spec:
	$(JAVA) -config GracefulShutdown.cfg GracefulShutdown.tla

.PHONY: build trace-bug trace-correct validate demo-bug demo-correct check-spec
