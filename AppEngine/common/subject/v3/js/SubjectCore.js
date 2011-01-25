(function() {
  typeof Subject != "undefined" && Subject !== null ? Subject : Subject = {
    loadAllScripts: function(scripts, whenDone) {
      var loadNextScript;
      loadNextScript = function() {
        var script, url;
        url = scripts.shift();
        script = document.createElement('script');
        script.src = url;
        script.type = 'text/javascript';
        script.onload = function() {
          if (scripts.length > 0) {
            return loadNextScript();
          } else {
            return whenDone();
          }
        };
        return document.body.appendChild(script);
      };
      return loadNextScript();
    }
  };
  Subject.loadAllScripts(['/common/js/jquery-1.4.3.min.js', '/common/subject/v3/js/Model.js', '/common/subject/v3/js/Presentation.js', '/common/subject/v3/js/Slide.js', '/common/subject/v3/js/_Scratchpad.js'], function() {
    return test();
  });
}).call(this);
