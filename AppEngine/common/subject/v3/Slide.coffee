
class Subject.Slide extends Subject.ModelObject
	properties: () ->
		[
			'sortingOrder'
			'points'
			'imageURL'
		]
	
	updateUsingContent: (content) ->
		@setSortingOrder content.sortingOrder
		@setImageURL content.imageURL
		@setPoints (points = [])
		
		i = 0
		for point in content.points
			i++
			((i, point) ->
				@context.getOrLoad { URL: point.URL, knownContent: point }, Subject.Point, (x) ->
					points[i] = x
			)(i, point)
		