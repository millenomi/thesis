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
	
	AVAILABLE_KINDS = [FREEFORM, DID_NOT_UNDERSTAND, GO_IN_DEPTH]
	
	def to_data(self):
		data = {"kind": self.question_kind}
		if self.question_kind == Question.FREEFORM:
			data['text'] = self.text
			
		return data
		
class Mood(Model):
	slide = ReferenceProperty(p.Slide, collection_name = "moods")
	mood_kind = StringProperty()
	
	# Mood kind constants
	WHY_AM_I_HERE = "whyAmIHere"
	CONFUSED = "confused"
	BORED = "bored"
	INTERESTED = "interested"
	ENGAGED = "engaged"
	THOUGHTFUL = "thoughtful"
	
	AVAILABLE_KINDS = [WHY_AM_I_HERE, CONFUSED, BORED, INTERESTED, ENGAGED, THOUGHTFUL]
	
	def to_data(self):
		data = {"kind": self.mood_kind}
		return data

def summary_of_moods(slide):
	x = {}
	for m in slide.moods:
		if not m.mood_kind in x:
			x[m.mood_kind] = 1
		else:
			x[m.mood_kind] += 1
	
	return x
	
p.Slide.summary_of_moods = summary_of_moods
	
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
		
		data = q.to_data()
		data["pointURL"] = p.PointJSONView.url(q.point)
		json.dump(data, self.response.out)

class ReportAMood(w.RequestHandler):
	url_scheme = '/presentations/at/(.*)/slides/(.*)/new_mood'
	
	@classmethod
	def url(self, slide):
		return "/presentations/at/%s/slides/%s/new_mood" % (str(point.slide.presentation.key().id()), str(point.slide.sorting_order))
		
	def post(self, pres, slide_index):
		x = p.Presentation.get_by_url_id(pres)
		if x is not None:
			x = x.slide_at_index(slide_index)
			
		if x is None:
			self.error(404)
			return
		
		kind = self.request.get("kind", default_value = None)
		if kind not in Mood.AVAILABLE_KINDS:
			self.error(400)
			self.response.headers['X-IL-Error-Reason'] = 'unknown mood kind'
			return
		
		def tx():
			m = Mood(slide = x, parent = x, mood_kind = kind)
			m.put()
			x.revision += 1
			x.put()
		run_in_transaction(tx)
		
		self.redirect(p.SlideJSONView.url(x))
	
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
		l.put()
		
		self.redirect(QuestionView.url(q))
		
def append_handlers(list):
	list.append((QuestionView.url_scheme, QuestionView))
	list.append((PoseAQuestion.url_scheme, PoseAQuestion))
	list.append((ReportAMood.url_scheme, ReportAMood))
