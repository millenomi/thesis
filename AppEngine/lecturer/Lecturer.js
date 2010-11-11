var live;

$(function() {
	var delegate = new ILabs.Subject.LiveDelegate();
	delegate.liveDidStart = function(live) {
		$('#questions-label').text("Waiting for questions...");
	};
	delegate.liveDidFinish = function(live) {
		$('#questions-label').text("Live session not ongoing.");
		$('#questions-list').empty();
	};
	delegate.liveDidPoseNewQuestion = function(live, question) {
		$('#questions-label').text(live.questionsPostedDuringLive().count() + " questions.");
		question.loadSelf(function() {
			$('<li></li>').text(question.kind() + ": " + question.text()).appendTo($('#questions-list'));
		});
	};
	
	live = new ILabs.Subject.Live(delegate);
	live.ongoing(function(o) {
		if (!o) {
			$('#questions-label').text("Live session not ongoing.");
			$('#questions-list').empty();
		}
	});
});
