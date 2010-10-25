import presentation as p
from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

class Question(Model):
	point = ReferenceProperty(p.Point)
	text = TextProperty()
	
class QuestionView(w.RequestHandler):
	url_scheme = '/questions/(.*)'
	
	@classmethod
	def url(self, question):
		return "/questions/%s" % (str(question.key()),)
		
	def get(self, ident):
		q = Question.get(Key(ident))
		if q is None:
			self.error(404)
			return
		
		json.dump({"text": q.text, "pointURL": p.PointJSONView.url(q.point)}, self.response.out)
		
	
class PoseAQuestion(w.RequestHandler):
	url_scheme = '/presentations/at/(.*)/slides/(.*)/points/(.*)/new_question'
	
	@classmethod
	def url(self, point):
		return "/presentations/at/%s/slides/%s/points/%s/new_question" % (str(point.slide.presentation.key().id()), str(point.slide.sorting_order), str(point.sorting_order))
		
	def post(self, pres, slide_index, point_index):
		x = p.Presentation.get_by_url_id(pres)
		if x is not None:
			x = x.slide_at_index(slide_index)
		if x is not None:
			x = x.point_at_index(point_index)
			
		if x is None:
			self.error(404)
			return
			
		text = self.request.get("text", default_value = None)
		if text is None:
			self.error(400)
			return
			
		q = Question(point = x, parent = x, text = text)
		q.put()
		
		self.redirect(QuestionView.url(q))
		
def append_handlers(list):
	list.append((QuestionView.url_scheme, QuestionView))
	list.append((PoseAQuestion.url_scheme, PoseAQuestion))

