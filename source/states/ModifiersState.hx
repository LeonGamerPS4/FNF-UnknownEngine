package states;

import flixel.util.FlxGradient;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;

import objects.AttachedText;
import objects.CheckboxThingie;

import substates.PauseSubState;

class ModifiersState extends MusicBeatState
{
	var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x336FECF7, 0x0));
	var gradientBar:FlxSprite = new FlxSprite(0,0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);
	var side:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('Modi_Bottom'));

	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];
	
	public static var isPlayState:Bool = false;
	public static var fromFreeplay:Bool = false;
	public static var fromCampaign:Bool = false;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;
	
	private var descBox:FlxSprite;
	private var descText:FlxText;
	
	var goption:GameplayOption = new GameplayOption('Scroll Type:', 
		"Sets the scroll speed type. Multiplicative multiplies the scroll speed, while Constant sets the scroll speed itself. Can be changed with both types.", 
		'scrolltype', 
		'string', 
		'multiplicative', 
		["multiplicative", "constant"]);
		
	var loption:GameplayOption = new GameplayOption('Scroll Speed:', 
		"Sets how fast the chart speed is. The higher the amount, the faster the notes go. Can be changed numerically.", 
		'scrollspeed', 
		'float', 
		1);
	
	var menuMusic:FlxSound;

	function getOptions()
	{
		optionsArray.push(goption);

		loption.scrollSpeed = 2.0;
		loption.minValue = 0.35;
		loption.changeValue = 0.05;
		loption.decimals = 2;	
		optionsArray.push(loption);

		#if FLX_PITCH
		var option:GameplayOption = new GameplayOption('Playback Rate:', 
			"Change the speed of the song and its pitch. 1.2 is Hifi, 0.8 is Lofi, but you can set it to anything from 0.5 to 3. Can be changed numerically.", 
			'songspeed', 
			'float', 
			1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier:', 
			"Sets how fast you can regain your health. The higher, the faster you can regenerate health. Can be changed numerically.", 
			'healthgain', 
			'float', 
			1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier:', 
			"Sets how fast you can lose your health, or not lose any at all. The higher, the faster you can lose health. Can be changed numerically.", 
			'healthloss', 
			'float', 
			1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);
		
		var option:GameplayOption = new GameplayOption('Starting Health', 
			"Sets your health when starting a song. Can be changed numerically.", 
			'startinghealth', 
			'percent', 
			0.5);
		option.scrollSpeed = 1.7;
		option.minValue = 0.01;
		option.maxValue = 2;
		option.changeValue = 0.01;
		option.displayFormat = '%v%';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Maximum Health', 
			"Sets your maximum health during a song. Can be changed numerically.", 
			'maxhealth', 
			'percent', 
			1);
		option.scrollSpeed = 1.7;
		option.minValue = 0.01;
		option.maxValue = 2;
		option.changeValue = 0.01;
		option.displayFormat = '%v%';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Instakill on Miss', 
			"Miss once, it's game over. Can be switched on or off.", 
			'instakill', 
			'bool', 
			false));
			
		optionsArray.push(new GameplayOption('Harmful Misses', 
			"Be careful, because every time you miss, your max health decreases. It's possible for your max health to be 1% if you're not careful. Can be switched on or off.", 
			'harmfulmisses', 
			'bool', 
			false));
			
		optionsArray.push(new GameplayOption('Practice Mode', 
			"Baby mode initiate. Practice your songs however you want, you won't be dying anytime soon. Score will not be saved. Can be switched on or off.", 
			'practice', 
			'bool', 
			false));
			
		optionsArray.push(new GameplayOption('Botplay', 
			"Just let a bot play for you. Useful for showcase videos and impossible songs. Score will not be saved. Can be switched on or off.", 
			'botplay', 
			'bool', 
			false));
	}

	public function getOptionByName(name:String)
	{
		for(i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	private var bg:FlxSprite;
	
	override function create()
	{
		super.create();
		
		menuMusic = new FlxSound();
		menuMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		menuMusic.volume = 0;
		menuMusic.play(false, FlxG.random.int(0, Std.int(menuMusic.length / 2)));

		FlxG.sound.list.add(menuMusic);
		
		if (!FlxG.sound.music.playing && !isPlayState && ClientPrefs.data.pauseMusic != 'None')
		{
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), menuMusic.volume);
			FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
		}
		else if (!FlxG.sound.music.playing && !isPlayState && ClientPrefs.data.pauseMusic == 'None')
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		
		
		bg = new FlxSprite(0, 0).loadGraphic(Paths.image('modiBG_Main'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.03;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x5585BDFF, 0xAAECE2FF], 1, 90, true); 
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);

		grid.velocity.set(40, 40);
		grid.alpha = 0;
		add(grid);
		grid.scrollFactor.set(0.07, 0.07);

		side.scrollFactor.x = 0;
		side.scrollFactor.y = 0;
		side.antialiasing = true;
		side.screenCenter();
		add(side);
		side.y = FlxG.height - side.height;

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);
		
		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		descText.alpha = 0;
		add(descText);
		
		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(200, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(optionsArray[i].type == 'bool') {
				optionText.x += 90;
				optionText.startPosition.x += 90;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			} else {
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
		
		FlxTween.tween(bg, { alpha:1}, 0.8, { ease: FlxEase.quartInOut});
		FlxTween.tween(grid, { alpha:0.6}, 0.8, { ease: FlxEase.quartInOut});
		FlxTween.tween(descBox, { alpha:0.6}, 0.8, { ease: FlxEase.quartInOut});
		FlxTween.tween(descText, { alpha:1}, 0.8, { ease: FlxEase.quartInOut});
		FlxG.camera.zoom = 0.6;
		FlxG.camera.alpha = 0;
		FlxTween.tween(FlxG.camera, { zoom:1, alpha:1}, 0.7, { ease: FlxEase.quartInOut});
		
		MusicBeatState.windowNameSuffix = " - Modifier Menu";
		
		resetted = false;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	
	public static var resetted:Bool = false;
	
	override function update(elapsed:Float)
	{	
		if (goption.getValue() != "constant")
		{
			loption.displayFormat = '%vX';
			loption.maxValue = 3;
		}
		else
		{
			loption.displayFormat = "%v";
			loption.maxValue = 6;
		}
		
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if(FlxG.mouse.wheel != 0)
		{
			changeSelection(-FlxG.mouse.wheel);
		}
		
		if (FlxG.keys.justPressed.CONTROL)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			openSubState(new substates.PresetSubstate());
		}

		if (controls.BACK) {
			ClientPrefs.saveSettings();
			
			FlxTween.tween(FlxG.camera, { zoom:0.6, alpha:-0.6}, 0.8, { ease: FlxEase.quartInOut});
			FlxTween.tween(bg, { alpha:0}, 0.3, { ease: FlxEase.quartInOut});
			FlxTween.tween(grid, { alpha:0}, 0.3, { ease: FlxEase.quartInOut});
			FlxTween.tween(gradientBar, { alpha:0}, 0.3, { ease: FlxEase.quartInOut});
			FlxTween.tween(side, { alpha:0}, 0.3, { ease: FlxEase.quartInOut});
			FlxTween.tween(descBox, { alpha:0}, 0.3, { ease: FlxEase.quartInOut});
			FlxTween.tween(descText, { alpha:0}, 0.3, { ease: FlxEase.quartInOut});
			
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.4);
			new FlxTimer().start(0.4, function(tmr:FlxTimer)
			{
				FlxG.sound.music.stop();
			});
			if (isPlayState)
			{
				backend.StageData.loadDirectory(PlayState.SONG);
				MusicBeatState.switchState(new PlayState());
				FlxG.sound.music.stop();
			}
			else if (fromFreeplay) {		
				MusicBeatState.switchState(new FreeplayState());
			} else if (fromCampaign) {			
				MusicBeatState.switchState(new StoryMenuState());
			} else {
				MusicBeatState.switchState(new GamemodesMenuState());
			}
		}

		if(nextAccept <= 0)
		{
			var usesCheckbox = true;
			if(curOption.type != 'bool')
			{
				usesCheckbox = false;
			}

			if(usesCheckbox)
			{
				if(controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			} else {
				if(controls.UI_LEFT || controls.UI_RIGHT) {
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed) {
						if(pressed) {
							var add:Dynamic = null;
							if(curOption.type != 'string') {
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch(curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string':
									var num:Int = curOption.curOption; //lol
									if(controls.UI_LEFT_P) --num;
									else num++;

									if(num < 0) {
										num = curOption.options.length - 1;
									} else if(num >= curOption.options.length) {
										num = 0;
									}

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
									
									if (curOption.name == "Scroll Type")
									{
										var oOption:GameplayOption = getOptionByName("Scroll Speed");
										if (oOption != null)
										{
											if (curOption.getValue() == "constant")
											{
												oOption.displayFormat = "%v";
												oOption.maxValue = 6;
											}
											else
											{
												oOption.displayFormat = "%vX";
												oOption.maxValue = 3;
												if(oOption.getValue() > 3) oOption.setValue(3);
											}
											updateTextFrom(oOption);
										}
									}
									//trace(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						} else if(curOption.type != 'string') {
							holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

							switch(curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));
								
								case 'float' | 'percent':
									var blah:Float = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
									curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if(curOption.type != 'string') {
						holdTime += elapsed;
					}
				} else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}
			}

			if (resetted || controls.RESET)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != 'bool')
					{
						if(leOption.type == 'string')
						{
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}

					if(leOption.name == 'Scroll Speed')
					{
						leOption.displayFormat = "%vX";
						leOption.maxValue = 3;
						if(leOption.getValue() > 3)
						{
							leOption.setValue(3);
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if(holdTime > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;
			
		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(Y);
		descText.y += 270;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
		for (text in grpTexts) {
			text.alpha = 0.6;
			if(text.ID == curSelected) {
				text.alpha = 1;
			}
		}
		
		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
		
		curOption = optionsArray[curSelected]; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from ClientPrefs.hx's gameplaySettings
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:String = '';
	public var name:String = 'Unknown';

	public function new(name:String, description:String = '', variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if(defaultValue == 'null variable value')
		{
			switch(type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = '';
					if(options.length > 0) {
						defaultValue = options[0];
					}
			}
		}

		if(getValue() == null) {
			setValue(defaultValue);
		}

		switch(type)
		{
			case 'string':
				var num:Int = options.indexOf(getValue());
				if(num > -1) {
					curOption = num;
				}
	
			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		//nothing lol
		if(onChange != null) {
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return ClientPrefs.data.gameplaySettings.get(variable);
	}
	public function setValue(value:Dynamic)
	{
		ClientPrefs.data.gameplaySettings.set(variable, value);
	}

	public function setChild(child:Alphabet)
	{
		this.child = child;
	}

	private function get_text()
	{
		if(child != null) {
			return child.text;
		}
		return null;
	}
	private function set_text(newValue:String = '')
	{
		if(child != null) {
			child.text = newValue;
		}
		return null;
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch(type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}
		type = newValue;
		return type;
	}
}