package options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence
		
		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		//add(grid);

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool');
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool');
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Judgement Counter',
			"If unchecked, the judgement counter gets hidden.",
			'judgementCounter',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Display MS Offset On Note Hits',
			'If checked, an offset (in milliseconds) will appear near notes.',
			'showMsText',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Rating System:',
			'Which rating system would you like to use?',
			'ratingSystem',
			'string',
			['Default', 'Default Colorless', 'Psych', 'Kade', 'Andromeda']);
		addOption(option);
		
		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus.",
			'autoPause',
			'bool');
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Hitsound Type:',
			'Funny notes play the selected sound when you hit them.',
			'hitsoundType',
			'string',
			['Absorb', 
			'Audience', 
			'Beep', 
			'Beep 2', 
			'Bells', 
			'Bells 2', 
			'Bongo', 
			'Clank', 
			'Clank 2', 
			'Clap', 
			'Clap 2', 
			'Clap 3', 
			'Cymbal', 
			'Drum', 
			'Echoclap', 
			'Golf Hit', 
			'Hi-hat', 
			'Key Jingling', 
			'osu! (Default)', 
			'Shot', 
			'Snare', 
			'Switch', 
			'Wood']);
		addOption(option);
		option.onChange = onChangeHitsoundType;

		var option:Option = new Option('Hitsound Volume',
			'Sets the volume of the funny notes\' sounds.',
			'hitsoundVolume',
			'percent');
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);
		
		var option:Option = new Option('Perfect! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Perfect!" in milliseconds.',
			'perfectWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 10;
		option.maxValue = 20;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float');
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Sustains as One Note',
			"If checked, Hold Notes can't be pressed if you miss,\nand count as a single Hit/Miss.\nUncheck this if you prefer the old Input System.",
			'guitarHeroSustains',
			'bool');
		addOption(option);

		super();
	}
	
	function onChangeHitsoundType()
	{
		FlxG.sound.play(Paths.sound(ClientPrefs.data.hitsoundType));
	}

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound(ClientPrefs.data.hitsoundType), ClientPrefs.data.hitsoundVolume);

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;
}