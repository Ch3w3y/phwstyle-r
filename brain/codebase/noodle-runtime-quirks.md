# Noodle runtime quirks (v0.1.5)

Found while running the loop with Claude Code 2.1.x. Each item says whether it was read in Noodle's source or only observed.

- **Claude sessions never exit (source).** Noodle starts Claude with `--input-format stream-json` and keeps stdin open for steering. It treats a Claude stage as done only when the process exits (`dispatcher/process_session.go` `waitForExit`). The monitor's completed flag comes only from a `complete` event, which the Claude parser never emits (`monitor/claims.go`). Current Claude Code keeps waiting while stdin is open, so every stage hangs. Fixed in the local build below.
- **Runtime watcher overflow (source).** The main loop reads one fsnotify event per cycle, and each cycle rewrites `orders.json`, which triggers the next cycle. Events pile up until `fsnotify: queue or buffer overflow` kills `noodle start`, about 25 minutes in (observed). Fixed in the local build below.
- **The scheduler holds a slot (source).** A live schedule session counts toward `max_concurrency` (`loop/cook_spawn.go` `atMaxConcurrency`). Keep `max_concurrency = 2`.
- **Usage-limit stalls (observed).** A session that hits the Claude usage limit stops at once. Check its `meta.json` for "hit your" before you debug anything else.
- **Backlog sync runs every second (source).** `adapters/backlog-sync` caches its result for 30 seconds so the loop stays inside GitHub's rate limit.

## Local build

Upstream `main` fixes the first two bugs but has no release yet. The loop runs a v0.1.5 build with three changes:

1. `dispatcher/process_dispatcher.go`: close Claude's stdin after the first prompt. Claude then finishes its turn and any background work, and exits.
2. `loop/loop.go`: read watcher events in a goroutine and coalesce them into one pending cycle, as upstream `main` does.
3. `loop/loop.go`: the loop's own `orders.json` writes no longer trigger a cycle. The one-second ticker still runs one.

To rebuild: clone `poteto/noodle` at `v0.1.5`, apply the patch at the end of this note, create `ui/dist/client/index.html` (the web UI is not built, and the server is off in `.noodle.toml`), then run `go build`. Run `go test ./loop/... ./dispatcher/... ./monitor/...` to check it.

Session transcripts live in `.noodle/sessions/<session>/canonical.ndjson`. Run `tail -f` on one to watch an agent.

## Patch

```diff
diff --git a/dispatcher/process_dispatcher.go b/dispatcher/process_dispatcher.go
index 8d135cc..5ea129f 100644
--- a/dispatcher/process_dispatcher.go
+++ b/dispatcher/process_dispatcher.go
@@ -214,6 +214,10 @@ func (d *ProcessDispatcher) configureStdin(
 	if err := controller.SendMessage(ctx, composedPrompt); err != nil {
 		return nil, fmt.Errorf("send initial prompt: %w", err)
 	}
+	// Local patch: current Claude Code keeps waiting for input while stdin is
+	// open, so the session never exits. Closing stdin lets Claude finish its
+	// turn and any background work, then exit. Live steering is lost.
+	_ = process.Stdin().Close()
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
```
