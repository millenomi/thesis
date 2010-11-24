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
		var $el = $('<div class="slide span-24 last">' +
			'<div class="slide-image span-13">' +
				'<img src="#">' +
			'</div>' +
			'<div class="questions span-11 last"></div>' +
		'</div>');
		
		function newFreeformQuestionElement(question) {
			var $newOne = $('<div class="question freeform"><h2></h2><p class="reference">re: <span class="point"></span></p></div>');

			question.text(function(t) {
				$newOne.find('h2').text(t);
			});
			question.point(function(p) {
				p.text(function(t) {
					$newOne.find('.point').text("“" + t + "”");
				});
			});

			$newOne.data('modelURL', question.URL());
			return $newOne;
		}
		
		var _freeformQuestionElements = [],
			_knownQuestionURLs = Hash(),
			_quickQuestionElementsByKind = Hash();

		return {
			$: $el,
			
			beginUpdating: function(slide) {
				var self = this;
				slide.points(function(pts) {
					pts.asyncValuesOfKey('questions', function(qs) {
						self._actuallyUpdate(slide);
					});
				});
			},
			
			_actuallyUpdate: function(slide) {
				// 1. sort questions
				
				var newFreeformQuestions = [];
				var newQuickQuestionsByKind = Hash();
				
				var points = slide.points();
				if (!points)
					throw "The model should be loaded prior to invoking this method.";
					
				for (var i = 0; i < points.length; i++) {
					var point = points[i];
					var questions = point.questions();
					if (!questions)
						throw "The model should be loaded prior to invoking this method.";
					
					for (var j = 0; j < questions.length; j++) {
						var question = questions[j];
						if (_knownQuestionURLs.hasItem(question.URL()))
							continue;
							
						if (question.kind() == 'freeform' && question.text())
							newFreeformQuestions.push(question);
						else {
							var a = newQuickQuestionsByKind.getItem(question.kind());
							if (!a) {
								a = [];
								newQuickQuestionsByKind.setItem(question.kind(), a);
							}
							
							a.push(question);
						}
						
						_knownQuestionURLs.setItem(question.URL(), true);
					}
				}
				
				// 2. add new elements for freeform questions.
				
				for (var i = 0; i < newFreeformQuestions.length; i++) {
					var $q = newFreeformQuestionElement(newFreeformQuestions[i]);

					var $where = $el.children('.question.freeform:last');
					if ($where.length > 0) {
						$where.after($q);
					} else {
						$where = $el.children('.questions').prepend($q);
					}
				}
			},
		};
	};
}