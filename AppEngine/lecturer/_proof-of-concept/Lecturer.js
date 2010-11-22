var live;
var displayNamesForQuestionKinds = {
	didNotUnderstand: 'Sorry?',
	goInDepth: 'Can you go in depth?'
};

$(function() {
	var delegate = new ILabs.Subject.LiveDelegate();
	delegate.liveDidStart = function(live) {
		$('#questions-label').text("Waiting for questions...");
	};
	delegate.liveDidFinish = function(live) {
		$('#questions-label').text("Live session not ongoing.");
	};
	delegate.liveDidPoseNewQuestion = function(live, question) {
		$('#questions-label').text(live.questionsPostedDuringLive().count() + " questions.");
		question.loadSelf(function() {
			var li = $('<li></li>');
			li.addClass(question.kind());
			if (question.kind() == 'freeform')
				li.text("‘" + question.text() + "’");
			else
				li.text("1x " + displayNamesForQuestionKinds[question.kind()]);
				
			li.appendTo($('#questions-list'));
			
			question.point().text(function(text) {
				$('<span></span>').addClass("point").text(" on “" + text + "”").appendTo(li);
			});
		});
	};
	
	live = new ILabs.Subject.Live(delegate);
	live.ongoing(function(o) {
		if (!o) {
			$('#questions-label').text("Live session not ongoing.");
		}
	});
});
