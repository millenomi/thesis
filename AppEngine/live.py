from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

import presentation as p
import question as qa

class Live(Model):
	slide = ReferenceProperty(p.Slide)

	@classmethod
	def get_current(self):
		me = self.all().get()
		if me is None:
			me = Live()
			# Whoever edits us will .put().
			
		return me

class LiveControl(w.RequestHandler):
	url_scheme = '/live'
	
	# TODO: ACL
	def post(self):
		me = Live.get_current()
		slide_no = self.request.get('slide', default_value = None)
		pres_id = self.request.get('presentation', default_value = None)
		if pres_id is not None and slide_no is not None:
			s = p.Slide.gql("WHERE presentation = :1 AND sorting_order = :2", p.Presentation.get_by_id(long(pres_id)), long(slide_no)).get()
			
			if s is None:
				self.error(400)
				return
				
			me.slide = s
			me.put()
		elif self.request.get('end') == 'true':
			me.slide = None
			me.put()
	
	def get(self):
		me = Live.get_current()
		s = me.slide
		response = { "slide": None }
		
		if s is not None:
			response["slide"] = s.to_data()
			# {
			# 				"presentation": {
			# 					"id": s.presentation.key().id(),
			# 					"URL": p.PresentationJSONView.url(s.presentation)
			# 				},
			# 				"ordinal": s.sorting_order,
			# 				"URL": p.SlideJSONView.url(s)
			# 			}
			response["slide"]["URL"] = p.SlideJSONView.url(s)
			questions = []
			
			for pt in s.point_set:
				for q in pt.question_set:
					questions.append(qa.QuestionView.url(q))
			
			response["slide"]["questionURLs"] = questions
		
		self.response.headers['Content-Type'] = 'application/json'
		json.dump(response, self.response.out)
	

def append_handlers(list):
	list.append((LiveControl.url_scheme, LiveControl))
	