(function() {
  var _ref;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  (_ref = this.Subject) != null ? _ref : this.Subject = {};
  Subject.Presentation = function() {
    function Presentation() {
      Presentation.__super__.constructor.apply(this, arguments);
    }
    __extends(Presentation, Subject.ModelObject);
    Presentation.prototype.properties = function() {
      return ['title', 'slides'];
    };
    Presentation.prototype.updateUsingContent = function(content) {
      var slideInfo, _fn, _i, _len, _ref, _results;
      this.setTitle(content.title);
      this.setSlides([]);
      _ref = content.slides;
      _fn = function(slideInfo) {
        return _results.push(this.context.getOrLoad(slideInfo.URL, Subject.Slide, __bind(function(slide) {
          var slides;
          slides = this.slides();
          return slides[slide.sortingOrder()] = slide;
        }, this)));
      };
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        slideInfo = _ref[_i];
        _fn.call(this, slideInfo);
      }
      return _results;
    };
    return Presentation;
  }();
}).call(this);
