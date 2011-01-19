(function() {
  var _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  (_ref = this.Subject) != null ? _ref : this.Subject = {};
  Subject.Context = function() {
    function Context() {
      this.loadedObjects = {};
    }
    Context.prototype.get = function(url) {
      return this.loadedObjects[url];
    };
    Context.prototype.put = function(url, object) {
      return this.loadedObjects[url] = object;
    };
    Context.prototype.complete = function(url, modelClass, done) {
      return jQuery.ajax({
        dataType: 'json',
        url: url,
        success: __bind(function(contentOfX) {
          modelClass.updateGraphWithContent(this, url, contentOfX);
          return done(this.get(url));
        }, this)
      });
    };
    Context.prototype.getOrLoad = function(url, produce, done) {
      var x;
      x = this.get(url);
      if (x) {
        done(x);
        return;
      } else {
        return this.complete(url, produce, done);
      }
    };
    return Context;
  }();
  Subject.ModelObject = function() {
    function ModelObject(options) {
      var propertyName, _fn, _i, _len, _ref;
      if (options == null) {
        options = {};
      }
      this.URL = options.URL;
      if (!this.URL) {
        throw "Each model object must have a URL";
      }
      this.context = options.context || new Subject.Context();
      _ref = this.properties();
      _fn = function(propertyName) {
        return (__bind(function(property) {
          var setter, variableName;
          variableName = '_' + property;
          this[property] = function() {
            return this[variableName];
          };
          setter = 'set' + property.substr(0, 1).toUpperCase() + property.substr(1);
          return this[setter] = function(x) {
            this[variableName] = x;
            return this;
          };
        }, this))(propertyName);
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        propertyName = _ref[_i];
        _fn.call(this, propertyName);
      }
    }
    ModelObject.prototype.properties = function() {
      throw "The 'properties()' method of a ModelObject is abstract and must be overridden.";
    };
    return ModelObject;
  }();
  Subject.ModelObject.updateGraphWithContent = function(context, url, content) {
    var x;
    x = new this({
      URL: url,
      context: context
    });
    x.updateUsingContent(content);
    return context.put(url, x);
  };
}).call(this);
