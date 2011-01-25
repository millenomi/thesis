if (!window.ILabs)
	window.ILabs = {};
	
if (!ILabs.Subject)
	ILabs.Subject = {};

if (!ILabs.Subject.SlideViewCanonicalQuickQuestionOrder) {
	ILabs.Subject.SlideViewCanonicalQuickQuestionOrder = [
		'didNotUnderstand',
		'goInDepth'
	];
}

if (!ILabs.Subject.SlideView) {
	ILabs.Subject.SlideView = function() {
		if (!ILabs.Subject.MoodsView)
			$(document.body).append('<script src="MoodsView.js" type="text/javascript"></scripts>');
		
		var $el = $('<div class="slide span-24 last">' +
			'<p class="slide-number"></p>' +
			'<div class="slide-image span-13">' +
				'<img src="#">' +
			'</div>' +
			'<div class="questions span-11 last"></div>' +
		'</div>');
		
		function userVisibleOverallTextForQuestionKind(kind, count) {
			var text = (count == 1? 'One person' : count + " people");
			switch (kind) {
				case "didNotUnderstand": text += " did not understand this:"; break;
				case "goInDepth": text += " would like to go in depth on this:"; break;
				default: return "(???)";
			}
			
			return text;
		}
		
		var _knownQuestionURLs = Hash(),
			_shortQuestionsByKind = Hash();

		var _slide = null, _slideObserver = null;
		var _moodsView = null, _moodsViewShown = false;

		return {
			$: $el,
			
			slide: function() { return _slide; },
			setSlide: function(s) {
				_slide = s;
				
				if (s)
					this.beginUpdating();
			},
			
			beginUpdating: function() {
				var slide = this.slide();
				if (!slide)
					return;
				
				var self = this;
				slide.sortingOrder(function(i) {
					$el.find('.slide-number').text((i + 1).toString());
				});
				slide.points(function(pts) {
					_.each(pts, function(pt) {
						pt.loadSelf(function() {
							_.each(pt.questions(), function(q) { self.insertQuestion(q); });
						}, {reload: true});
					});
				});
				slide.imageURL(function(url) {
					$el.find('.slide-image img').attr('src', url);
				});
			},
			
			setMoods: function(moods) {
				if (!_moodsView)
					_moodsView = ILabs.Subject.MoodsView();
					
				_moodsView.setMoods(moods);
				
				if (_moodsView.shouldShow() && !_moodsViewShown) {
					$el.find('.questions').prepend(_moodsView.$);
					_moodsViewShown = true;
				} else if (!_moodsView.shouldShow() && _moodsViewShown) {
					_moodsView.$.hide();
					_moodsViewShown = false;
				}
			},
			
			insertQuestion: function(q) {
				var ident = _.uniqueId();
				if (_knownQuestionURLs.hasItem(q.URL()))
					return;
				
				q.loadSelf(function() {
					if (_knownQuestionURLs.hasItem(q.URL())) {
						console.log(ident, "Jettisoning load attempt because it was already known", q, q.URL());
						return;					
					}
					
					_knownQuestionURLs.setItem(q.URL(), true);
					
					if (q.kind() == "freeform") {
						if (!q.text())
							return;
						
						var $q = $('<div class="question freeform"><h2></h2><p class="reference">• <span class="point"></span></p></div>');
						$q.data('URL', q.URL());
						
						$q.find('h2').text(q.text());
						
						q.point().text(function(t) { $q.find('.point').text(t); });
						
						var $longOnes = $el.find('.question.freeform:last');
						if ($longOnes.length != 0)
							$longOnes.after($q);
						else if (_moodsView)
							_moodsView.$.after($q);
						else
							$el.find('.questions').prepend($q);
						$q.hide().show(400);
						
					} else {
						
						var $qs = _shortQuestionsByKind.getItem(q.kind());
						if (!$qs) {
							$qs = $('<div class="question short"><h2></h2></div>').addClass(q.kind());
							_shortQuestionsByKind.setItem(q.kind(), $qs);
							$el.find('.questions').append($qs);
							$qs.hide().show(400);
						}
						
						var count = $qs.data('count') || 0;
						count++;
						$qs.data('count', count);
						
						$qs.find('h2').text(userVisibleOverallTextForQuestionKind(q.kind(), count));
						
						var found = null; var count;
						$qs.find('.reference').each(function() {
							if ($(this).data('pointURL') == q.point().URL()) {
								found = this; count = $(this).data("count") || 0; return false;
							}
						});
						
						if (!found) {
							var $p = $('<p class="reference">• <span class="point"></span></p></div>');
							q.point().text(function(t) { $p.find('.point').text(t); });
							$p
								.data('pointURL', q.point().URL())
								.data('count', 1)
								;
							$qs.append($p);
							$p.hide().show(300);
						} else {
							$p = $(found);
							count++;
							$p.data('count', count);
							q.point().text(function(t) { $p.find('.point').text("“" + t + "” (" + $p.data('count') + ")"); });
						}
					}
					
				});
			}
		};
	};
}