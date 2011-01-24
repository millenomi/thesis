
if (!this.Subject)
	this.Subject = {};
	
Subject.loadScripts = function(scripts, whenDone) {
	var toLoad = scripts.length;
	
	for (var i = 0; i < arguments.length; i++) {
		var s = document.createElement('script');
		s.src = scripts[i];
		s.type = 'text/javascript';
		
		s.onload = function() {
			toLoad--;
			if (toLoad == 0 && whenDone)
				whenDone();
		};
		
		document.body.appendChild(s);
	}
};

Subject.loadScripts(
	[
		'/common/js/jquery-1.4.3.min.js',
		
		'/common/subject/v3/Model.js',
	],
	function() {
		jQuery(document).ready(function() {

		});
	});