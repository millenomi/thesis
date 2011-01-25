this.Subject ?= {}

class Subject.Presentation extends Subject.ModelObject
	properties: () ->
		[
			'title',
			'slides'
		]
	
	updateUsingContent: (content) ->
		@setTitle content.title
		@setSlides []

		for slideInfo in content.slides
			@context.getOrLoad slideInfo.URL, Subject.Slide, (slide) =>
				slides = @slides()
				slides[slide.sortingOrder()] = slide

