extends Node

@onready var compute = get_node("../LifeCompute") 

func _on_randomise_button_pressed():
	compute.randomise_data()


func _on_step_button_pressed():
	compute.execute()


func _on_run_button_toggled(button_pressed):
	compute.running = button_pressed
	get_node("VBoxContainer/step_button").disabled = button_pressed


func _on_h_slider_value_changed(value):
	get_node("../Camera2D").zoom = value * Vector2.ONE

