
$(function() {

	window.live = ILabs.Subject.Live();

	var orderedSlideViews = [], slideViewsByURL = Hash();
	var enqueuedQuestionLoads = null;
	
	var liveDelegate = {
		liveDidStart: function(l) {
			live.slide().presentation(function(p) {
				p.title(function(t) {
					$('#header')
						.removeClass('loading')
						.children('h1')
							.text(t);
				});
			});
		},
		
		liveDidMoveToSlide: function(l, slide) {
			enqueuedQuestionLoads = [];
			
			slide.loadSelf(function() {
				var x = slideViewsByURL.getItem(slide.URL());
				if (!x) {
					x = ILabs.Subject.SlideView();
					x.setSlide(slide);
					
					slideViewsByURL.setItem(slide.URL(), x);
					orderedSlideViews.push(x);
					orderedSlideViews = _.sortBy(orderedSlideViews, function(sv) { return sv.slide().sortingOrder(); });
					var index = _.indexOf(_.map(orderedSlideViews, function(sv) { return sv.slide().URL(); }), x.slide().URL());
					
					if (index == 0)
						$('.container').append(x.$);
					else
						$('.slide:nth(' + (index - 1) + ')').after(x.$);
				}
				
				x.$.scrollTop(0);
				
				_.each(enqueuedQuestionLoads, function(c) { c(); });
				enqueuedQuestionLoads = null;
			});
		},
		
		liveDidAskNewQuestions: function(l, questions) {
			function actuallyDoIt() {
				_.each(questions, function(q) {
					q.point(function(p) {
						p.slide(function(s) {
							var slideView = slideViewsByURL.getItem(s.URL());
							slideView.insertQuestion(q);
						});						
					});
				});
			}
			
			if (enqueuedQuestionLoads)
				enqueuedQuestionLoads.push(actuallyDoIt);
			else
				actuallyDoIt();
		},
	};

	$('#header').addClass('loading').html("<h1>Waiting for lecture…</h1>");

	live.setDelegate(liveDelegate);
	live.start();
	
});
