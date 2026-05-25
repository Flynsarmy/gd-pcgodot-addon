@tool
class_name NoiseNodeSettings
extends NodeSettings

@export_group("Noise")

@export var out_name : String = "density"
@export var in_scale : float = 1.0
@export var noise_bias : float = 0.0
@export var noise_amplitude : float = 1.0

enum eOutputType {
	Float = 0,
	Vector3 = 1,
}

enum eMode {
	Override = 0,
	Add = 1,
}

@export var output_type : eOutputType = eOutputType.Float
@export var mode : eMode = eMode.Override

func _init():
	super._init()
	resource_name = "Noise Settings"
