package Loader_fla
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.ui.Keyboard;
	import flash.utils.*;
	import flash.filters.*;

	dynamic public class MainTimeline extends MovieClip
	{
	  	public static var Game:Object;
		public var mcLoading:MovieClip;
		public var sFile:String;
		public var sTitle:String;
		public var sBG:String;
		public var sURL:String = "https://game.aq.com/game/";
		public var LoginURL:String = this.sURL + "api/login/now";
		public var versionURL:String = this.sURL + "api/data/gameversion";
	  	public var urlLoader:URLLoader;
		public var loaderVars:Object;
	 	public var loader:Loader;

		{
			MovieClip.prototype.removeAllChildren = function():void
			{
				var c:* = this.numChildren - 1;
				while(c >= 0)
				{
				this.removeChildAt(c);
				c--;
				}
			};
		}

		public function MainTimeline()
		{
			super();
			addEventListener(Event.ADDED_TO_STAGE,this.OnAddedToStage);
		}

		private function OnAddedToStage(event:Event) : void
		{
			removeEventListener(Event.ADDED_TO_STAGE,this.OnAddedToStage);
			try {
				Security.allowDomain("*");
			} catch (e) { };
			this.urlLoader = new URLLoader();
			this.urlLoader.addEventListener(Event.COMPLETE,this.OnDataComplete);
			this.urlLoader.load(new URLRequest(this.versionURL));
			stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyboardDown);
		}

		public function OnDataComplete(event:Event) : void
		{
			this.urlLoader.removeEventListener(Event.COMPLETE,this.OnDataComplete);
			var vars:Object = JSON.parse(event.target.data);
			this.sFile = vars.sFile;
			this.sTitle = vars.sTitle;
			this.sBG = vars.sBG;
			this.loaderVars = vars;
			this.LoadGame();
		}

		public function LoadGame() : void
		{
			loaderContext = new LoaderContext(false,new ApplicationDomain(null));
			loaderContext.allowCodeImport = true;
			this.loader = new Loader();
			this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.OnProgress);
			this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.OnComplete);
			// this.loader.load(new URLRequest(this.sURL + "gamefiles/" + this.sFile), loaderContext);
			this.loader.load(new URLRequest("app:/gamefiles/Game3089.swf"), loaderContext);
			this.mcLoading.strLoad.text = "Loading 0%";
		}

		public function OnProgress(event:ProgressEvent) : void
		{
			var progress:* = event.currentTarget.bytesLoaded / event.currentTarget.bytesTotal * 100;
			this.mcLoading.strLoad.text = "Loading " + progress + "%";
		}

		public function OnComplete(event:Event) : void
		{
			var param:* = undefined;
			this.loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, this.OnProgress);
			this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.OnComplete);
		 	this.stg = stage;
			this.stg.removeChildAt(0);
			Game = this.stg.addChildAt(event.currentTarget.content, 0);			
			for(param in root.loaderInfo.parameters)
			{
			   Game.params[param] = root.loaderInfo.parameters[param];
			}
			Game.params.sURL = this.sURL;
			Game.params.sBG = this.sBG;
			Game.params.sTitle = this.sTitle;
			Game.params.loginURL = this.LoginURL;		
			Game.loginLoader.addEventListener(Event.COMPLETE, this.OnLoginComplete);	
			this.stg.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyboardDown);
		}

		private function getTextBox(): String 
		{
			var text: String = "";
			if (Game.ui.mcInterface.ncText != null) text = Game.ui.mcInterface.ncText.text;
			if (Game.ui.mcInterface.te != null) text = Game.ui.mcInterface.te.text;
			return text;
		}

		private function OnLoginComplete(event:Event) : void
		{
			var vars:Object = JSON.parse(event.target.data);
			vars.login.iUpg = 10;
			vars.login.iUpgDays = 999;
			for (var s in vars.servers) 
			{
				vars.servers[s].sName = vars.servers[s].sName;
			}
			trace("res: " + JSON.stringify(vars));
			event.target.data = JSON.stringify(vars);
		}
		
		private function IsLoggedIn() : Boolean
		{
			return Game != null && Game.sfc != null && Game.sfc.isConnected == true;
		}
		
		private function IsPlayerAlive() : Boolean 
		{
			return Game.world.myAvatar.dataLeaf.intHP > 0;
		}
		
		private function SendMessage(text:String)
		{
			Game.chatF.pushMsg("server", text,"SERVER","",0);
		}
		
		private function onKeyboardDown(event:KeyboardEvent) : void
		{
			trace("text: " + this.getTextBox())
			if (!IsLoggedIn() || this.getTextBox().substr(0, 2) != "/.") return;
			switch (event.keyCode)
			{
				case Keyboard.A:
					ToggleAutoBattling();
					break;

				case Keyboard.X:
					Game.world.moveToCell(Game.world.strFrame, Game.world.strPad);
					break;

				case Keyboard.B:
					Game.world.toggleBank();
					break;

				case Keyboard.W:
					if (Game.world.WALKSPEED == 8) 
					{
						this.SendMessage("[WalkSpeed] 2x Speed");
						Game.world.WALKSPEED = 16;
					}
					else
					{
						this.SendMessage("[WalkSpeed] Normal Speed");
						Game.world.WALKSPEED = 8;
					}
					break;

				case Keyboard.L:
					Game.world.visible = !Game.world.visible;
					break;
			}
		}

		
		private var isBotting:Boolean = false;
		private var botTimer:Timer = new Timer(100); // in ms
		private var skillDelay:int = 0;
		private var skillIndex:int = 0;
		
		private function ToggleAutoBattling() : Boolean
		{
			this.isBotting = !this.isBotting;
			if (this.isBotting) 
			{
				for (var s in Game.world.actions.active) 
				{
					Game.world.actions.active[s].range = "20000";
				}
				this.SendMessage("[BOT] Generic Attack is ON");
				botTimer.addEventListener(TimerEvent.TIMER, KillMonster);
				botTimer.start();
				return true;
			}
			else
			{
				this.SendMessage("[BOT] Generic Attack is OFF");
				botTimer.removeEventListener(TimerEvent.TIMER, KillMonster);
				botTimer.stop();
				return false;
			}
		}
		
		private function KillMonster(e:TimerEvent):void
		{
			if (!IsLoggedIn()) 
			{
				botTimer.removeEventListener(TimerEvent.TIMER, kill);
				botTimer.stop();
				this.skillDelay = 0;
				this.isBotting = false;
				return;
			}
			this.skillDelay++;
			if (this.skillDelay == 2) //200ms
			{
				if (Game.world.myAvatar.target == null) 
				{
					//random monster
					Game.world.setTarget(GetMonsterByName("*"));
				}
				UseSkill(skillIndex.toString());
				skillIndex++;
				if (skillIndex > 4) skillIndex = 0;
				this.skillDelay = 0;
			}
		}
		
		private function GetMonsterByName(name:String):Object
		{
			for each (var mon:Object in Game.world.getMonstersByCell(Game.world.strFrame))
			{
				if (mon.pMC) 
				{
					var monster:String = mon.pMC.pname.ti.text.toLowerCase();
					if (((monster.indexOf(name.toLowerCase()) > -1) || (name == "*")) && mon.dataLeaf.intState > 0)
					{
						return mon;
					}
				}
			}
			return null;
		}
		
		private function UseSkill(index:String) : Boolean
		{	
			if (Game.world.myAvatar.dataLeaf.intHP == 0) return false;
			
			var myHP:int = Game.world.myAvatar.dataLeaf.intHP / Game.world.myAvatar.dataLeaf.intHPMax * 100;
			switch (Game.world.myAvatar.objData.strClassName)
			{
				case "Void Highlord":
					if (myHP < 40 && (index == "1" || index == "3"))
						return false;
					break;
				case "Scarlet Sorceress":
					if (myHP < 30 && (index == "1" || index == "4"))
						return false;
					break;
				case "Dragon of Time":
					if (myHP < 30 && (index == "1" || index == "3"))
						return false;
					break;
			}
			
			var skill:Object = Game.world.actions.active[parseInt(index)];
			if (Game.world.myAvatar.target == Game.world.myAvatar)
			{
				Game.world.myAvatar.target = null;
				return false;
			}
			if (Game.world.myAvatar.target != null && Game.world.myAvatar.target.dataLeaf.intHP > 0)
			{
				Game.world.approachTarget();
				if (IsSkillReady(skill) == 0)
				{
					if (Game.world.myAvatar.dataLeaf.intMP >= skill.mp)
					{
						if (skill.isOK && !skill.skillLock)
						{
							Game.world.testAction(skill);
						}
					}
				}
				return true;
			}
			return false;
		}
		
		private function IsSkillReady(param1) : int
		{
			var _loc_4:* = NaN;
			var _loc_2:* = new Date().getTime();
			var _loc_3:* = 1 - Math.min(Math.max(Game.world.myAvatar.dataLeaf.sta.$tha, -1), 0.5);
			if (param1.OldCD != null)
			{
				_loc_4 = Math.round(param1.OldCD * _loc_3);
				delete param1.OldCD;
			}
			else
			{
				_loc_4 = Math.round(param1.cd * _loc_3);
			}
			var _loc_5:* = Game.world.GCD - (_loc_2 - Game.world.GCDTS);
			if (_loc_5 < 0)
			{
				_loc_5 = 0;
			}
			var _loc_6:* = _loc_4 - (_loc_2 - param1.ts);
			if (_loc_6 < 0)
			{
				_loc_6 = 0;
			}
			return Math.max(_loc_5, _loc_6);
		}
	}
}
