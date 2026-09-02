class_name Battle
extends TestBattle

# External encounters queue a BattleSetup before changing to battle.tscn.
# The inherited controller consumes it and falls back to the test setup only
# when launched directly.
