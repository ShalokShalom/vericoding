// Benchmark: Combat resolution
// Domain: Turn-based game combat
// Purpose: Verify that damage application is bounded, health never goes
//          below zero, and kill detection is correct.

module Combat {

  datatype Entity = Entity(
    id:        int,
    maxHealth: int,
    health:    int,
    attack:    int,
    defense:   int
  )

  predicate ValidEntity(e: Entity)
  {
    e.maxHealth > 0 &&
    0 <= e.health <= e.maxHealth &&
    e.attack >= 0 &&
    e.defense >= 0
  }

  predicate IsAlive(e: Entity)
  {
    e.health > 0
  }

  function ClampedSub(a: int, b: int): int
  {
    if a - b < 0 then 0 else a - b
  }

  function ComputeDamage(attacker: Entity, defender: Entity): int
    requires ValidEntity(attacker)
    requires ValidEntity(defender)
  {
    ClampedSub(attacker.attack, defender.defense)
  }

  function ApplyDamage(target: Entity, damage: int): Entity
    requires ValidEntity(target)
    requires damage >= 0
  {
    target.(health := ClampedSub(target.health, damage))
  }

  function Attack(attacker: Entity, defender: Entity): Entity
    requires ValidEntity(attacker)
    requires ValidEntity(defender)
  {
    ApplyDamage(defender, ComputeDamage(attacker, defender))
  }

  lemma DamageDoesNotExceedHealth(target: Entity, damage: int)
    requires ValidEntity(target)
    requires damage >= 0
    ensures  ApplyDamage(target, damage).health >= 0
  {}

  lemma AttackPreservesDefenderValidity(attacker: Entity, defender: Entity)
    requires ValidEntity(attacker)
    requires ValidEntity(defender)
    ensures  ValidEntity(Attack(attacker, defender))
  {}

  lemma KillingBlow(attacker: Entity, defender: Entity)
    requires ValidEntity(attacker)
    requires ValidEntity(defender)
    requires ComputeDamage(attacker, defender) >= defender.health
    ensures  !IsAlive(Attack(attacker, defender))
  {}

}
