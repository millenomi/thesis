this.test = () ->
	window._context_ = new Subject.Context()
	_context_.getOrLoad '/presentations/at/1', Subject.Presentation, (p) ->
		console.log p if window.console

this.pres = () ->
	_context_.get('/presentations/at/1')
	