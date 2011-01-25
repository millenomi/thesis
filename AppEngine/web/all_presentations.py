from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

import presentation as p, os

from jinja2 import Environment, FileSystemLoader
env = Environment(loader = FileSystemLoader(os.path.dirname(__file__)))

class AllPresentationsPageListItem:
	def __init__(self, pres):
		import answers
		self.presentation = pres
		self.display_url = answers.QuestionAnswerView.url(pres)
		
		slide = p.Slide.gql("where presentation = :1 and sorting_order = 0 limit 1", pres).get()
		if slide is not None:
			self.image_url = p.SlideImageView.url(slide)		

class AllPresentationsPage(w.RequestHandler):
	url_scheme = '/presentations/all/show'
	
	@classmethod
	def url(self):
		return self.url_scheme
	
	def get(self):
		all_presentations = p.Presentation.gql("ORDER BY created_on DESC")
		t = env.get_template('all_presentations.html')
		self.response.out.write(t.render({
			'items': [AllPresentationsPageListItem(pres) for pres in all_presentations]
		}))
		
class PresentationPage(w.RequestHandler):
	url_scheme = '/presentations/([^/]+)/show'
	
	@classmethod
	def url(self, pres):
		return '/presentations/%s/show' % str(pres.key())
	
	def get(self, presentation_ident):
		presentation = None
		try:
			presentation = p.Presentation.get(Key(presentation_ident))
		except:
			pass
			
		if presentation is None:
			return self.error(404)
		
		# TODO
		self.redirect(PresentationAttentionMeasuresPage.url(presentation))

# ---------------------------------------------------------------------------

import question, live

CANONICAL_QUESTION_KIND_ORDER = question.Question.AVAILABLE_KINDS

class Accumulator:
	def __init__(self):
		self.clear()
		
	def clear(self):
		self.count = 0
	
	def add(self, x):
		self.count += x
		return self.count
	

# If True, all counts produced by a PresentationAttentionEntry will be randomized.
# Useful for working with mock data.
DEBUG_RANDOMIZE = False

class PresentationAttentionEntry:
	def __init__(self, slide):
		self.slide = slide
		if DEBUG_RANDOMIZE:
			import random
			
			self.number_of_positive_moods = random.randrange(20)
			self.number_of_negative_moods = random.randrange(20)
			
			x = {}
			for kind in CANONICAL_QUESTION_KIND_ORDER:
				x[kind] = random.randrange(20)
			self.number_of_questions_by_kind = x
		else:
			self.number_of_positive_moods = live.Mood.gql("where mood_kind in :1", live.Mood.POSITIVE_MOODS).count()
			self.number_of_negative_moods = live.Mood.gql("where mood_kind in :1", live.Mood.NEGATIVE_MOODS).count()
		
			x = {}
			for pt in slide.point_set:
				for q in pt.question_set:
					if not q.question_kind in x:
						x[q.question_kind] = 1
					else:
						x[q.question_kind] += 1

			self.number_of_questions_by_kind = x
		self.slide_image_url = p.SlideImageView.url(slide)
		
	def number_of_items(self):
		x = self.number_of_negative_moods
		x += self.number_of_positive_moods
		for key in self.number_of_questions_by_kind:
			x += self.number_of_questions_by_kind[key]
		return x
		
	def set_sizes_given_height_and_max(self, height, max):
		self.size_of_positive_moods = max > 0 and height / max * self.number_of_positive_moods or 0
		self.size_of_negative_moods = max > 0 and height / max * self.number_of_negative_moods or 0
		x = []
		for key in CANONICAL_QUESTION_KIND_ORDER:
			if key in self.number_of_questions_by_kind:
				x.append(max > 0 and height / max * self.number_of_questions_by_kind[key] or 0)
		self.sizes_of_questions_in_canonical_order = x

class PresentationAttentionMeasuresPage(w.RequestHandler):
	url_scheme = '/presentations/([^/]+)/show/attention'
	
	@classmethod
	def url(self, pres):
		return '/presentations/%s/show/attention' % str(pres.key())
	
	def get(self, presentation_ident):
		presentation = None
		try:
			presentation = p.Presentation.get(Key(presentation_ident))
		except:
			pass
			
		if presentation is None:
			return self.error(404)
		
		entries = [PresentationAttentionEntry(slide) for slide in p.Slide.gql("where presentation = :1 order by sorting_order", presentation)]
		the_max = max([e.number_of_items() for e in entries])
		height = 300 #px
		
		for e in entries:
			e.set_sizes_given_height_and_max(height, the_max)
		
		t = env.get_template('presentation_attention.html')
		self.response.out.write(t.render({
			'entries': entries,
			'canonical_question_kind_order': CANONICAL_QUESTION_KIND_ORDER,
			'presentation': presentation,
			'accumulator': Accumulator()
		}))
