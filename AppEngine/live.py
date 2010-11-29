from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

import presentation as p

class Live(Model):
	slide = ReferenceProperty(p.Slide)
	questions = ListProperty(Key)
	finished = BooleanProperty()
	# moods = backreference set of Mood.
	
	@classmethod
	def get_current(self):
		me = self.all().get()
		if me is None:
			me = Live()
			me.finished = True
			me.put()
			
		return me
		

class Mood(Model):
	import live
	live = ReferenceProperty(live.Live, collection_name = "moods")
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
		data = {"kind": self.mood_kind, "slideURL": p.SlideJSONView.url(self.slide) }
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

		
class MoodView(w.RequestHandler):
	url_scheme = '/moods/id/(.*)'
	
	@classmethod
	def url(self, m):
		if isinstance(m, Mood):
			m = m.key()
			
		return "/moods/id/%s" % (str(m),)
		
	def get(self, ident):
		q = Mood.get(Key(ident))
		if q is None:
			self.error(404)
			return
		
		data = q.to_data()
		json.dump(data, self.response.out)
		
class LiveControl(w.RequestHandler):
	url_scheme = '/live'
	
	# TODO: ACL
	def post(self):
		me = Live.get_current()
		slide_no = self.request.get('slide', default_value = None)
		pres_id = self.request.get('presentation', default_value = None)
		if pres_id is not None and slide_no is not None:
			if me.finished:
				me.finished = False
				me.slide = None
				me.questions = []
				for m in me.moods:
					m.delete()
			
			s = p.Slide.gql("WHERE presentation = :1 AND sorting_order = :2", p.Presentation.get_by_id(long(pres_id)), long(slide_no)).get()
			
			if s is None:
				self.error(400)
				return
				
			me.slide = s
		elif self.request.get('end') == 'true':
			me.finished = True
			me.slide = None
		
		me.put()
		
	
	def get(self):
		import question as qa
		
		me = Live.get_current()
		
		s = me.slide
		response = { "slide": None, "questionsPostedDuringLive": [], "finished": me.finished,
			"moods": [MoodView.url(x) for x in me.moods], "moodsForCurrentSlide": {} }
		
		if s is not None:
			response["slide"] = s.to_data()
			response["slide"]["URL"] = p.SlideJSONView.url(s)
			questions = []
			
			for pt in s.point_set:
				for q in pt.question_set:
					questions.append(qa.QuestionView.url(q))
			
			response["slide"]["questionURLs"] = questions
			response["moodsForCurrentSlide"] = s.summary_of_moods()
			
		for q in me.questions:
			response["questionsPostedDuringLive"].append(qa.QuestionView.url(q))
		
		self.response.headers['Content-Type'] = 'application/json'
		json.dump(response, self.response.out)
	
class ReportAMood(w.RequestHandler):
	url_scheme = '/live/presentations/at/(.*)/slides/(.*)/new_mood'
	
	@classmethod
	def url(self, slide):
		return "/live/presentations/at/%s/slides/%s/new_mood" % (str(point.slide.presentation.key().id()), str(point.slide.sorting_order))
		
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
		
		live = Live.get_current()
		m = Mood(slide = x, live = live, parent = live, mood_kind = kind)
		m.put()
		
		self.redirect(MoodView.url(m))
	
def append_handlers(list):
	list.append((MoodView.url_scheme, MoodView))
	list.append((ReportAMood.url_scheme, ReportAMood))
	list.append((LiveControl.url_scheme, LiveControl))
