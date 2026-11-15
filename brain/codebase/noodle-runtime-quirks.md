# Noodle runtime quirks (v0.1.5)

Found while running the loop with Claude Code 2.1.x. Each item says whether it was read in Noodle's source or only observed.

- **Claude worker sessions never exit.** Noodle starts Claude with `--input-format stream-json` and keeps stdin open for steering (source: `dispatcher/process_dispatcher.go` `configureStdin`). It treats a Claude stage as done only when the process exits (source: `dispatcher/process_session.go` `waitForExit`). The monitor's completed flag comes only from a `complete` event, which the Claude parser never emits (source: `monitor/claims.go`). Claude Code 2.1.x keeps waiting for input while stdin is open (observed), so every worker stage hangs.
- **Runtime watcher overflow.** The main loop reads one fsnotify event per cycle, and each cycle's `orders.json` write triggers the next cycle (source: `loop/loop.go` `Run`). Events pile up until `fsnotify: queue or buffer overflow` kills `noodle start`, about 25 minutes in (observed).
- **Re-listed orders cancel running stages.** If the scheduler writes an order that is already active, Noodle replaces the running stage when any field differs, such as routing defaults the scheduler leaves empty or a reworded prompt. That cancels the running session (source: `loop/orders.go` `mergeAmendedActiveOrder`, `loop/loop_cycle_pipeline.go` `cancelSupersededActiveCooks`).
- **The scheduler holds a slot.** The schedule session is meant to stay alive and receive stage events, and it counts toward `max_concurrency` (source: `loop/cook_spawn.go` `atMaxConcurrency`). Keep `max_concurrency = 2`.
- **Usage-limit stalls (observed).** A session that hits the Claude usage limit stops at once. Check its `meta.json` for "hit your" before you debug anything else.
- **Backlog sync runs every second (source: `loop/util.go` `pollInterval`).** `adapters/backlog-sync` caches its result for 30 seconds so the loop stays inside GitHub's rate limit, and `adapters/backlog-done` clears the cache when an order finishes.

## Local build

The loop runs a v0.1.5 build with three changes:

1. `dispatcher/process_dispatcher.go`: close Claude's stdin after the first prompt, for worker stages only. Claude then finishes its turn and any background work, and exits. The schedule session keeps stdin open. Workers lose live steering and `noodle stop`; killing them still works. Upstream `main` fixes this differently: it marks a Claude session complete on its `result` event and kills it, which would also kill a session waiting on background work.
2. `loop/orders.go`: while a stage is running, an amendment keeps that stage as it is and takes only the incoming stages after the one with the same task key.
3. `loop/loop.go`: read watcher events in a goroutine and coalesce them into one pending cycle, as upstream `main` does. Unlike `main`, the loop's own `orders.json` writes no longer trigger a cycle, because `flushState` rewrites it at the end of every cycle. The one-second ticker still runs one, and `Cycle` reloads `orders.json` from disk.

To rebuild: clone `poteto/noodle` at `v0.1.5`, apply the patch at the end of this note, create `ui/dist/client/index.html` (the web UI is not built, and the server is off in `.noodle.toml`), then run `go build`. Expected test results with `go test ./loop/... ./dispatcher/... ./monitor/...`: `TestConsumeOrdersNextDuplicateActiveIDAmendsCurrentStage` and the `orders-next-promotion-with-inflight-cook` fixture fail, because they test the amendment behaviour change 2 removes. `internal/schemadoc` already fails on plain v0.1.5.

Session transcripts live in `.noodle/sessions/<session>/canonical.ndjson`. Run `tail -f` on one to watch an agent.

## Patch

```diff
diff --git a/dispatcher/process_dispatcher.go b/dispatcher/process_dispatcher.go
index 8d135cc..e886a66 100644
--- a/dispatcher/process_dispatcher.go
+++ b/dispatcher/process_dispatcher.go
@@ -177,7 +177,7 @@ func (d *ProcessDispatcher) startSessionProcess(
 		return nil, nil, fmt.Errorf("start process: %w", err)
 	}
 
-	controller, err := d.configureStdin(ctx, process, req.Provider, composedPrompt)
+	controller, err := d.configureStdin(ctx, process, req, composedPrompt)
 	if err != nil {
 		_ = process.ForceKill()
 		return nil, nil, err
@@ -201,9 +201,9 @@ func (d *ProcessDispatcher) startSessionProcess(
 // as the first stream-json user message. For other providers (codex), writes
 // the prompt to stdin and closes it.
 func (d *ProcessDispatcher) configureStdin(
-	ctx context.Context, process *ProcessHandle, provider, composedPrompt string,
+	ctx context.Context, process *ProcessHandle, req DispatchRequest, composedPrompt string,
 ) (*claudeController, error) {
-	if stringx.Normalize(provider) == "codex" {
+	if stringx.Normalize(req.Provider) == "codex" {
 		go func() {
 			_, _ = io.WriteString(process.Stdin(), composedPrompt)
 			_ = process.Stdin().Close()
@@ -214,6 +214,14 @@ func (d *ProcessDispatcher) configureStdin(
 	if err := controller.SendMessage(ctx, composedPrompt); err != nil {
 		return nil, fmt.Errorf("send initial prompt: %w", err)
 	}
+	// Local patch: current Claude Code keeps waiting for input while stdin is
+	// open, so a worker session never exits. Closing stdin lets Claude finish
+	// its turn and any background work, then exit. The schedule session keeps
+	// stdin open: it is meant to stay alive and receive stage events. Workers
+	// lose live steering and `noodle stop`; killing them still works.
+	if stringx.Normalize(req.TaskKey) != "schedule" && stringx.Normalize(req.Skill) != "schedule" {
+		_ = process.Stdin().Close()
+	}
 	return controller, nil
 }
 
diff --git a/loop/loop.go b/loop/loop.go
index 5e2446c..5a58726 100644
--- a/loop/loop.go
+++ b/loop/loop.go
@@ -356,6 +356,9 @@ func (l *Loop) Run(ctx context.Context) error {
 
 	ticker := time.NewTicker(l.pollInterval())
 	defer ticker.Stop()
+	cycleTrigger := make(chan struct{}, 1)
+	watchErr := make(chan error, 1)
+	go forwardRuntimeWatcher(ctx, watcher.Events, watcher.Errors, cycleTrigger, watchErr)
 
 	for {
 		select {
@@ -363,6 +366,8 @@ func (l *Loop) Run(ctx context.Context) error {
 			l.shutdownAndDrain()
 			return nil
 		case <-ticker.C:
+			enqueueRuntimeCycle(cycleTrigger)
+		case <-cycleTrigger:
 			if err := l.Cycle(ctx); err != nil {
 				return err
 			}
@@ -379,20 +384,59 @@ func (l *Loop) Run(ctx context.Context) error {
 				}
 				return nil
 			}
-		case ev := <-watcher.Events:
-			if strings.HasSuffix(ev.Name, "orders.json") || strings.HasSuffix(ev.Name, "orders-next.json") || strings.HasSuffix(ev.Name, "control.ndjson") {
-				if err := l.Cycle(ctx); err != nil {
-					return err
-				}
-			}
-		case err := <-watcher.Errors:
+		case err := <-watchErr:
 			if err != nil {
-				return fmt.Errorf("watch runtime directory: %w", err)
+				return err
 			}
 		}
 	}
 }
 
+// Local patch: read watcher events off the main loop so the kernel queue
+// never overflows, and coalesce them into at most one pending cycle. The
+// loop's own orders.json writes no longer re-trigger a cycle; the ticker
+// still runs one every poll interval.
+func forwardRuntimeWatcher(
+	ctx context.Context,
+	events <-chan fsnotify.Event,
+	errors <-chan error,
+	cycleTrigger chan<- struct{},
+	watchErr chan<- error,
+) {
+	for {
+		select {
+		case <-ctx.Done():
+			return
+		case ev, ok := <-events:
+			if !ok {
+				return
+			}
+			if strings.HasSuffix(ev.Name, "orders-next.json") || strings.HasSuffix(ev.Name, "control.ndjson") {
+				enqueueRuntimeCycle(cycleTrigger)
+			}
+		case err, ok := <-errors:
+			if !ok {
+				return
+			}
+			if err == nil {
+				continue
+			}
+			select {
+			case watchErr <- fmt.Errorf("watch runtime directory: %w", err):
+			default:
+			}
+			return
+		}
+	}
+}
+
+func enqueueRuntimeCycle(ch chan<- struct{}) {
+	select {
+	case ch <- struct{}{}:
+	default:
+	}
+}
+
 func (l *Loop) Cycle(ctx context.Context) error {
 	if l.registryStale.Load() {
 		l.rebuildRegistry()
diff --git a/loop/orders.go b/loop/orders.go
index 18c89a8..25685e6 100644
--- a/loop/orders.go
+++ b/loop/orders.go
@@ -383,6 +383,31 @@ func mergeAmendedActiveOrder(existing Order, incoming Order) (Order, bool) {
 	if currentIndex < 0 || currentStage == nil {
 		return existing, false
 	}
+	// Local patch: a scheduler that re-lists an order whose stage is running
+	// would replace that stage whenever any field differs (empty routing
+	// defaults, reworded prompt), which cancels the running session. Keep the
+	// running stage as it is, and take only the incoming stages after the one
+	// with the same task key.
+	if currentStage.Status == StageStatusActive || currentStage.Status == StageStatusMerging {
+		matchIndex := -1
+		for i := range incoming.Stages {
+			if incoming.Stages[i].TaskKey == currentStage.TaskKey {
+				matchIndex = i
+				break
+			}
+		}
+		if matchIndex < 0 {
+			return existing, false
+		}
+		merged := incoming
+		merged.Stages = append(slices.Clone(existing.Stages[:currentIndex]), *currentStage)
+		merged.Stages = append(merged.Stages, incoming.Stages[matchIndex+1:]...)
+		merged.Status = existing.Status
+		if reflect.DeepEqual(existing, merged) {
+			return existing, false
+		}
+		return merged, true
+	}
 
 	merged := incoming
 	completedPrefix := slices.Clone(existing.Stages[:currentIndex])
```
