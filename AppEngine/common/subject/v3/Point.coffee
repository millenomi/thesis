
class Subject.Point extends Subject.ModelObject
	properties: () -> [
		'text'
		'indentation'		
	]

	updateUsingContent: (content) ->
		@setText content.text
		@setIndentation content.indentation
	