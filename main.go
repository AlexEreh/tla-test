package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

type State struct {
	WorkerState    map[string]string `json:"workerState"`
	MainState      string            `json:"mainState"`
	SignalReceived bool              `json:"signalReceived"`
}

var (
	mu             sync.Mutex
	workerState    = map[string]string{}
	mainState      = "running"
	signalReceived = false
)

func logState() {
	mu.Lock()
	ws := make(map[string]string, len(workerState))
	for k, v := range workerState {
		ws[k] = v
	}
	s := State{
		WorkerState:    ws,
		MainState:      mainState,
		SignalReceived: signalReceived,
	}
	mu.Unlock()

	b, _ := json.Marshal(s)
	fmt.Println(string(b))
}

func worker(id string, wg *sync.WaitGroup, stop <-chan struct{}) {
	defer wg.Done()

	mu.Lock()
	workerState[id] = "running"
	mu.Unlock()
	logState()

	select {
	case <-stop:
	case <-time.After(10 * time.Second):
	}

	// симулируем cleanup при остановке
	time.Sleep(200 * time.Millisecond)

	mu.Lock()
	workerState[id] = "stopped"
	mu.Unlock()
	logState()
}

func main() {
	// ПЕРЕКЛЮЧАТЕЛЬ: true = корректный shutdown, false = баг (main выходит раньше воркеров)
	correctBehavior := len(os.Args) > 1 && os.Args[1] == "--correct"

	workerIDs := []string{"w1", "w2"}
	stopCh := make(chan struct{})
	var wg sync.WaitGroup

	for _, id := range workerIDs {
		workerState[id] = "init"
	}
	logState()

	for _, id := range workerIDs {
		wg.Add(1)
		go worker(id, &wg, stopCh)
	}

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh

	mu.Lock()
	signalReceived = true
	mu.Unlock()
	logState()

	close(stopCh)

	if correctBehavior {
		wg.Wait()
	} else {
		// БАГ: не ждём воркеров
	}

	mu.Lock()
	mainState = "exited"
	mu.Unlock()
	logState()
}
