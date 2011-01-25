(function() {
  var I, L, _base, _ref, _ref2, _ref3;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  (_ref = this.ILabs) != null ? _ref : this.ILabs = {};
  (_ref2 = ILabs.Subject) != null ? _ref2 : ILabs.Subject = {};
  (_ref3 = (_base = ILabs.Subject).Lecturers) != null ? _ref3 : _base.Lecturers = {};
  I = ILabs.Subject;
  L = ILabs.Subject.Lecturers;
  L.log = function() {
    if (window.console && console.log) {
      return console.log.apply(console, arguments);
    }
  };
  I.View = function() {
    function View() {}
    View.prototype.jQ = function() {
      if (this.element) {
        return this.element;
      }
      throw "Return a jQuery object with a single element from this method!";
    };
    View.prototype.contents = function() {
      return this._contents;
    };
    View.prototype.setContents = function(newViews) {
      var contentElements, i, view, _i, _len;
      this._contents = newViews;
      if (newViews.length === 0) {
        this.jQ().empty();
        return;
      }
      i = 0;
      contentElements = jQuery();
      for (_i = 0, _len = newViews.length; _i < _len; _i++) {
        view = newViews[_i];
        if (view && view.jQ) {
          contentElements = contentElements.add(view.jQ());
        }
      }
      return this.jQ().append(contentElements);
    };
    return View;
  }();
  L.CollectionView = function() {
    __extends(CollectionView, I.View);
    function CollectionView(itemViewClass, element) {
      this.itemViewClass = itemViewClass;
      this.element = element || jQuery('<div></div>');
      this.items = [];
    }
    CollectionView.prototype.empty = function() {
      this.items = [];
      return this.setContents([]);
    };
    CollectionView.prototype.setItemAtIndex = function(index, object) {
      var item;
      if (this.itemViewClass) {
        item = new this.itemViewClass(object);
      } else {
        item = object;
      }
      this.items[index] = item;
      return this.setContents(this.items);
    };
    CollectionView.prototype.append = function(object) {
      return this.setItemAtIndex(this.items.length, object);
    };
    return CollectionView;
  }();
  L.LecturersScreen = function() {
    __extends(LecturersScreen, I.View);
    function LecturersScreen(live) {
      this.live = live;
      this.slideViews = [];
      this.slideViewsByURL = {};
      this.element = jQuery('<div class="ILabs-Subject-Lecturers-LecturersScreen"></div>');
      this.live.setDelegate(this);
    }
    LecturersScreen.prototype.setPresentation = function(object) {
      this.setContents([]);
      this.presentation = object;
      return this.presentation.loadSelf(__bind(function() {
        var s, _fn, _i, _len, _ref, _results;
        _ref = object.slides();
        _fn = function(s) {
          this.slideViews = [];
          this.slideViewsByURL = {};
          return _results.push(s.loadSelf(__bind(function() {
            var x;
            x = new L.SlideView(s);
            this.slideViews[s.sortingOrder()] = x;
            this.slideViewsByURL[s.URL()] = x;
            this.setContents(this.slideViews);
            if (this.currentSlideURL === s.URL()) {
              return x.slideIntoView();
            }
          }, this)));
        };
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          s = _ref[_i];
          _fn.call(this, s);
        }
        return _results;
      }, this));
    };
    LecturersScreen.prototype.liveDidAskNewQuestions = function(live, qs) {
      var q, _fn, _i, _len, _results;
      L.log(this, 'will load new questions', qs);
      _fn = function(q) {
        return _results.push(q.loadSelf(__bind(function() {
          var p;
          p = q.point();
          return p.loadSelf(__bind(function() {
            var s;
            s = this.slideViewsByURL[p.slide().URL()];
            if (s) {
              return s.insertQuestion(q);
            }
          }, this));
        }, this)));
      };
      _results = [];
      for (_i = 0, _len = qs.length; _i < _len; _i++) {
        q = qs[_i];
        _fn.call(this, q);
      }
      return _results;
    };
    LecturersScreen.prototype.liveDidMoveToSlide = function(live, slide) {
      var v;
      slide.loadSelf(__bind(function() {
        if (!this.presentation || this.presentation.URL() !== slide.presentation().URL()) {
          return this.setPresentation(slide.presentation());
        }
      }, this));
      this.currentSlideURL = slide.URL();
      v = this.slideViewsByURL[slide.URL()];
      if (v) {
        return v.scrollIntoView();
      }
    };
    return LecturersScreen;
  }();
  L.FreeformQuestionView = function() {
    __extends(FreeformQuestionView, I.View);
    function FreeformQuestionView(question) {
      this.question = question;
      this.element = jQuery('<div class="ILabs-Subject-Lecturers-FreeformQuestionsView"></div>');
      this.question.point().loadSelf(__bind(function() {
        return this.element.append(jQuery('<p class="question"></p>').text(this.question.text())).append(jQuery('<p class="point"></p>').text('‘' + this.question.point().text() + '’'));
      }, this));
    }
    return FreeformQuestionView;
  }();
  L.SlideView = function() {
    __extends(SlideView, I.View);
    function SlideView(slide) {
      var $el;
      this.slide = slide;
      $el = jQuery('\
			<div class="ILabs-Subject-Lecturers-SlideView">\
			</div>');
      this.element = $el;
      if (this.slide.imageURL()) {
        $el.append(jQuery('<img class="slide-image">').attr('src', this.slide.imageURL()));
      }
      this.moodView = new L.MoodView(this.slide);
      $el.append(this.moodView.jQ());
      this.freeformQuestionsElement = jQuery('<div class="freeformQuestions"></div>');
      $el.append(this.freeformQuestionsElement);
      this.freeformQuestions = new L.CollectionView(L.FreeformQuestionView, this.freeformQuestionsElement);
      this.freeformQuestionURLs = {};
      this.shortFormQuestionsElement = jQuery('<div class="shortFormQuestions"></div>');
      $el.append(this.shortFormQuestionsElement);
      I.bind(I.ModelItem.Loaded, __bind(function(e, object) {
        if (object.modelItemKind() === 'ILabs.Subject.Question') {
          return this.insertQuestion(object);
        }
      }, this));
      this.reloadAllPointsAndQuestions();
    }
    SlideView.prototype.reloadAllPointsAndQuestions = function() {
      L.log('Reloading all points and questions for', this);
      return this.slide.loadSelf(__bind(function() {
        var p, _fn, _i, _len, _ref, _results;
        L.log('Reloaded slide', this.slide, 'of', this);
        _ref = this.slide.points();
        _fn = function(p) {
          return _results.push(p.loadSelf(__bind(function() {
            var q, _fn, _i, _len, _ref, _results;
            L.log('Reloaded point', p, 'of slide', this.slide, 'of', this);
            _ref = p.questions();
            _fn = function(q) {
              return _results.push(q.loadSelf(__bind(function() {
                L.log('Reloaded question', q, 'of point', p, 'of slide', this.slide, 'of', this);
                return this.insertQuestion(q);
              }, this)));
            };
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              q = _ref[_i];
              _fn.call(this, q);
            }
            return _results;
          }, this)));
        };
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          _fn.call(this, p);
        }
        return _results;
      }, this));
    };
    SlideView.prototype.insertQuestion = function(q) {
      if (q.kind() === I.Question.FreeformKind && !this.freeformQuestionURLs[q.URL()]) {
        this.freeformQuestionURLs[q.URL()] = true;
        return this.freeformQuestions.append(q);
      }
    };
    SlideView.prototype.slideIntoView = function() {
      var el, x, y;
      x = 0;
      y = 0;
      el = this.element;
      while (el) {
        x += el.offsetLeft;
        y += el.offsetTop;
        el = el.offsetParent;
      }
      return window.scrollTo(x, y);
    };
    return SlideView;
  }();
  L.MoodView = function() {
    __extends(MoodView, I.View);
    function MoodView(slide) {
      var m, _i, _len, _ref;
      this.slide = slide;
      this.element = jQuery('<div></div>');
      I.bind(I.ModelItem.Loaded, __bind(function(e, object) {
        if (object.modelItemKind() === 'ILabs.Subject.Mood') {
          return this.insertMood(m);
        }
      }, this));
      this.live = I.Live.fromContext(this.slide.context());
      if (this.live.moods()) {
        _ref = this.live.moods();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          m = _ref[_i];
          m.loadSelf();
        }
      }
    }
    MoodView.prototype.insertMood = function(m) {
      return L.log("would have inserted mood", m, 'TODO');
    };
    return MoodView;
  }();
}).call(this);
