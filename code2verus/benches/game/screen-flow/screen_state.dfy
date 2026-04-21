// Benchmark: Screen state machine
// Domain: Nu engine screen transitions
// Purpose: Verify that screen transitions are total and deterministic
//          given a valid command, and that no invalid transition is possible.

module ScreenFlow {

  datatype ScreenState =
    | Title
    | MainMenu
    | Settings
    | Loading(destination: ScreenState)
    | InWorld(worldId: int)
    | Paused(previous: ScreenState)
    | GameOver

  datatype Command =
    | PressStart
    | OpenSettings
    | CloseSettings
    | StartGame(worldId: int)
    | LoadComplete
    | Pause
    | Resume
    | Quit
    | RestartFromGameOver

  predicate ValidState(s: ScreenState)
  {
    match s
    case Loading(dest) => ValidState(dest) && dest != Loading(dest)
    case Paused(prev)  => ValidState(prev) && prev != Paused(prev)
    case InWorld(id)   => id >= 0
    case _             => true
  }

  function Transition(s: ScreenState, cmd: Command): ScreenState
    requires ValidState(s)
  {
    match (s, cmd)
    case (Title,     PressStart)           => MainMenu
    case (MainMenu,  StartGame(id))        => Loading(InWorld(id))
    case (MainMenu,  OpenSettings)         => Settings
    case (Settings,  CloseSettings)        => MainMenu
    case (Loading(dest), LoadComplete)     => dest
    case (InWorld(_), Pause)               => Paused(s)
    case (Paused(prev), Resume)            => prev
    case (Paused(_), Quit)                 => MainMenu
    case (GameOver, RestartFromGameOver)   => MainMenu
    case _                                 => s
  }

  lemma TransitionPreservesValidity(s: ScreenState, cmd: Command)
    requires ValidState(s)
    ensures  ValidState(Transition(s, cmd))
  {}

  lemma LoadingDestinationReachable(dest: ScreenState, cmd: Command)
    requires ValidState(dest)
    requires cmd == LoadComplete
    ensures  Transition(Loading(dest), cmd) == dest
  {}

}
