
$(function() {

	window.live = ILabs.Subject.Live();

	var slideView = null;

	var liveDelegate = {
		liveDidStart: function() {
			live.slide().presentation(function(p) {
				p.title(function(t) {
					$('#header')
						.removeClass('loading')
						.children('h1')
							.text(t);
				});
			});
		},
		
		liveDidAskNewQuestions: function(questions) {
			_(questions).each(function(q) {
				q.point(function(p) {
					p.slide(function(s) {
						if (!slideView) {
							slideView = ILabs.Subject.SlideView();
							$('.container').append(slideView.$);
						}
							
						slideView.beginUpdating(s);
					});
				});
			});
		},
	};

	$('#header').addClass('loading').html("<h1>Waiting for lecture…</h1>");

	live.setDelegate(liveDelegate);
	live.start();
	
});
