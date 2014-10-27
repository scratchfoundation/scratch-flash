/**
 * VERSION: 2.01
 * DATE: 2010-12-24
 * AS3
 * UPDATES AND DOCS AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.TweenLite;
	import com.greensock.core.PropTween;

/**
 * If you'd like the inbetween values in a tween to always get rounded to the nearest integer, use the roundProps
 * special property. Just pass in an Array containing the property names that you'd like rounded. For example,
 * if you're tweening the x, y, and alpha properties of mc and you want to round the x and y values (not alpha)
 * every time the tween is rendered, you'd do: <br /><br /><code>
 * 	
 * 	TweenMax.to(mc, 2, {x:300, y:200, alpha:0.5, roundProps:["x","y"]});<br /><br /></code>
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenMax; <br /> 
 * 		import com.greensock.plugins.RoundPropsPlugin; <br />
 * 		TweenPlugin.activate([RoundPropsPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenMax.to(mc, 2, {x:300, y:200, alpha:0.5, roundProps:["x","y"]}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class RoundPropsPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _tween:TweenLite;
		
		/** @private **/
		public function RoundPropsPlugin() {
			super();
			this.propName = "roundProps";
			this.overwriteProps = ["roundProps"];
			this.round = true;
			this.priority = -1;
			this.onInitAllProps = _initAllProps;
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			_tween = tween;
			this.overwriteProps = this.overwriteProps.concat(value as Array);
			return true;
		}
		
		/** @private **/
		protected function _initAllProps():void {
			var prop:String, multiProps:String, rp:Array = _tween.vars.roundProps, pt:PropTween;
			var i:int = rp.length;
			while (--i > -1) {
				prop = rp[i];
				pt = _tween.cachedPT1;
				while (pt) {
					if (pt.name == prop) {
						if (pt.isPlugin) {
							pt.target.round = true;
						} else {
							add(pt.target, prop, pt.start, pt.change);
							_removePropTween(pt);
							_tween.propTweenLookup[prop] = _tween.propTweenLookup.roundProps;
						}
					} else if (pt.isPlugin && pt.name == "_MULTIPLE_" && !pt.target.round) {
						multiProps = " " + pt.target.overwriteProps.join(" ") + " ";
						if (multiProps.indexOf(" " + prop + " ") != -1) {
							pt.target.round = true;
						}
					}
					pt = pt.nextNode;
				}
			}
		}
		
		/** @private **/
		protected function _removePropTween(propTween:PropTween):void {
			if (propTween.nextNode) {
				propTween.nextNode.prevNode = propTween.prevNode;
			}
			if (propTween.prevNode) {
				propTween.prevNode.nextNode = propTween.nextNode;
			} else if (_tween.cachedPT1 == propTween) {
				_tween.cachedPT1 = propTween.nextNode;
			}
			if (propTween.isPlugin && propTween.target.onDisable) {
				propTween.target.onDisable(); //some plugins need to be notified so they can perform cleanup tasks first
			}
		}
		
		/** @private **/
		public function add(object:Object, propName:String, start:Number, change:Number):void {
			addTween(object, propName, start, start + change, propName);
			this.overwriteProps[this.overwriteProps.length] = propName;
		}

	}
}