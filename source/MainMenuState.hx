package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import WeekData;

using StringTools;
typedef MainMenuCharData =
{

	x:Float,
	y:Float
}
class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var versionItems:FlxTypedGroup<FlxText>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var curMenuChar:Int = 0;
	var mainMenuBG:FlxSprite;
	var bgTween:FlxTween;
	var menuChars:FlxSprite;
	var mainMenuJSON:MainMenuCharData;
	var optionShit:Array<String> = [
		'story_mode',
		'ritz_mode',
		'freeplay',
		/*You might wanna use the master editor to access the mod menu instead
		#if MODS_ALLOWED 'mods', #end*/
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		/*Grrr..... how dare you hide the button that lets you support the fnf developers....
		#if !switch 'donate', #end*/
		'options'
	];
	
	var ratTrapCode:Array<String> = ['J', 'E', 'T', 'S', 'E', 'T', 'R', 'A', 'D', 'I', 'O'];
	var ratTrapCodeCurArray:Int = 0;
	var keyLists:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var keyListsBuffer:String = '';

	var magenta:AttachedSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		curMenuChar = FlxG.random.int(1, 4);

		mainMenuJSON = Json.parse(Paths.getTextFromFile('images/mainmenucharacters/chara' + curMenuChar + '.json'));

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		mainMenuBG = new FlxSprite(-1500,- 714).loadGraphic(Paths.image('menuPattern'));
		mainMenuBG.scrollFactor.set();
		mainMenuBG.antialiasing = ClientPrefs.globalAntialiasing;
		add(mainMenuBG);

		bgTween = FlxTween.tween(mainMenuBG, {x: -924, y: -392}, 12, {type: LOOPING});

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new AttachedSprite('menuPatternDesat');
		magenta.sprTracker = mainMenuBG;
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuChars = new FlxSprite(mainMenuJSON.x, mainMenuJSON.y);
		menuChars.frames = Paths.getSparrowAtlas('mainmenucharacters/chara' + curMenuChar);
		menuChars.animation.addByPrefix('anim', "animation", 24);
		menuChars.animation.play('anim');
		menuChars.scrollFactor.set();
		menuChars.antialiasing = ClientPrefs.globalAntialiasing;
		add(menuChars);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 60 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 150)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.260;
			if(optionShit.length < 5) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		versionItems = new FlxTypedGroup<FlxText>();
		add(versionItems);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 64, 0, "Ritz's Cheese & Crackers v1.0.0", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionItems.add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		versionItems.add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		versionItems.add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8 && !selectedSomethin)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode' | 'ritz_mode':
										if (daChoice == 'story_mode') 
											StoryMenuState.selectedWeekFromMainMenu = 0; 
										else 
											StoryMenuState.selectedWeekFromMainMenu = 1;

										StoryMenuState.autoMode = false;
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									#if ACHIEVEMENTS_ALLOWED
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									#end
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);

				if (keyLists.contains(keyName)) keyListsBuffer = keyName;

				if (keyListsBuffer == ratTrapCode[ratTrapCodeCurArray])
				{
					FlxG.sound.play(Paths.sound('Metronome_Tick'));
					ratTrapCodeCurArray++;
				}
				else
					ratTrapCodeCurArray = 0;

				if (ratTrapCodeCurArray == ratTrapCode.length)
				{
					ratTrapEntrance();
				} 
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();
			spr.offset.x = -280;

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
				var daChoice:String = optionShit[curSelected];

				switch (daChoice)
				{
					case 'story_mode':
						spr.offset.x = -140;
					case 'ritz_mode':
						spr.offset.x = -80;
					case 'freeplay':
						spr.offset.x = -165;
					case 'mods':
						spr.offset.x = -195;
					case 'options':
						spr.offset.x = -205;
					default:
						spr.offset.x = -110;
				}	
			}
		});
	}

	function ratTrapEntrance():Void
	{
		selectedSomethin = true;
		
		FlxG.sound.play(Paths.sound('Metronome_Tick'));
		FlxG.sound.music.fadeOut(0.5, 0);

		magenta.color = 0xFF69F700;
		
		bgTween.cancel();
		mainMenuBG.setPosition(-1500,- 714);

		FlxTween.tween(menuChars.offset, {x: menuChars.offset.x + 1000}, 0.6, {ease: FlxEase.backInOut});
		menuItems.forEach(function(spr:FlxSprite)
		{
			FlxTween.tween(spr.offset, {x: spr.offset.x - 1000}, 0.6, {ease: FlxEase.backInOut});
		});
		versionItems.forEach(function(txt:FlxText)
		{
			FlxTween.tween(txt.offset, {x: txt.offset.x + 1000}, 0.6, {ease: FlxEase.backInOut});
		});

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			FlxG.sound.play(Paths.sound('JET-SET-RADIOOOOOO'));

			new FlxTimer().start(4.15, function(tmr:FlxTimer)
			{
				bgTween = FlxTween.tween(mainMenuBG, {x: -924, y: -392}, 1.4, {type: LOOPING});

				if(ClientPrefs.flashing)
					FlxFlicker.flicker(magenta, 0, 0.15, false);
				else
					magenta.visible = true;
			});

			new FlxTimer().start(7.1667, function(tmr:FlxTimer)
			{
				StoryMenuState.autoMode = true;
				StoryMenuState.selectedWeekFromMainMenu = 2;
				MusicBeatState.switchState(new StoryMenuState());
			});		
		});
	}
}
