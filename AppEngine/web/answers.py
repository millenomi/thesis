from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

import presentation as p, question as qa, os

from jinja2 import Environment, FileSystemLoader
env = Environment(loader = FileSystemLoader(os.path.dirname(__file__)))

def is_empty(thing):
	return len(thing) == 0
env.tests['empty'] = is_empty

class QASlideInfo:
	def __init__(self, slide, return_url_base):
		self.slide = slide
		self.image_url = p.SlideImageView.url(slide)
		
		self.question_entries = []
		for point in slide.point_set:
			for q in qa.Question.gql("where point = :1 and question_kind = :2", point, qa.Question.FREEFORM):
				self.question_entries.append(QAQuestionInfo(q, return_url_base))
		
class QAQuestionInfo:
	def __init__(self, question, return_url_base):
		self.question = question
		self.answers = qa.Answer.gql("where question = :1 order by created_on", question)
		self.key = str(question.key())
		self.new_answer_url = qa.AnswerAQuestion.url(question)
		self.return_url = return_url_base + "#" + str(question.key())

class QuestionAnswerView(w.RequestHandler):
	url_scheme = '/presentations/([^/]+)/show/qa'
	
	@classmethod
	def url(self, pres):
		return '/presentations/%s/show/qa' % str(pres.key())
	
	def presentation(self, presentation_ident):
		presentation = None
		try:
			presentation = p.Presentation.get(Key(presentation_ident))
		except:
			pass
			
		if presentation is None:
			self.error(404)
		
		return presentation
		
	
	def get(self, presentation_ident):
		presentation = self.presentation(presentation_ident)
		if presentation is None:
			return
			
		return_url_base = QuestionAnswerView.url(presentation)
	
		t = env.get_template('answers.html')
		self.response.out.write(t.render({
			'presentation': presentation,
			'ordered_entries': [QASlideInfo(s, return_url_base) for s in p.Slide.gql("where presentation = :1 order by sorting_order", presentation)]
		}))
		