import presentation as p
from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

import live
	
class Question(Model):
	point = ReferenceProperty(p.Point)
	text = TextProperty()
	question_kind = StringProperty()
	
	FREEFORM = 'freeform'
	DID_NOT_UNDERSTAND = 'didNotUnderstand'
	GO_IN_DEPTH = 'goInDepth'
	
	AVAILABLE_KINDS = [FREEFORM, DID_NOT_UNDERSTAND, GO_IN_DEPTH]
	
	def to_data(self):
		data = {"kind": self.question_kind}
		if self.question_kind == Question.FREEFORM:
			data['text'] = self.text
			
		data['answers'] = []
		for a in Answer.gql("WHERE question = :1 ORDER BY timestamp", self):
			data['answers'].append(a.to_data())
			
		return data

class Answer(Model):
	text = TextProperty()
	question = ReferenceProperty(Question)
	timestamp = DateTimeProperty(auto_now_add = True)
	
	def to_data(self):
		return {
			'text': self.text,
			'URL': AnswerView.url(self),
		}

class QuestionView(w.RequestHandler):
	url_scheme = '/questions/id/(.*)'
	
	@classmethod
	def url(self, question):
		if isinstance(question, Question):
			question = question.key()
			
		return "/questions/id/%s" % (str(question),)
		
	def get(self, ident):
		q = Question.get(Key(ident))
		if q is None:
			self.error(404)
			return
		
		self.response.headers['Content-Type'] = 'application/json'
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
		if kind not in Question.AVAILABLE_KINDS:
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
		
		import live
		l = live.Live.get_current()
		l.questions.append(q.key())
		self.response.headers['X-IL-Debug-LiveQuestionsContent'] = str(l.questions)
		l.put()
		
		self.redirect(QuestionView.url(q))
		
class AnswerView(w.RequestHandler):
	url_scheme = '/answers/(.*)'
	
	@classmethod
	def url(self, answer):
		return '/answers/%s' % str(answer.key())
		
	def get(self, answer_id):
		a = Answer.get(Key(answer_id))
		if a is None:
			self.error(404)
			return
		
		self.response.headers['Content-Type'] = 'application/json'
		data = a.to_data()
		data['questionURL'] = QuestionView.url(a.question)
		json.dump(data, self.response.out)
		
	def delete(self, answer_id):
		if not live.continue_after_checking_https_and_secret(self):
			return
		
		a = Answer.get(Key(answer_id))
		if a is None:
			self.error(404)
			return
		
		a.delete()
		
	def post(self, answer_id):
		if not live.continue_after_checking_https_and_secret(self):
			return

		if self.request.get('delete') == 'true':
			self.delete(answer_id)
		
class AnswerQuestion(w.RequestHandler):
	url_scheme = '/questions/id/([^/]+)/new_answer'
	
	@classmethod
	def url(self, question):
		return '/questions/id/%s/new_answer' % str(question.key())
		
	def post(self, question_id):
		if not live.continue_after_checking_https_and_secret(self):
			return
			
		q = Question.get(Key(question_id))
		if q is None:
			self.error(404)
			return
		
		if q.question_kind != Question.FREEFORM:
			self.error(400)
			self.response.headers['X-IL-Error-Reason'] = 'Only freeform questions can have answers'
			return
		
		a = Answer(question = q)
		text = self.request.get('text')
		if text == '':
			self.error(400)
			self.response.headers['X-IL-Error-Reason'] = 'You must specify text for an answer'
			return
			
		a.text = text
		
		a.put()
		self.redirect(AnswerView.url(a))
		
def append_handlers(list):
	list.append((AnswerQuestion.url_scheme, AnswerQuestion))
	list.append((AnswerView.url_scheme, AnswerView))
	list.append((QuestionView.url_scheme, QuestionView))
	list.append((PoseAQuestion.url_scheme, PoseAQuestion))
