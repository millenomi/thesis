(function() {
  this.test = function() {
    window._context_ = new Subject.Context();
    return _context_.getOrLoad('/presentations/at/1', Subject.Presentation, function(p) {
      if (window.console) {
        return console.log(p);
      }
    });
  };
  this.pres = function() {
    return _context_.get('/presentations/at/1');
  };
}).call(this);
