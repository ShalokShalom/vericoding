// Benchmark: Event routing
// Domain: Nu-style message/event dispatch
// Purpose: Verify that event routing is deterministic and that every
//          dispatched event reaches exactly the correct set of handlers.

module EventBus {

  type HandlerId = int
  type EventType = int

  datatype Event = Event(
    kind:    EventType,
    payload: seq<int>
  )

  datatype Registry = Registry(
    subscriptions: map<EventType, set<HandlerId>>
  )

  predicate ValidRegistry(r: Registry)
  {
    forall k :: k in r.subscriptions ==>
      (forall h :: h in r.subscriptions[k] ==> h >= 0)
  }

  function Subscribe(r: Registry, kind: EventType, handler: HandlerId): Registry
    requires ValidRegistry(r)
    requires handler >= 0
  {
    if kind in r.subscriptions
    then r.(subscriptions := r.subscriptions[kind := r.subscriptions[kind] + {handler}])
    else r.(subscriptions := r.subscriptions[kind := {handler}])
  }

  function Unsubscribe(r: Registry, kind: EventType, handler: HandlerId): Registry
    requires ValidRegistry(r)
  {
    if kind in r.subscriptions
    then r.(subscriptions := r.subscriptions[kind := r.subscriptions[kind] - {handler}])
    else r
  }

  function Dispatch(r: Registry, e: Event): set<HandlerId>
    requires ValidRegistry(r)
  {
    if e.kind in r.subscriptions
    then r.subscriptions[e.kind]
    else {}
  }

  lemma SubscribeRegistersHandler(r: Registry, kind: EventType, handler: HandlerId)
    requires ValidRegistry(r)
    requires handler >= 0
    ensures  handler in Dispatch(Subscribe(r, kind, handler), Event(kind, []))
  {}

  lemma UnsubscribeRemovesHandler(r: Registry, kind: EventType, handler: HandlerId)
    requires ValidRegistry(r)
    ensures  handler !in Dispatch(Unsubscribe(r, kind, handler), Event(kind, []))
  {}

  lemma SubscribePreservesValidity(r: Registry, kind: EventType, handler: HandlerId)
    requires ValidRegistry(r)
    requires handler >= 0
    ensures  ValidRegistry(Subscribe(r, kind, handler))
  {}

}
