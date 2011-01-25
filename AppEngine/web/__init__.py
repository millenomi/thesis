import all_presentations as ap, answers as a

def append_handlers(list):
	route = lambda y: (y.url_scheme, y)
	
	list.append(route(ap.AllPresentationsPage))
	list.append(route(ap.PresentationPage))
	list.append(route(ap.PresentationAttentionMeasuresPage))
	
	list.append(route(a.QuestionAnswerView))
	