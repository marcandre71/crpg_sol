extends Node
## Signaux globaux : les domaines communiquent par ici, pas par appels directs.

signal skill_check_resolved(actor_id: String, skill_id: String, result: Dictionary)
signal condition_changed(actor_id: String, condition_id: String, active: bool)
signal life_support_tick(seconds_left: int)
signal combat_started
signal combat_ended
