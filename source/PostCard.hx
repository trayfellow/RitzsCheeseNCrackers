package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.filters.BlurFilter;

class PostCard extends FlxState
{
    public var finishCallback:Void->Void = null;
    var PostCardFlxTween:FlxTweenManager = new FlxTweenManager();
    var blur:BlurFilter;
    var bgDarken:FlxSprite;
    var postCard:FlxSprite;
    var startTxt:FlxText;
    
    var hasWaited:Bool = false;
    var alreadyPressed:Bool = false;

	public function new(fromWho:String)
	{
		super();

        hasWaited = false;
        alreadyPressed = false;
        PlayState.instance.camHUD.visible = false;
        FlxG.sound.playMusic(Paths.music('rats-in-new-york-city'), 1, true);

        if(ClientPrefs.postCardBlur)
        {   
            blur = new BlurFilter(0, 0, 1);
            FlxG.camera.setFilters([blur]);
        }
        
        if(ClientPrefs.postCardBlur)
            PostCardFlxTween.tween(blur, {blurX: 32, blurY: 32}, 0.35, {ease: FlxEase.quadInOut});

        bgDarken = new FlxSprite().makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), FlxColor.BLACK);
		bgDarken.alpha = 0;
        bgDarken.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		add(bgDarken);

        PostCardFlxTween.tween(bgDarken, {alpha: 0.4}, 0.35, {ease: FlxEase.quadInOut});

        postCard = new FlxSprite().loadGraphic(Paths.image('post_cards/postcardFrom-' + fromWho));
		postCard.antialiasing = ClientPrefs.globalAntialiasing;
        postCard.screenCenter();
        postCard.offset.y -= 800;
        postCard.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		add(postCard);

        startTxt = new FlxText(481, 673, FlxG.width, "Press Enter To Begin", 20);
		startTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		startTxt.scrollFactor.set();
		startTxt.borderSize = 1.25;
        startTxt.alpha = 0;
        startTxt.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		add(startTxt);

        //PostCardFlxTween.tween(postCard, {angle: 20}, 2.4, {type: PINGPONG, ease: FlxEase.sineInOut});
        PostCardFlxTween.tween(postCard.scale, {x: 0.95, y: 0.93}, 2.4, {type: PINGPONG, ease: FlxEase.sineInOut});
        PostCardFlxTween.tween(postCard.offset, {y: postCard.offset.y + 800}, 2.4, {
            startDelay: 0.4, ease: FlxEase.quintInOut,
            onComplete: function(twn:FlxTween)
            {
                hasWaited = true;
            }
        });

        new FlxTimer().start(1.9, function(tmr:FlxTimer) {
            PostCardFlxTween.tween(startTxt, {alpha: 1}, 0.5, {
                onComplete: function(twn:FlxTween)
                {
                    hasWaited = true;
                }
            });
        });

        PlayState.instance.add(this);
	}

	override function update(elapsed)
	{
        PostCardFlxTween.update(elapsed);
        super.update(elapsed);

		if(PlayerSettings.player1.controls.ACCEPT && !alreadyPressed && hasWaited)
		{
            alreadyPressed = true;
            FlxG.sound.play(Paths.sound('pageFold' + FlxG.random.int(1, 3)), 1.4);
            FlxG.sound.music.fadeOut();

            PostCardFlxTween.tween(startTxt, {alpha: 0}, 0.5);
            PostCardFlxTween.tween(postCard.offset, {y: -800}, 1.5, {
                ease: FlxEase.backInOut,
                onComplete: function(twn:FlxTween)
                {
                    PostCardFlxTween.tween(bgDarken, {alpha: 0}, 0.9, {
                        ease: FlxEase.quadInOut,
                        onComplete: function(twn:FlxTween)
                        {
                            PlayState.instance.camHUD.visible = true;
                            finishCallback();

                            new FlxTimer().start(0.1, function(tmr:FlxTimer) {
                                if(blur != null)
                                    (blur);
    
                                PostCardFlxTween.clear();
                                kill();
                                destroy();
                                PlayState.instance.remove(this);
                            });
                        }
                    });

                    if(ClientPrefs.postCardBlur)
                      PostCardFlxTween.tween(blur, {blurX: 0, blurY: 0}, 0.8, {ease: FlxEase.quadInOut});
                }
            });
		}
	}
}
