------------------------- MODULE GracefulShutdown -------------------------
EXTENDS TLC, Sequences, FiniteSets

CONSTANTS Workers  \* {"w1", "w2"}

WorkerStates == {"init", "running", "stopped"}
MainStates   == {"running", "exited"}

VARIABLES
    workerState,    \* [w \in Workers -> WorkerStates]
    mainState,      \* MainStates
    signalReceived  \* BOOLEAN

vars == <<workerState, mainState, signalReceived>>

TypeOK ==
    /\ workerState    \in [Workers -> WorkerStates]
    /\ mainState      \in MainStates
    /\ signalReceived \in BOOLEAN

\* Инвариант: main не может выйти пока есть воркеры не в stopped
SafeShutdown ==
    mainState = "exited" =>
        \A w \in Workers : workerState[w] = "stopped"

Init ==
    /\ workerState    = [w \in Workers |-> "init"]
    /\ mainState      = "running"
    /\ signalReceived = FALSE

\* Воркер переходит init -> running
WorkerStart(w) ==
    /\ workerState[w] = "init"
    /\ workerState' = [workerState EXCEPT ![w] = "running"]
    /\ UNCHANGED <<mainState, signalReceived>>

\* Получен сигнал
ReceiveSignal ==
    /\ ~signalReceived
    /\ signalReceived' = TRUE
    /\ UNCHANGED <<workerState, mainState>>

\* Воркер останавливается (только после сигнала)
WorkerStop(w) ==
    /\ signalReceived
    /\ workerState[w] = "running"
    /\ workerState' = [workerState EXCEPT ![w] = "stopped"]
    /\ UNCHANGED <<mainState, signalReceived>>

\* Main завершается (только когда все воркеры stopped)
MainExit ==
    /\ signalReceived
    /\ \A w \in Workers : workerState[w] = "stopped"
    /\ mainState' = "exited"
    /\ UNCHANGED <<workerState, signalReceived>>

Next ==
    \/ \E w \in Workers : WorkerStart(w)
    \/ ReceiveSignal
    \/ \E w \in Workers : WorkerStop(w)
    \/ MainExit

Spec == Init /\ [][Next]_vars

=============================================================================
