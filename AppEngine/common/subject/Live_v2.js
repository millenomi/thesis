// -- Hash impl from http://www.mojavelinux.com/articles/javascript_hashes.html liberally tweaked.

if (!Array.prototype.valuesOfKey) {
	Array.prototype.valuesOfKey = function(key) {
		var x = [];
		for (var i = 0; i < this.length; i++)
			x.push(this[i][key]);
		return x;
	}
}

if (!Array.prototype.asyncValuesOfKey) {
	Array.prototype.asyncValuesOfKey = function(key, callback) {
		var countOfDownloads = this.length;
		var values = [];
		
		for (var i = 0; i < this.length; i++) {
			(function(index) {
				var self = this[index];
				
				self[key].apply(self, [function(result) {
					countOfDownloads--;
					values[index] = result;
					
					if (countOfDownloads == 0)
						callback(values);
				}]);
			}).apply(this, [i]);
		}
	};
}

function Hash()
{
	var self = {};
	
	self.length = 0;
	self.items = [];
	self.canUseHasOwnProperty = (typeof(Object.prototype.hasOwnProperty) != 'undefined');
	for (var i = 0; i < arguments.length; i += 2) {
		if (typeof(arguments[i + 1]) != 'undefined') {
			this.items[arguments[i]] = arguments[i + 1];
			this.length++;
		}
	}
   
	self.removeItem = function(in_key)
	{
		var tmp_previous;
		if (typeof(this.items[in_key]) != 'undefined') {
			this.length--;
			tmp_previous = this.items[in_key];
			delete this.items[in_key];
		}
	   
		return tmp_previous;
	}

	self.getItem = function(in_key) {
		if (this.canUseHasOwnProperty && !this.items.hasOwnProperty(in_key))
			return undefined;
			
		return this.items[in_key];
	}

	self.setItem = function(in_key, in_value)
	{
		var tmp_previous;
		if (typeof(in_value) != 'undefined') {
			if (typeof(this.items[in_key]) == 'undefined') {
				this.length++;
			}
			else {
				tmp_previous = this.items[in_key];
			}

			this.items[in_key] = in_value;
		}
	   
		return tmp_previous;
	}

	self.hasItem = function(in_key)
	{
		if (this.canUseHasOwnProperty && !this.items.hasOwnProperty(in_key))
			return false;
			
		return typeof(this.items[in_key]) != 'undefined';
	}

	self.clear = function()
	{
		for (var i in this.items) {
			delete this.items[i];
		}

		this.length = 0;
	}
	
	return self;
}

// -----------

if (!window.ILabs)
	window.ILabs = {};
	
if (!ILabs.Subject) {
	ILabs.Subject = {
		load: function(url, success, complete) {
			$.ajax({
				url: url,
				dataType: 'json',
				success: success,
				complete: complete
			});
		}
	};
}

if (!ILabs.Coalescer) {
	ILabs.Coalescer = function() {
		var count = 0;
		var callback = null;
		var finishedOnce = false;
		
		return {
			wait: function() {
				count++;
				var self = this;
				return function() { self.finish(); };
			},
			
			finish: function() {
				count--;
				if (count == 0) {
					if (callback)
						callback.apply(this);
					finishedOnce = true;
				}
			},
			
			whenDone: function(newCallback) {
				if (finishedOnce) {
					newCallback.apply(this);
					return;
				}
				
				callback = newCallback;
			}
		};
	};
}

if (!ILabs.Subject.ModelContext) {
	ILabs.Subject.ModelContext = function() {
		return {
			_knownModelItems: Hash(),
			
			getBy: function(factory, options) {
				if (!options)
					return null;
				
				if (typeof options == 'string')
					options = {URL: options};
				
				if (!options.URL)
					throw "All items requested through a context must have the URL option set (eg {URL: '/some/object/1'}). You can also pass a single string parameter, and it'll work anyway (eg '/some/object/1').";
				
				options.context = this;
				
				var x = this._knownModelItems.getItem(options.URL);
				if (!x) {
					x = factory(options);
					this._knownModelItems.setItem(options.URL, x);
				}
				
				return x;
			},
			
			getByArrayOf: function(factory, optionsArray) {
				var final = [];
				for (var i = 0; i < optionsArray.length; i++) {
					var x = this.getBy(factory, optionsArray[i]);
					if (x)
						final.push(x);
				}
				
				return final;
			},
			
			setObjectForURL: function(object, url) {
				if (this._knownModelItems.hasItem(url))
					throw new "Cannot replace an object with another in a context. (TODO.) Produce a new context instead, then place the object in that context.";
				
				this._knownModelItems.setItem(url, object);
			}
		};
	};
}

if (!ILabs.Subject.ModelItem) {
	ILabs.Subject.ModelItem = function(options) {
		var url = options.URL;
		var context = options.context;
		if (!context) {
			context = ILabs.Subject.ModelContext();
			context.setObjectForURL(this, url);
		}
		
		var self = {
			_knownData: options.knownData,
			_onLoadHandlers: null,
			_hasLoaded: false,
			
			URL: function() { return url; },
			context: function() { return context; },
			
			loadSelf: function(callback, options) {
				var shouldReload = options && options['reload'];
				
				if (!shouldReload && this._hasLoaded) {
					if (callback)
						callback.apply(this);
					return;
				}
				
				if (this._knownData) {
					this._hasLoaded = true;
					this.setValuesWithRemoteData(this._knownData);
					if (callback)
						callback.apply(this);
						
					return;
				}
				
				var needsToLoad = (!this._onLoadHandlers);
				
				if (!this._onLoadHandlers)
					this._onLoadHandlers = [];
				
				if (callback)
					this._onLoadHandlers.push(callback);
				
				if (needsToLoad) {
					var self = this;
					ILabs.Subject.load(this.URL(),
						function onSuccess(data) {
							self._hasLoaded = true;
							self.setValuesWithRemoteData(data);
						
							for (var i = 0; i < self._onLoadHandlers.length; i++)
								self._onLoadHandlers[i].apply(self);
						},
						function onDone() {
							self._onLoadHandlers = null;
						});
				}
			},
			
			getBy: function(kind, url) {
				return this.context().getBy(kind, url);
			},
			getByArrayOf: function(kind, urls) {
				return this.context().getByArrayOf(kind, urls);
			},
			
			setValuesWithRemoteData: function(data) {
				throw "The setValuesWithRemoteData() method is abstract. Override it in your ModelItem specializer.";
			},
			
			addAsyncAccessor: function(name, valueKey) {
				if (!valueKey)
					valueKey = '_' + name;
				
				this[name] = function(callback) {					
					if (this._hasLoaded) {
						if (callback)
							callback.apply(this, [this[valueKey]]);
						return this[valueKey];
					} else {
						var actualCallback = null;
						if (callback) {
							actualCallback = function() {
								if (callback)
									callback.apply(this, [this[valueKey]]);
							}
						}
						
						this.loadSelf(actualCallback);
					}
				};
			},
			
			addAsyncAccessors: function() {
				for (var i = 0; i < arguments.length; i++)
					this.addAsyncAccessor(arguments[i]);
			},
		};
		
		return self;
	};
}

// -----------------------------------------------

if (!ILabs.Subject.Point) {
	ILabs.Subject.Point = function(options) {
		var self = ILabs.Subject.ModelItem(options);
		
		self.setValuesWithRemoteData = function(data) {
			this._text = data.text;
			this._indentation = data.indentation;
			
			this._questions = this.getByArrayOf(ILabs.Subject.Question, data.questionURLs);
			
			this._slide = this.getBy(ILabs.Subject.Slide, data.slideURL);			
		};
		
		self.addAsyncAccessors('text', 'indentation', 'questions', 'slide');
		
		return self;
	}
}

if (!ILabs.Subject.Slide) {
	ILabs.Subject.Slide = function(options) {
		var self = ILabs.Subject.ModelItem(options);
		
		self.setValuesWithRemoteData = function(data) {
			self._sortingOrder = data.sortingOrder;
			
			var optionsArray = [];
			for (var i = 0; i < data.points.length; i++) {
				data.points[i].slideURL = this.URL();
				optionsArray.push({ knownData: data.points[i], URL: data.points[i].URL });
			}
			
			self._points = this.getByArrayOf(ILabs.Subject.Point, optionsArray);
			
			self._presentation = this.getBy(ILabs.Subject.Presentation, data.presentation);
		};
		
		self.addAsyncAccessors('sortingOrder', 'points', 'presentation');
		
		return self;
	};
}

if (!ILabs.Subject.Presentation) {
	ILabs.Subject.Presentation = function(options) {
		var self = ILabs.Subject.ModelItem(options);
		
		// TODO remove this nonsense.
		self.setValuesWithRemoteData = function(data) {
			var slideURLs = data.slides.valuesOfKey('URL');
			this._slides = this.getByArrayOf(ILabs.Subject.Slide, slideURLs);
			this._title = data.title;
		};
		
		self.addAsyncAccessors('slides', 'title');
		
		return self;
	};
}

if (!ILabs.Subject.Question) {
	ILabs.Subject.Question = function(options) {
		var self = ILabs.Subject.ModelItem(options);
		
		self.setValuesWithRemoteData = function(data) {
			self._kind = data.kind;
			self._text = data.text;
			self._point = this.getBy(ILabs.Subject.Point, data.pointURL);
		};
		
		self.addAsyncAccessors('kind', 'text', 'point');
		
		return self;
	};
}

if (!ILabs.Subject.Live) {
	ILabs.Subject.Live = function(options) {
		if (!options)
			options = {};
		
		options.URL = '/live';
		var self = ILabs.Subject.ModelItem(options);
		
		self.delegate = function() { return this._delegate; };
		self.setDelegate = function(d) { this._delegate = ILabs.Subject.LiveDelegateMixin(d); };
				
		self.setValuesWithRemoteData = function(data) {
			var d = this.delegate();
			
			var didStart = (data.slide && !this._slide);
			var didFinish = (!data.slide && this._slide);
			
			var didMoveToSlide = (data.slide && this._slide && data.slide.URL != this._slide.URL());
			
			var questionsAsked = null;
			
			if (data.slide)
				this._slide = this.getBy(ILabs.Subject.Slide, { URL:data.slide.URL, knownData: data.slide });
			else
				delete this._slide;
				
			if (!this._lastQuestionsAsked)
				this._lastQuestionsAsked = [];
			
			if (data.questionsPostedDuringLive && !_.isEqual(this._lastQuestionsAsked, data.questionsPostedDuringLive)) {
				var _data = _(data.questionsPostedDuringLive);
				var newQuestionURLs = _data.without.apply(_data, this._lastQuestionsAsked);
				questionsAsked = this.getByArrayOf(ILabs.Subject.Question, newQuestionURLs);
				this._lastQuestionsAsked = data.questionsPostedDuringLive;
			}
			
			if (d) {
				if (didStart) {
					d.liveDidStart(this);
					d.liveDidMoveToSlide(this, this._slide);
				} else if (didFinish)
					d.liveDidFinish(this);
				else if (didMoveToSlide)
					d.liveDidMoveToSlide(this, this._slide);
					
				if (!didFinish && questionsAsked)
					d.liveDidAskNewQuestions(questionsAsked);
			}
		};
		
		self.start = function() {
			if (!this._timer) {
				var self = this;
				this._timer = window.setInterval(function() { self.loadSelf(null, {reload: true}); }, 1500);				
			}
		};
		
		self.stop = function() {
			if (this._timer) {
				window.clearInterval(this._timer);
				delete this._timer;
			}
		};
		
		self.addAsyncAccessors('slide');
		return self;
	}
}

if (!ILabs.Subject.doNothingFunction)
	ILabs.Subject.doNothingFunction = function() {};

if (!ILabs.Subject.LiveDelegateMixin) {
	ILabs.Subject.LiveDelegateMixin = function(object) {
		var doNothing = ILabs.Subject.doNothingFunction;
		
		if (!object.liveDidStart)
			object.liveDidStart = doNothing;
		if (!object.liveDidFinish)
			object.liveDidFinish = doNothing;
		if (!object.liveDidMoveToSlide)
			object.liveDidMoveToSlide = doNothing;
		if (!object.liveDidAskNewQuestions)
			object.liveDidAskNewQuestions = doNothing;
			
		return object;
	}
}
