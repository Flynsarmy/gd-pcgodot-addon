@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Output",
		"settings" : OutputNodeSettings,
		"ins" : [{ "label" : "In", "data_type" : FlowData.DataType.Float }],
		"outs" : [],
		"tooltip" : "Exposes an output parameter of the Subgraph",
	}

func getMeta() -> Dictionary:
	if settings:
		meta_node.ins = [{ "label" : "In", "data_type" : settings.data_type }]
	return meta_node

func getTitle() -> String:
	return settings.name

func refreshFromSettings():
	super.refreshFromSettings()
	initFromScript()

func onPropChanged( prop_name : String ):
	super.onPropChanged( prop_name )
	if prop_name == "data_type" or prop_name == "name":
		initFromScript()

func execute( ctx : FlowData.EvaluationContext ):
	var in_data = get_optional_input( 0 )
	if in_data:
		var target_data = FlowData.Data.new()
		for stream_name in in_data.streams:
			var stream = in_data.streams[stream_name]
			target_data.registerStream(stream_name, stream.container, stream.data_type)
			
		var main_stream_name = in_data.last_added_stream_name
		if main_stream_name == "" or not in_data.hasStream(main_stream_name):
			main_stream_name = in_data.streams.keys()[in_data.streams.size() - 1]
			
		if in_data.streams.size() > 0 and not target_data.hasStream(settings.name):
			var main_stream = in_data.streams[main_stream_name]
			target_data.registerStream(settings.name, main_stream.container, settings.data_type)
			
		set_output( 0, target_data )
