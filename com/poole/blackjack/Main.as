﻿package com.poole.blackjack {
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import com.poole.blackjack.helper.HandleXML;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import com.poole.blackjack.TouchEvents;
	import com.greensock.*;
	import com.greensock.easing.*;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	//I pinpointed the crashes to the point where I've finshed loading an asset and start loading another, though could not figure why it was crashing without error
	
	public class Main extends MovieClip {
		private var game:MovieClip;	//pass stage ref
		private var intro:MovieClip;
		private var menu:MovieClip;
		private var settings:MovieClip;
		private var cState;	//state of app
		private var xmlLoader:HandleXML = new HandleXML(this,'data',false);
		private var xml:XML;
		private var container:MovieClip = new MovieClip();
		private var sources:Array;	//holds all imported files
		private var touchRef = new TouchEvents(stage);
		
		public function Main() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//addChild(loadBar);
			addChild(container);
			container.y=100;
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			changeState("intro");
			addEventListener(Event.CLOSE,Save);
		}
		
		public function GetTouchRef() {
			return touchRef;
		}
		
		public function addToStage(object) {
			addChild(object);
		}
		
		public function XMLDone(xm) {
			xml = xm;
			trace(xml);
			//xmlLoader.SetXML("music", "1");
			xmlLoader.Save();
			//menu.leaderboard.leaderName.text = "Name: "+xml.leaderboard.entry.@name;
			//menu.leaderboard.leaderScore.text = "Score: "+xml.leaderboard.score;
			//menu.leaderboard.leaderPlace.text = "Place: "+xml.leaderboard.entry.@place;
			//trace("Name: "+xml.leaderboard.entry.@name+", Score: "+xml.leaderboard.score+", Place:"+xml.leaderboard.entry.@place);
		}
		
		public function Save(e:Event) {
			xmlLoader.Save(true);
		}
		
		public function EditSetting(thenode,thename,thevalue,save:Boolean=false) {
			xmlLoader.SetXML(thenode,thename,thevalue);
			if (save) {xmlLoader.Save();}
		}
		
		public function GetSetting(thenode,thename) {
			return xmlLoader.GetXML(thenode,thename);
		}
		
		public function fileLoaded(file) {
			trace(file.GetType()+":"+file.GetName()+" done loading");
			if (file.GetType() != "sound") {container.addChild(file.GetObject())};
			if (xmlLoader.AllFilesLoaded()) {
				//removeChild(loadBar);
				trace("all files have finished loading");
				xmlLoader.Save(true);
			}
		}
		
		public function setSources(arr) {
			sources = arr;
		}
		
		public function GetSource(key:String=null) {
			if (sources == null) {return null;}
			if (key != null) {
				if (key in sources) {
					return sources[key];
				}
				else {
					trace("key is not defined");
					return null;
				}
			}
			else {
				return sources;
			}
		}
		
		public function GetRandomSound(key:String,minNum:int,maxNum:int) {
			key=key+Math.floor(Math.random() * (maxNum - minNum + 1) + minNum);
			trace(key+" "+sources[key]);
			if (key != null) {
				if (key in sources) {
					return sources[key];
				}
			}
		}
		
		public function GetXML() {
			return xml;
		}
		
		private function getData(e:Event) {
			xml = xmlLoader.Data();
		}
		
		public function updateLoadBar(loaded,total) {
			//loadBar.loadBar.width = (loaded/total)*loadBar.loadOutline.width;
			//loadBar.loadText.text = new uint(loaded/total*100).toString()+"%";
		}
		
		public function removeFromStage(object) {
			removeChild(object);
		}
		
		public function changeState(stat:String,remove:Boolean=true) {
			if (cState && remove) {removeChild(cState);}
			switch(stat) {
				case "intro":
					intro = new Intro();
					addChild(this[stat]);
					break;
				case "menu":
					menu = new Menu();
					addChild(this[stat]);
					break;
				case "game":
					game = new Game(this);
					addChild(this[stat]);
					this[stat].alpha=0;
					TweenMax.to(this[stat],1,{alpha:1});
					break;
				case "settings":
					settings = new Settings(this);
					addChild(this[stat]);
					this[stat].alpha=0;
					TweenMax.to(this[stat],1,{alpha:1});
					break;
			}
			if (remove) {
				cState = this[stat];
			}
		}
	}
}
