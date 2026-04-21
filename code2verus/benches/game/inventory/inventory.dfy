// Benchmark: Inventory system
// Domain: Game item management
// Purpose: Verify that inventory operations preserve core invariants:
//          capacity bounds, item counts, and absence of negative quantities.

module Inventory {

  type ItemId = int

  datatype Inventory = Inventory(
    items:    map<ItemId, int>,
    capacity: int
  )

  predicate ValidInventory(inv: Inventory)
  {
    inv.capacity >= 0 &&
    (forall id :: id in inv.items ==> inv.items[id] > 0) &&
    TotalItems(inv.items) <= inv.capacity
  }

  function TotalItems(items: map<ItemId, int>): int
  {
    if |items| == 0 then 0
    else
      var id :| id in items;
      items[id] + TotalItems(items - {id})
  }

  function AddItem(inv: Inventory, id: ItemId, qty: int): Inventory
    requires ValidInventory(inv)
    requires qty > 0
    requires TotalItems(inv.items) + qty <= inv.capacity
  {
    if id in inv.items
    then inv.(items := inv.items[id := inv.items[id] + qty])
    else inv.(items := inv.items[id := qty])
  }

  function RemoveItem(inv: Inventory, id: ItemId, qty: int): Inventory
    requires ValidInventory(inv)
    requires qty > 0
    requires id in inv.items
    requires inv.items[id] >= qty
  {
    if inv.items[id] == qty
    then inv.(items := inv.items - {id})
    else inv.(items := inv.items[id := inv.items[id] - qty])
  }

  lemma AddPreservesValidity(inv: Inventory, id: ItemId, qty: int)
    requires ValidInventory(inv)
    requires qty > 0
    requires TotalItems(inv.items) + qty <= inv.capacity
    ensures  ValidInventory(AddItem(inv, id, qty))
  {
    assume {:axiom} false; // proof stub — fill in
  }

  lemma RemovePreservesValidity(inv: Inventory, id: ItemId, qty: int)
    requires ValidInventory(inv)
    requires qty > 0
    requires id in inv.items
    requires inv.items[id] >= qty
    ensures  ValidInventory(RemoveItem(inv, id, qty))
  {
    assume {:axiom} false; // proof stub — fill in
  }

}
