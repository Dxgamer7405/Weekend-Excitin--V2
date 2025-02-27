package;

#if desktop
import Discord.DiscordClient;
#end
import Achievements;
import editors.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.1'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = ['story_mode', 'freeplay', 'credits', 'gallery', 'options'];
	var charNames:Array<String> = ['kochi', 'hika', 'tsubasa', 'ren', 'cat'];

	var easterEggEnabled:Bool = true;
	var easterEggKeyCombination:Array<FlxKey> = [FlxKey.B, FlxKey.R, FlxKey.E, FlxKey.A, FlxKey.D];
	var lastKeysPressed:Array<FlxKey> = [];

	var magenta:FlxSprite;
	var line:FlxSprite;
	var menu_character:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var chess:ChessBG;

	var selectedSomethin:Bool = true;

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
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG_b'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		chess = new ChessBG();
		add(chess);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		// Character
		var charX:Array<Float> = [650, 720, 690, 750, 800];
		var charY:Array<Float> = [180, 200, 120, 120, 480];
		var curID:Int = FlxG.random.int(0, charNames.length - 1);
		var curChar:String = charNames[curID];

		menu_character = new FlxSprite(charX[curID], charY[curID]);
		menu_character.frames = Paths.getSparrowAtlas('mainmenuchrs/${curChar == 'cat' ? 'lucky ' : ''}$curChar title');
		menu_character.animation.addByPrefix('bump', '${curChar == 'cat' ? 'lucky_' : ''}${curChar}_title', 24, true);
		menu_character.animation.play('bump');
		menu_character.scale.set(1.1, 1.1);
		menu_character.updateHitbox();
		menu_character.antialiasing = ClientPrefs.globalAntialiasing;
		add(menu_character);

		trace('Menu Character: $curChar');

		// BG Stuff
		line = new FlxSprite().loadGraphic(Paths.image('menubg/line2'));
		line.scrollFactor.set(0, 0);
		line.updateHitbox();
		line.screenCenter();
		line.antialiasing = true;
		add(line);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 10 / optionShit.length;
		}*/

		// Menu Items
		var angles:Array<Float> = [5, 2, -2, -5, -7];
		var valuesY:Array<Float> = [57, 187, 320, 450, 570];
		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, valuesY[i]);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.angle = angles[i];
			menuItem.setGraphicSize(Std.int(menuItem.width * 0.8));
			menuItem.updateHitbox();
			menuItem.scrollFactor.set();
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.x -= menuItem.width;
			FlxTween.tween(menuItem, {x: 60}, 1, {
				ease: FlxEase.backOut,
				startDelay: 0.5 + (0.25 * i),
				onComplete: twn -> if (i == 0) selectedSomethin = false
			});
			menuItems.add(menuItem);
		}

		// FlxG.camera.follow(camFollowPos, null, 2);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Weekend Excitin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2]))
			{ // It's a friday night. WEEEEEEEEEEEEEEEEEE
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
	function giveAchievement()
	{
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		line.x += 10;
		FlxTween.tween(line, {x: -840}, 2.5, {ease: FlxEase.expoOut});

		if (easterEggEnabled)
		{
			var finalKey:FlxKey = FlxG.keys.firstJustPressed();
			if (finalKey != FlxKey.NONE)
			{
				lastKeysPressed.push(finalKey); // Convert int to FlxKey
				if (lastKeysPressed.length > easterEggKeyCombination.length)
				{
					lastKeysPressed.shift();
				}

				if (lastKeysPressed.length == easterEggKeyCombination.length)
				{
					var isDifferent:Bool = false;
					for (i in 0...lastKeysPressed.length)
					{
						if (lastKeysPressed[i] != easterEggKeyCombination[i])
						{
							isDifferent = true;
							break;
						}
					}

					if (!isDifferent)
					{
						trace('Easter egg triggered!');
						// FlxG.save.data.psykaEasterEgg = !FlxG.save.data.psykaEasterEgg;
						FlxG.sound.play(Paths.sound('secretSound'));

						var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
						black.alpha = 0;
						add(black);

						FlxTween.tween(black, {alpha: 1}, 1, {
							onComplete: function(twn:FlxTween)
							{
								PlayState.SONG = Song.loadFromJson("pan-hard", "pan");
								LoadingState.loadAndSwitchState(new PlayState());
							}
						});
						lastKeysPressed = [];
					}
				}
			}
		}

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

					// if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

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
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'gallery':
										MusicBeatState.switchState(new GalleryState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			// spr.screenCenter(X);
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

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 5)
				{
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
