if (!window.ILabs)
	window.ILabs = {};
	
if (!ILabs.Subject)
	ILabs.Subject = {};

if (!ILabs.Subject.MoodsView) {
	var Moods = {
		WhyAmIHere: 'whyAmIHere',
		Confused: 'confused',
		Bored: 'bored',
		Interested: 'interested',
		Engaged: 'engaged',
		Thoughtful: 'thoughtful',
		
		isPositive: function(mood) {
			return mood == Moods.Engaged || mood == Moods.Interested || mood == Moods.Thoughtful;
		}
	};
	
	Moods.canonicalOrder = [
		Moods.Engaged, Moods.WhyAmIHere, Moods.Interested, Moods.Confused, Moods.Thoughtful, Moods.Bored
	];
	
	ILabs.Subject.MoodsView = function() {
		var $el = $('<div class="moods"></div>');
		var moods = null, shouldShow = false;
		
		return {
			$: $el,
			shouldShow: function() { return shouldShow; },
			
			setMoods: function(summary) {
				moods = summary;
				
				shouldShow = false;
				$el.empty();
				_.each(Moods.canonicalOrder, function(mood) {
					if (!moods[mood])
						return;
					
					shouldShow = true;
					
					$el.append(
						$('<p class="mood"></p>')
							.addClass(mood)
							.addClass(Moods.isPositive(mood)? "positive" : "negative")
							.text(moods[mood].toString())
					);
				});
				
				return shouldShow;
			},
		};
	};
}

