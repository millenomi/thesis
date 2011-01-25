(function() {
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Subject.Slide = function() {
    function Slide() {
      Slide.__super__.constructor.apply(this, arguments);
    }
    __extends(Slide, Subject.ModelObject);
    Slide.prototype.properties = function() {
      return ['sortingOrder', 'points', 'imageURL'];
    };
    Slide.prototype.updateUsingContent = function(content) {
      var i, point, points, _fn, _i, _len, _ref, _results;
      this.setSortingOrder(content.sortingOrder);
      this.setImageURL(content.imageURL);
      this.setPoints((points = []));
      i = 0;
      _ref = content.points;
      _fn = function(point) {
        i++;
        return _results.push((function(i, point) {
          return this.context.getOrLoad({
            URL: point.URL,
            knownContent: point
          }, Subject.Point, function(x) {
            return points[i] = x;
          });
        })(i, point));
      };
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        point = _ref[_i];
        _fn(point);
      }
      return _results;
    };
    return Slide;
  }();
}).call(this);
