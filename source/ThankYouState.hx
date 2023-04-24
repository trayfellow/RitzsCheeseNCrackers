package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.input.keyboard.FlxKey;

class ThankYouState extends MusicBeatState
{
	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var thxs = new FlxSprite().loadGraphic(Paths.image('thxs'));
		thxs.antialiasing = ClientPrefs.globalAntialiasing;
		add(thxs);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK || controls.ACCEPT)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}
}
