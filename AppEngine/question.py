import presentation as p
from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

class Question(Model):
	point = ReferenceProperty(p.Point)
	text = TextProperty()
	question_kind = StringProperty()
	
	FREEFORM = 'freeform'
	DID_NOT_UNDERSTAND = 'didNotUnderstand'
	GO_IN_DEPTH = 'goInDepth'
	
	def to_data(self):
		data = {"kind": self.question_kind}
		if self.question_kind == Question.FREEFORM:
			data['text'] = self.text
			
		return data
		
	
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
		
		data = q.to_data()
		data["pointURL"] = p.PointJSONView.url(q.point)
		json.dump(data, self.response.out)
		
	
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
		
		kind = self.request.get("kind", default_value = None)
		if kind not in (Question.FREEFORM, Question.DID_NOT_UNDERSTAND, Question.GO_IN_DEPTH):
			self.error(400)
			self.response.headers['X-IL-Error-Reason'] = 'unknown question kind'
			return
		
		text = None
		if kind == Question.FREEFORM:
			text = self.request.get("text", default_value = None)
			if text is None:
				self.error(400)
				self.response.headers['X-IL-Error-Reason'] = 'freeform questions need text'
				return
			
		q = Question(point = x, parent = x, text = text, question_kind = kind)
		q.put()
		
		self.redirect(QuestionView.url(q))
		
def append_handlers(list):
	list.append((QuestionView.url_scheme, QuestionView))
	list.append((PoseAQuestion.url_scheme, PoseAQuestion))

