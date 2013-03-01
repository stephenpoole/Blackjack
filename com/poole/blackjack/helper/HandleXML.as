﻿package com.poole.blackjack.helper {
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.events.*;
	import com.poole.blackjack.helper.Blowfish;
	import flash.utils.ByteArray;
	import flash.filesystem.*;
	import flash.utils.setTimeout;
	import flash.display.Loader;

	/*	XML interface
		opens a .void (encrypted) file with instantiation: HandleXML(callback object,url)
			instead opens a plaintext xml file with instantiation: HandleXML(callback object,url,false)
			if neither exist, will create a new save file using the given url
			
			returns xml data with GetXML(attribute)
			sets xml data with SetXML(attribute,value)
		
		treats the children of any "<sources>" tag as files to be loaded, enumerates their sizes and loads them sequentially
			returns file data with GetSource(name,attribute)
			returns object reference with GetSource(name)
			returns entire file array with GetSource()
			
			valid attributes are as follows: name, url, object, type
			
		saves the current xmlObject as .void with Save()
			saves an additional plaintext .xml with Save(true)
	*/
	
	public class HandleXML {
		private var xmlObject:XML;
		private var loader:URLLoader;
		private var notify;
		private var crypto:Blowfish = new Blowfish();
		private var link:String;
		private var sources:Array = new Array();
		private var encrypted:Boolean;
		private var checkedOtherType:Boolean=false;
		private var totalSize:uint = 0;
		private var totalLoaded:Array = new Array();
		
		public function HandleXML(notif,url:String,enc:Boolean=true) {
			encrypted = enc;
			link=url;
			notify=notif;
			Load();
		}
	
		/*public interface functions*/
		public function Data() {
			return xmlObject.data;
		}
		
		public function GetSource(name:String=null,attr:String=null) {
			if (name != null) {
				if (attr != null) {
					if (sources[name][attr] !== undefined) {
						return sources[name][attr];
					}
					else {
						trace("key is not definted");
						return null;
					}
				}
				else if (sources[name]["object"] !== undefined) {
					return sources[name]["object"];
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
		
		public function SetXML(attr:String, val:String) {
			switch (attr) {
				case "music":
					xmlObject.settings.music = val;
					break;
			}
		}
		
		public function GetXML(attr:String) {
			switch (attr) {
				case "music":
					return xmlObject.settings.music;
			}
		}
		
		public function Save(debug:Boolean=false) {
			setTimeout(function() {		//fix weird already open error
				var cipher:String = crypto.encrypt(xmlObject.toXMLString());
				saveFile(cipher,link,"void");
				if (debug) {saveFile(xmlObject.toXMLString(),link,"xml");}
			},100);
		}
		
		public function Load() {
			if (encrypted) {
				loader = new URLLoader(new URLRequest('embed/'+link+".void"));
			}
			else {
				loader = new URLLoader(new URLRequest('embed/'+link+".xml"));
			}
			loader.addEventListener(Event.COMPLETE,loadDone);
			loader.addEventListener(IOErrorEvent.IO_ERROR, XMLLoadError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, XMLLoadError);
		}
		
		public function AllFilesLoaded() {
			for each(var node in sources) {
				if (node[0] == 0) {return false;}
			}
			return true;
		}
		
		/*loader functions*/
		private function loadDone(e:Event) {
			loader.removeEventListener(Event.COMPLETE,loadDone);
			if (encrypted) {	//if loading the encrypted filetype, decrypt it first
				xmlObject = new XML(crypto.decrypt(loader.data));
			}
			else {
				xmlObject = new XML(loader.data);
			}
			loader.close();
			
			/*check for sources to load*/
			var sourceList = xmlObject.sources;
			for each (var node:XML in sourceList.children()) {
				loadFile(node);
			}
			
			notify.XMLDone(xmlObject);
			checkedOtherType=false;
		}
		
		private function loadFile(node:XML) {	//set up files for loading
			var theurl:URLRequest = new URLRequest(node.@url);
			var ldr:Loader = new Loader();
			sources[node.@name] = new Array(0,0);	//done loading, first call
			sources[node.@name]["name"] = node.@name;
			sources[node.@name]["type"] = node.name();
			sources[node.@name]["object"] = ldr;
			sources[node.@name]["url"] = node.@url;
			
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event){loadFileDone(e,sources[node.@name])});
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:ErrorEvent){loadError(e,sources[node.@name])});
			ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,function(e:ErrorEvent){loadError(e,sources[node.@name])});
			ldr.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,function(e:ProgressEvent){onProgress(e,sources[node.@name])});
			ldr.load(theurl);
		}
		
		private function loadFileDone(e:Event,ref) {
			ref["object"].contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			ref[0] = 1;
			notify.fileLoaded(ref);
		}
		
		private function onProgress(e:ProgressEvent,ref) {
			if (ref[1] == 0) {totalSize += e.bytesTotal; ref[1]=1;}
			totalLoaded[e.currentTarget.loaderURL] = e.bytesLoaded;
			notify.updateLoadBar(enumLoaded(),totalSize);
			trace(new uint(enumLoaded()/totalSize*100).toString()+"%");
		}
		
		/*helper functions*/
		private function saveFile(dat:String,filename:String,filetype:String) {
			var bytes = new ByteArray();
			bytes.writeUTFBytes(dat);
			var filestream:FileStream = new FileStream();
			var file = new File(File.applicationDirectory.nativePath+"\\embed\\"+filename+"."+filetype);
			filestream.open(file, FileMode.WRITE);
			filestream.writeBytes(bytes);
			filestream.close();
		}
		
		private function loadError(e:ErrorEvent,ref:String) {
			trace("Load error:"+e);
			ref[2] = 1;
		}
		
		private function XMLLoadError(e:ErrorEvent) {
			loader.removeEventListener(Event.COMPLETE,loadDone);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loadError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loadError);
			loader.close();
			
			if (!checkedOtherType) {
				trace("Load failed, trying to load other type");
				checkedOtherType = true;
				if (e.text.indexOf("2032") >= 0) {	//check for stream error, usually means file does not exist
					encrypted = !encrypted;
					Load();		//try loading the other filetype
				}
			}
			else {
				trace("Both filetypes do not exist, creating new save");
				//generate new save file
				xmlObject = newSaveGameXML();
				notify.XMLDone(xmlObject);
				checkedOtherType=false;
			}
		}
		
		private function newSaveGameXML() {
			var xml:XML = <blackjack>
				  <leaderboard>
					<entry place="1" name="Stephen" score="1200"/>
					<score>1200</score>
				  </leaderboard>
				  <settings>
					<music>1</music>
				  </settings>
				  <guest>
					<chips>0</chips>
					<chipswon>0</chipswon>
					<chipslost>0</chipslost>
					<hands>0</hands>
					<handswon>0</handswon>
					<handslost>0</handslost>
				  </guest>
				</blackjack>;
			return xml;
		}
		
		private function enumLoaded() {
			var temp:uint=0;
			
			for each (var index in totalLoaded) {
				temp += index;
			}
			return temp;
		}
	}
}