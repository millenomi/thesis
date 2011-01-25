
import all_presentations as ap, answers as a

def _route_for(cls):
	return (cls.url_scheme, cls)

def append_handlers(list):
	list.append(_route_for(ap.AllPresentationsPage))
	list.append(_route_for(ap.PresentationPage))
	list.append(_route_for(ap.PresentationAttentionMeasuresPage))

	list.append(_route_for(a.QuestionAnswerView))
	