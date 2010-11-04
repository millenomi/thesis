from google.appengine.ext.db import *
from django.utils import simplejson as json
from google.appengine.ext import webapp as w

class Presentation(Model):
	title = StringProperty()
	created_on = DateTimeProperty(auto_now_add = True)
	
	def to_data(self, include_contents_of_slides = False):
		pres_data = { "title": self.title, "slides": [] }

		for s in Slide.gql("WHERE presentation = :1 ORDER BY sorting_order ASC", self):
			slide_data = { 'URL': SlideJSONView.url(s) }
			if include_contents_of_slides:
				slide_data['contents'] = s.to_data()
			
			pres_data['slides'].append(slide_data)
			
		return pres_data
		
	@classmethod
	def key_for_id(self, id):
		return Key.from_path('Presentation', long(id))
		
	@classmethod
	def get_by_url_id(self, url_id):
		return self.get(self.key_for_id(url_id))
		
	def slide_at_index(self, i):
		return Slide.gql("WHERE presentation = :1 AND sorting_order = :2", self, long(i)).get()
	
class Slide(Model):
	presentation = ReferenceProperty(Presentation)
	sorting_order = IntegerProperty()
	
	def to_data(self):
		slide_data = { "sortingOrder": self.sorting_order, "points": [] }

		for p in Point.gql("WHERE slide = :1 ORDER BY sorting_order ASC", self):
			point_data = p.to_data()
			point_data["URL"] = PointJSONView.url(p)
			slide_data["points"].append(point_data)
			
		slide_data["presentation"] = PresentationJSONView.url(self.presentation)
		
		return slide_data
	
	def point_at_index(self, i):
		return Point.gql("WHERE slide = :1 AND sorting_order = :2", self, long(i)).get()
		
class Point(Model):
	slide = ReferenceProperty(Slide)
	text = TextProperty()
	indentation = IntegerProperty()
	sorting_order = IntegerProperty()
	# question_set = a set of question.Question
	
	def to_data(self):
		import question
		point_data = { "text": self.text, "indentation": self.indentation, "questionURLs": [] }
		
		for q in self.question_set:
			point_data["questionURLs"].append(question.QuestionView.url(q))
			
		return point_data

def presentation_from_data(pres_data):
	def tx():
		pres = Presentation()
		pres.title = pres_data['title']
		pres.put()
		
		i = 0
		for slide_data in pres_data['slides']:
			s = Slide(presentation = pres, parent = pres)
			s.sorting_order = i
			s.put()
			
			j = 0
			
			for point_data in slide_data['points']:
				p = Point(slide = s, parent = s)
				p.text = point_data['text']
				p.indentation = point_data['indentation']
				p.sorting_order = j
				p.put()

				j += 1
			
			i += 1
		
		return pres
	
	return run_in_transaction(tx)

class AllPresentationsJSONView(w.RequestHandler):
	url_scheme = '/presentations/all'

	@classmethod
	def url(self):
		return self.url_scheme
	
	def get(self):
		presentations = [PresentationJSONView.url(x) for x in Presentation.all()]
		self.response.headers['Content-Type'] = 'application/json'
		json.dump(presentations, self.response.out)

class PresentationJSONView(w.RequestHandler):
	url_scheme = '/presentations/(at|content_of)/([^/])*'

	@classmethod
	def url(self, pres, include_contents_of_slides = False):
		pres = pres.key()
		if not include_contents_of_slides:
			action = 'at'
		else:
			action = 'content_of'
		
		return "/presentations/%s/%s" % (action, str(pres.id()))
	
	def get(self, action, id):
		p = Presentation.get_by_id(long(id))
		content = (action == "content_of")
		
		if p is None:
			self.response.headers['Content-Type'] = 'text/plain'
			self.response.out.write("Not found")
			self.error(404)
			return

		self.response.headers['Content-Type'] = 'application/json'
		json.dump(p.to_data(include_contents_of_slides = content), self.response.out)
		
class SlideJSONView(w.RequestHandler):
	url_scheme = '/presentations/at/(.*)/slides/(.*)'
	
	@classmethod
	def url(self, slide):
		return "/presentations/at/%s/slides/%s" % (str(slide.presentation.key().id()), str(slide.sorting_order))
	
	def get(self, pres, index):
		pres = Presentation.key_for_id(long(pres))
		index = long(index)
		
		s = Slide.gql("WHERE presentation = :1 AND sorting_order = :2", pres, index).get()
		if s is None:
			self.response.headers['Content-Type'] = 'text/plain'
			self.response.out.write("Not found")
			self.error(404)
			return

		self.response.headers['Content-Type'] = 'application/json'
		json.dump(s.to_data(), self.response.out)

class PresentationLoader(w.RequestHandler):
	url_scheme = '/presentations/new'
	
	def post(self):
		if self.request.headers['Content-Type'] != 'application/json' and \
		 self.request.headers['Content-Type'] != 'text/json':
			self.error(400)
			self.response.headers['X-IL-ErrorReason'] = "content type unacceptable"
			return
		
		p = presentation_from_data(json.loads(self.request.body))
		if p is not None:
			self.redirect(PresentationJSONView.url(p))
		else:
			self.error(400)
			self.response.headers['X-IL-ErrorReason'] = "cannot parse JSON into a presentation"

class PointJSONView(w.RequestHandler):
	url_scheme = '/presentations/at/(.*)/slides/(.*)/points/(.*)'
	
	@classmethod
	def url(self, point):
		return "/presentations/at/%s/slides/%s/points/%s" % (str(point.slide.presentation.key().id()), str(point.slide.sorting_order), str(point.sorting_order))
		
	def get(self, pres, slide_index, point_index):
		pres = Presentation.key_for_id(long(pres))
		slide_index = long(slide_index)
		point_index = long(point_index)
		
		s = Slide.gql("WHERE presentation = :1 AND sorting_order = :2", pres, slide_index).get()
		if s is None:
			self.response.headers['X-IL-ErrorReason'] = "slide not found"
			self.response.headers['Content-Type'] = 'text/plain'
			self.response.out.write("Not found")
			self.error(404)
			return

		p = Point.gql("WHERE slide = :1 AND sorting_order = :2", s, point_index).get()
		if p is None:
			self.response.headers['X-IL-ErrorReason'] = "point not found in slide"
			self.response.headers['Content-Type'] = 'text/plain'
			self.response.out.write("Not found")
			self.error(404)
			return
		
		self.response.headers['Content-Type'] = 'application/json'
		x = p.to_data(); x["slideURL"] = SlideJSONView.url(p.slide)
		json.dump(x, self.response.out)
	
def append_handlers(list):
	list.append((PointJSONView.url_scheme, PointJSONView))
	list.append((SlideJSONView.url_scheme, SlideJSONView))
	list.append((AllPresentationsJSONView.url_scheme, AllPresentationsJSONView))
	list.append((PresentationJSONView.url_scheme, PresentationJSONView))
	list.append((PresentationLoader.url_scheme, PresentationLoader))
