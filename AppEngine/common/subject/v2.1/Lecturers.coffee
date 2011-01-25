
this.ILabs ?= {}
ILabs.Subject ?= {}
ILabs.Subject.Lecturers ?= {}

I = ILabs.Subject
L = ILabs.Subject.Lecturers

L.log = () ->
	console.log.apply(console, arguments) if window.console and console.log

class I.View
	jQ: () ->
		return @element if @element
		throw "Return a jQuery object with a single element from this method!"
	
	contents: () ->
		@_contents
		
	setContents: (newViews) ->
		@_contents = newViews
		if newViews.length == 0
			@jQ().empty()
			return
		
		i = 0
		contentElements = jQuery()
		for view in newViews
			contentElements = contentElements.add view.jQ() if view and view.jQ
			
		@jQ().append contentElements

class L.CollectionView extends I.View
	constructor: (@itemViewClass, element) ->
		@element = element or jQuery('<div></div>')
		@items = []
	
	empty: () ->
		@items = []
		@setContents([])
	
	setItemAtIndex: (index, object) ->
		if @itemViewClass
			item = new (@itemViewClass)(object)
		else
			item = object
		
		@items[index] = item
		@setContents(@items)
		
	append: (object) ->
		@setItemAtIndex(@items.length, object)
		
class L.LecturersScreen extends I.View
	constructor: (@live) ->
		@slideViews = []
		@slideViewsByURL = {}
		
		@element = jQuery('<div class="ILabs-Subject-Lecturers-LecturersScreen"></div>')
		@live.setDelegate this
	
	setPresentation: (object) ->
		@setContents([])
		@presentation = object
		@presentation.loadSelf () =>
			for s in object.slides()
				@slideViews = []
				@slideViewsByURL = {}
				s.loadSelf () =>
					x = new L.SlideView(s)
					@slideViews[s.sortingOrder()] = x
					@slideViewsByURL[s.URL()] = x
					
					@setContents(@slideViews)
					
					if @currentSlideURL == s.URL()
						x.slideIntoView()
	
	liveDidAskNewQuestions: (live, qs) ->
		L.log(this, 'will load new questions', qs)
		for q in qs
			q.loadSelf () =>
				p = q.point()
				p.loadSelf () =>
					s = @slideViewsByURL[p.slide().URL()]
					s.insertQuestion(q) if s
	
	liveDidMoveToSlide: (live, slide) ->
		slide.loadSelf () =>
			if not @presentation or @presentation.URL() != slide.presentation().URL()
				@setPresentation slide.presentation()
		
		@currentSlideURL = slide.URL()
		v = @slideViewsByURL[slide.URL()]
		v.scrollIntoView() if v

class L.FreeformQuestionView extends I.View
	constructor: (@question) ->
		@element = jQuery('<div class="ILabs-Subject-Lecturers-FreeformQuestionsView"></div>')
		@question.point().loadSelf () =>
			@element.append(
				jQuery('<p class="question"></p>').text @question.text()
			).append(
				jQuery('<p class="point"></p>').text '‘' + @question.point().text() + '’'
			)

class L.SlideView extends I.View
	constructor: (@slide) ->
		$el = jQuery('
			<div class="ILabs-Subject-Lecturers-SlideView">
			</div>')
		@element = $el
		
		if @slide.imageURL()
			$el.append(
				jQuery('<img class="slide-image">')
					.attr('src', @slide.imageURL())
			)
		
		@moodView = new L.MoodView(@slide)
		$el.append @moodView.jQ()
		
		@freeformQuestionsElement = jQuery('<div class="freeformQuestions"></div>')
		$el.append(@freeformQuestionsElement)
		@freeformQuestions = new L.CollectionView(L.FreeformQuestionView, @freeformQuestionsElement)
		@freeformQuestionURLs = {}
		
		@shortFormQuestionsElement = jQuery('<div class="shortFormQuestions"></div>')
		$el.append(@shortFormQuestionsElement)

		I.bind I.ModelItem.Loaded, (e, object) =>
			@insertQuestion(object) if object.modelItemKind() == 'ILabs.Subject.Question'
		
		@reloadAllPointsAndQuestions()
	
	reloadAllPointsAndQuestions: () ->
		L.log('Reloading all points and questions for', this)
		@slide.loadSelf () =>
			L.log('Reloaded slide', @slide, 'of', this)
			for p in @slide.points()
				p.loadSelf () =>
					L.log('Reloaded point', p, 'of slide', @slide, 'of', this)
					for q in p.questions()
						q.loadSelf () =>
							L.log('Reloaded question', q, 'of point', p, 'of slide', @slide, 'of', this)
							@insertQuestion(q)
	
	insertQuestion: (q)	->
		if q.kind() == I.Question.FreeformKind and not @freeformQuestionURLs[q.URL()]
			@freeformQuestionURLs[q.URL()] = true
			@freeformQuestions.append(q)
	
	slideIntoView: () ->
		# readapted from http://radio.javaranch.com/pascarello/2005/01/09/1105293729000.html
		x = 0; y = 0
		
		el = @element
		while el
			x += el.offsetLeft
			y += el.offsetTop
			el = el.offsetParent
		
		window.scrollTo(x, y)

class L.MoodView extends I.View
	constructor: (@slide) ->
		@element = jQuery('<div></div>')
		I.bind I.ModelItem.Loaded, (e, object) =>
			@insertMood(m) if object.modelItemKind() == 'ILabs.Subject.Mood'
			
		@live = I.Live.fromContext(@slide.context())
		if @live.moods()
			for m in @live.moods()
				m.loadSelf()
			
	insertMood: (m) ->
		L.log("would have inserted mood", m, 'TODO')