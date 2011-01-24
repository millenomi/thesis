this.Subject ?= {}

class Subject.Context
	constructor: () ->
		@loadedObjects = {}
	
	get: (url) ->
		@loadedObjects[url]
		
	put: (url, object) ->
		@loadedObjects[url] = object
		
	complete: (url, modelClass, done) ->
		jQuery.ajax {
			dataType: 'json',
			url: url,
			success: (contentOfX) =>
				modelClass.updateGraphWithContent(this, url, contentOfX)
				done @get(url)
		}
	
	getOrLoad: (url, produce, done) ->
		x = @get(url)
		if x
			done x
			return
		else
			@complete(url, produce, done)
		
class Subject.ModelObject
	constructor: (options = {}) ->
		@URL = options.URL
		throw "Each model object must have a URL" unless @URL
		@context = options.context or new Subject.Context()
		
		for propertyName in @properties()
			((property) =>
				variableName = '_' + property
				this[property] = () ->
					return this[variableName]
				setter = 'set' + property.substr(0,1).toUpperCase() + property.substr(1)
				this[setter] = (x) ->
					this[variableName] = x
					this
			)(propertyName)
	
	properties: () ->
		throw "The 'properties()' method of a ModelObject is abstract and must be overridden."
		
	
Subject.ModelObject.updateGraphWithContent = (context, url, content) ->
	x = new this({URL: url, context: context})
	x.updateUsingContent content
	context.put url, x
