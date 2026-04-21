// Benchmark: Quest progression
// Domain: Game quest system
// Purpose: Verify that quest state transitions are legal and that
//          objective tracking is consistent with overall quest status.

module QuestSystem {

  datatype ObjectiveStatus = Incomplete | Complete | Failed
  datatype QuestStatus     = Active | Succeeded | QuestFailed | NotStarted

  datatype Objective = Objective(
    id:     int,
    status: ObjectiveStatus
  )

  datatype Quest = Quest(
    id:         int,
    status:     QuestStatus,
    objectives: seq<Objective>
  )

  predicate ValidQuest(q: Quest)
  {
    q.id >= 0 &&
    |q.objectives| > 0 &&
    (forall i :: 0 <= i < |q.objectives| ==> q.objectives[i].id >= 0) &&
    (q.status == Succeeded  ==> AllComplete(q.objectives)) &&
    (q.status == QuestFailed ==> AnyFailed(q.objectives))
  }

  predicate AllComplete(objectives: seq<Objective>)
  {
    forall i :: 0 <= i < |objectives| ==> objectives[i].status == Complete
  }

  predicate AnyFailed(objectives: seq<Objective>)
  {
    exists i :: 0 <= i < |objectives| && objectives[i].status == Failed
  }

  function CompleteObjective(q: Quest, idx: int): Quest
    requires ValidQuest(q)
    requires q.status == Active
    requires 0 <= idx < |q.objectives|
    requires q.objectives[idx].status == Incomplete
  {
    var updated := q.objectives[idx := q.objectives[idx].(status := Complete)];
    var newStatus := if AllComplete(updated) then Succeeded else Active;
    q.(objectives := updated, status := newStatus)
  }

  function FailObjective(q: Quest, idx: int): Quest
    requires ValidQuest(q)
    requires q.status == Active
    requires 0 <= idx < |q.objectives|
  {
    var updated := q.objectives[idx := q.objectives[idx].(status := Failed)];
    q.(objectives := updated, status := QuestFailed)
  }

  lemma CompleteObjectivePreservesValidity(q: Quest, idx: int)
    requires ValidQuest(q)
    requires q.status == Active
    requires 0 <= idx < |q.objectives|
    requires q.objectives[idx].status == Incomplete
    ensures  ValidQuest(CompleteObjective(q, idx))
  {
    assume {:axiom} false; // proof stub
  }

  lemma FailObjectivePreservesValidity(q: Quest, idx: int)
    requires ValidQuest(q)
    requires q.status == Active
    requires 0 <= idx < |q.objectives|
    ensures  ValidQuest(FailObjective(q, idx))
  {
    assume {:axiom} false; // proof stub
  }

}
