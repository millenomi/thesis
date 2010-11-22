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
		},
		
		asyncAccessor: function(valueKey) {
			return function(callback) {
				var self = this;
				
				if (callback) {
					if (self[valueKey] === undefined) {
						self.loadSelf(function() {
							callback(self[valueKey]);
						});
					} else {
						callback(self[valueKey]);
					}
				}
				
				return self[valueKey];
			}
		},
		
		asyncHasLoadedAccessor: function() {
			return function() {
				return this._asyncAccessorAwaitingCallbacks === null;
			};
		},
		
		asyncLoadFunction: function() {
			return function(callback, options) {
				var self = this;
				
				var shouldReloadEvenIfLoaded = options && options['reload'];
				if (!shouldReloadEvenIfLoaded && self.hasLoaded())
					return;
				
				var waitingForLoad = (self._asyncAccessorAwaitingCallbacks !== undefined && self._asyncAccessorAwaitingCallbacks !== null);
				if (!self._asyncAccessorAwaitingCallbacks)
					self._asyncAccessorAwaitingCallbacks = [];
				if (callback)
					self._asyncAccessorAwaitingCallbacks.unshift(callback);
				
				if (!waitingForLoad) {
					ILabs.Subject.load(self.URL(),
						function onSuccess(data) {
							self.setValuesByParsingData(data);
							var i; for (i = 0; i < self._asyncAccessorAwaitingCallbacks.length; i++)
								(self._asyncAccessorAwaitingCallbacks)[i]();
						},
						function whenDone() {
							self._asyncAccessorAwaitingCallbacks = null;
						});
				};
			}
		},
		
		giveAsyncAccessors: function(self) {
			self.loadSelf = this.asyncLoadFunction();
			self.hasLoaded = this.asyncHasLoadedAccessor();
			var i; for (i = 1; i < arguments.length; i += 2)
				self[arguments[i]] = this.asyncAccessor(arguments[i + 1]);
		}
	};
}
	
if (!ILabs.Subject.ModelSet) {
	ILabs.Subject.ModelSet = function() {};
	ILabs.Subject.ModelSet.prototype = {
		put: function(key, value) {
			if (!this._keys)
				this._keys = [];

			var newValue = (this[key] === undefined);
			this[key] = value;
			
			if (newValue)
				this._keys.unshift(key);
		},
		
		each: function(callback) {
			if (!this._keys)
				return;
			
			var self = this;
			$.each(this._keys, function() {
				var x = self[this];
				if (x)
					callback.apply(x);
			});
		},
		
		count: function() {
			if (!this._keys)
				return 0;
				
			return this._keys.length;
		}
	};
}
	
if (!ILabs.Subject.Live) {
	ILabs.Subject.Live = function(d) {
		this.init(d);
	};

	ILabs.Subject.Live.prototype = {
		init: function(delegate) {
			var self = this;
			if (delegate)
				this.setDelegate(delegate);
			this._intervalID = window.setInterval(function() { self.checkForUpdates(); }, 1000);
			this.checkForUpdates();
		},
		
		stop: function() {
			if (this._intervalID !== null) {
				window.clearInterval(this._intervalID);
				this._intervalID = null;
			}
		},
		
		URL: function() { return '/live'; },
		setValuesByParsingData: function(liveData) {
			var wasOngoing = this._ongoing;
			this._ongoing = (liveData.slide != null);
			
			if (this._ongoing) {
				if (!this._questionsPostedDuringLive)
					this._questionsPostedDuringLive = new ILabs.Subject.ModelSet();
			
				var i; for (i = 0; i < liveData.questionsPostedDuringLive.length; i++) {
					var url = liveData.questionsPostedDuringLive[i];
					if (!this._questionsPostedDuringLive[url]) {
						var q = new ILabs.Subject.Question(url);
						this._questionsPostedDuringLive.put(url, q);
						if (this.delegate())
							this.delegate().liveDidPoseNewQuestion(this, q);
					}
				}
			
				if (!wasOngoing && this.delegate())
					this.delegate().liveDidStart(this);
			} else {
				this._questionsPostedDuringLive = null;
				
				if (wasOngoing && this.delegate())
					this.delegate().liveDidFinish(this);
			}
			
		},
		
		checkForUpdates: function() {
			this.loadSelf(null, {reload: true});
		},
		
		delegate: function() { return this._delegate; },
		setDelegate: function(d) { this._delegate = d; }
	};
	
	ILabs.Subject.giveAsyncAccessors(ILabs.Subject.Live.prototype,
		'ongoing', '_ongoing',
		'questionsPostedDuringLive', '_questionsPostedDuringLive');
}

if (!ILabs.Subject.Question) {
	ILabs.Subject.Question = function(url, callback) { this.init(url, callback); };
	ILabs.Subject.Question.prototype = {
		init: function(url, callback) {
			this._URL = url;
			if (callback)
				this.loadSelf(callback);
		},
		
		URL: function() {
			return this._URL;
		},
		
		setValuesByParsingData: function(data) {
			this._kind = data.kind;
			this._text = data.text;
			this._point = new ILabs.Subject.Point(data.pointURL);
		}
	};
	
	ILabs.Subject.giveAsyncAccessors(ILabs.Subject.Question.prototype,
		'kind', '_kind',
		'text', '_text',
		'point', '_point'
	);
}

if (!ILabs.Subject.Point) {
	ILabs.Subject.Point = function(url) { this.init(url); };
	
	ILabs.Subject.Point.prototype = {
		init: function(url) {
			this._URL = url;
		},
		
		URL: function() {
			return this._URL;
		},
		
		setValuesByParsingData: function(data) {
			this._text = data.text;
			this._indentation = data.indentation;
			
			this._questions = [];
			var i; for (i = 0; i < data.questionURLs.length; i++)
				this._questions.unshift(new ILabs.Subject.Question(data.questionURLs[i]));
				
			// this._slide = new ILabs.Subject.Slide(data.slideURL);
		}
	};
	
	ILabs.Subject.giveAsyncAccessors(ILabs.Subject.Point.prototype,
		'text', '_text',
		'indentation', '_indentation',
		'questions', '_questions'
	);
}

if (!ILabs.Subject.LiveDelegatePrototype) {
	ILabs.Subject.LiveDelegatePrototype = {
		liveDidStart: function(live) {},
		liveDidFinish: function(live) {},
		// didMoveToSlide...
		liveDidPoseNewQuestion: function(live, question) {},
	};
}

if (!ILabs.Subject.LiveDelegate) {
	ILabs.Subject.LiveDelegate = function() {};
	ILabs.Subject.LiveDelegate.prototype = ILabs.Subject.LiveDelegatePrototype;
}
