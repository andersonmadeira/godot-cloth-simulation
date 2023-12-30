extends Area3D
class_name Pit

func _on_body_entered(body: Node3D) -> void:
	if body is Ball:
		body.explode()
