Subject ?=
	loadAllScripts: (scripts, whenDone) ->
		loadNextScript = () ->
			url = scripts.shift()
			script = document.createElement 'script'
			script.src = url
			script.type = 'text/javascript'
			script.onload = () ->
				if scripts.length > 0
					loadNextScript()
				else
					whenDone()
			
			document.body.appendChild(script)
		
		loadNextScript()
	
Subject.loadAllScripts [
	'/common/js/jquery-1.4.3.min.js'
	'/common/subject/v3/js/Model.js'
	'/common/subject/v3/js/Presentation.js'
	'/common/subject/v3/js/Slide.js'
	'/common/subject/v3/js/_Scratchpad.js'
], () ->
	test()
