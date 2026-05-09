----------------------- MODULE TraceValidation -----------------------
\* Запуск: tlc TraceValidation.tla
\* Требует: TLA+ Community Modules (ndJsonDeserialize)
\* Путь к трейсу задаётся через -config или переменную TraceFile ниже

EXTENDS GracefulShutdown, TLC, Json, Integers

\* Путь к файлу трейса — замени на абсолютный путь если нужно
CONSTANTS TraceFile

\* Читаем все строки ndjson как последовательность состояний
TraceStates == ndJsonDeserialize(TraceFile)

\* Переопределяем Init: стартуем с первого состояния трейса
TraceInit ==
    /\ workerState    = TraceStates[1].workerState
    /\ mainState      = TraceStates[1].mainState
    /\ signalReceived = TraceStates[1].signalReceived

\* Переопределяем Next: просто шагаем по трейсу
TraceNext ==
    \E i \in 1 .. (Len(TraceStates) - 1) :
        /\ workerState    = TraceStates[i].workerState
        /\ mainState      = TraceStates[i].mainState
        /\ signalReceived = TraceStates[i].signalReceived
        /\ workerState'    = TraceStates[i + 1].workerState
        /\ mainState'      = TraceStates[i + 1].mainState
        /\ signalReceived' = TraceStates[i + 1].signalReceived

TraceSpec == TraceInit /\ [][TraceNext]_vars

\* Проверяем SafeShutdown на всех состояниях трейса
THEOREM TraceSpec => []SafeShutdown

=============================================================================
