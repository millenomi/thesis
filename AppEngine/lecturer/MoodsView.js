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
	
	var canonicalMoodsOrder = [
		Moods.Engaged, Moods.WhyAmIHere, Moods.Confused, Moods.Interested, Moods.Bored, Moods.Thoughtful
	];
	
	var Localizer = function(object) {
		if (!object.stringForAmount) {
			object.stringForAmount = function(i) {
				var format = null;
				
				if (this[i])
					format = this[i.toString()];
				else if (this.n)
					format = this.n;
					
				if (format)
					return this.postprocess(_.sprintf(format, i));
				else
					return this.postprocess("<#" + i + "#>")
			};
		}
		
		if (!object.postprocess)
			object.postprocess = _.identity;
		
		return object;
	}
	
	var LocalizerWithPostfix = function(postfix, object) {
		if (!object.postprocess) {
			object.postprocess = function(x) { return x + postfix; };
		}
		
		return Localizer(object);
	}
	
	var PeopleLocalizer = function(postfix) {
		return LocalizerWithPostfix(postfix, {
			1: "One person is",
			n: "%d people are"
		});
	}
	
	var localizersForMoods = {};
	localizersForMoods[Moods.WhyAmIHere] = Localizer({
		1: "One person wonders why they're here",
		n: "%d people are wondering why they're here"
	});
	localizersForMoods[Moods.Thoughtful] = Localizer({
		1: "One person is really thinking about this",
		n: "%d people are really thinking about this"
	});
	localizersForMoods[Moods.Confused] = PeopleLocalizer(" confused");
	localizersForMoods[Moods.Engaged] = PeopleLocalizer(" engaged");
	localizersForMoods[Moods.Bored] = PeopleLocalizer(" bored");
	localizersForMoods[Moods.Interested] = PeopleLocalizer(" interested");
	
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
				_.each(canonicalMoodsOrder, function(mood) {
					if (!moods[mood])
						return;
					
					shouldShow = true;
					
					var l = localizersForMoods[mood];
					if (!l)
						l = { stringForAmount: function(i) { return "<#" + i + "#>"; } };
					
					$el.append(
						$('<p class="mood"></p>')
							.addClass(mood)
							.addClass(Moods.isPositive(mood)? "positive" : "negative")
							.text(l.stringForAmount(moods[mood]))
					);
				});
				
				return shouldShow;
			},
		};
	};
}

