class_name LifeSupportClock
extends RefCounted
## Compte à rebours du support vital du sas de Thulé-7.
## Le temps avance par le coût des actions hors combat (timeCost) et de 5 s par tour de combat.

signal ticked(seconds_left: int)
signal warning(seconds_left: int)
signal expired

## Paliers d'alerte, en secondes restantes.
const WARNINGS: Array[int] = [300, 120, 60]

var seconds_left: int
var stopped := false


func _init(seconds: int) -> void:
	seconds_left = seconds


## Fait avancer l'horloge ; sans effet une fois le support vital réparé ou l'horloge à zéro.
func advance(seconds: int) -> void:
	if stopped or seconds_left <= 0 or seconds <= 0:
		return
	var before := seconds_left
	seconds_left = maxi(0, seconds_left - seconds)
	ticked.emit(seconds_left)
	for w in WARNINGS:
		if before > w and seconds_left <= w and seconds_left > 0:
			warning.emit(seconds_left)
			break
	if seconds_left == 0:
		expired.emit()


## Support vital réparé : l'horloge s'arrête.
func stop() -> void:
	stopped = true


@warning_ignore("integer_division")
static func format(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]
