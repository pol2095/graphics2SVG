/*
Copyright 2023 pol2095. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package com.utils
{
	import flash.display.IGraphicsData;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	public function graphics2SVG(shape:*, recurse:Boolean = true):String
	{
		var bounds:Rectangle = shape.getBounds( shape );
		var result:Vector.<IGraphicsData> = shape.graphics.readGraphicsData(recurse);
		var width:Number = bounds.x * 2 + bounds.width;
		var height:Number = bounds.y * 2 + bounds.height;
		
		XML.prettyIndent = 4;
		Fill.svg = <svg xmlns={Fill.s.uri} xmlns:xlink={Fill.xlink.uri}><defs/><g/></svg>;
		Fill.svg.@width = width + "px";
		Fill.svg.@height = height + "px";
		Fill.svg.@version = "1.1";
		Fill.svg.@viewBox = 0 + " " + 0 + " " + width + " " + height;
		//trace( svg.toXMLString() );
		Fill.gradients = new Vector.<String>();
		
		for( var i:int = 0; i < result.length; i++ )
		{
			var className:String = getQualifiedClassName( result[i] );
			className = className.substring( className.indexOf( "::" ) + 2 );
			className = className.substr(0, 1).toLowerCase() + className.substr(1, className.length); 
			Fill[className]( result[i] );
		}
		Fill.finalizePath();
		
		var svgString:String = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n' + Fill.svg.toXMLString();
		return svgString.split("    ").join("\t");
	}
}

final class Fill
{
	import flash.display.CapsStyle;
	import flash.display.GradientType;
	import flash.display.GraphicsGradientFill;
	import flash.display.GraphicsPath;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.IGraphicsData;
	import flash.display.InterpolationMethod;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	
	public static var svg:XML;
	private static var path:XML;
	
	public static const s:Namespace = new Namespace("s", "http://www.w3.org/2000/svg");
	public static const xlink:Namespace = new Namespace("xlink", "http://www.w3.org/1999/xlink");
	public static var gradients:Vector.<String>;
	
	private static function toHex(color:uint):String
	{
		var value:String = color.toString(16);
		if( value.length > 6 ) value = value.substring( value.length - 6 );
		var length:int = value.length;
		for(var i:int = 0; i < 6 - length; i++)	value = "0" + value;
		return "#" + value.toUpperCase();
	}
	
	public static function graphicsSolidFill(result:IGraphicsData):void
	{
		finalizePath();
		var gsf:GraphicsSolidFill = result as GraphicsSolidFill;
		path.@stroke = "none";
		path.@fill = toHex(gsf.color);
		if(gsf.alpha != 1) path.@["fill-opacity"] = gsf.alpha;
	}
	
	public static function graphicsPath(result:IGraphicsData):void
	{
		var svgS:Vector.<String> = new <String>[];
		var gp:GraphicsPath = result as GraphicsPath;
		var dataIndex:int = 0;
		for(var i:int = 0 ; i < gp.commands.length; i++)
		{
			switch( gp.commands[i] )
			{
				case 1:
					svgS.push( 'M' + gp.data[dataIndex] + ' ' + gp.data[dataIndex+1] );
					dataIndex+=2;
					break;
				case 2:
					svgS.push( 'L' + gp.data[dataIndex] + ' ' + gp.data[dataIndex+1] );
					dataIndex+=2;
					break;
				case 3:
					svgS.push( 'Q' + gp.data[dataIndex] + ' ' + gp.data[dataIndex+1] + ' ' + gp.data[dataIndex+2] + ' ' + gp.data[dataIndex+3] );
					dataIndex+=4;
					break;
			}
		}
		path.@d = svgS.join(" ");
	}
	
	public static function graphicsEndFill(result:IGraphicsData):void
	{
		//
	}
	
	public static function graphicsStroke(result:IGraphicsData):void
	{
		finalizePath();
		var gs:GraphicsStroke = result as GraphicsStroke;
		var alpha:Number = 1.0;
		var color:uint = 0;
		if( gs.fill )
		{
			alpha = (gs.fill as GraphicsSolidFill).alpha;
			color = (gs.fill as GraphicsSolidFill).color;
		}
		lineStyle(gs.thickness, color, alpha, gs.pixelHinting, gs.scaleMode, gs.caps, gs.caps, gs.joints, gs.miterLimit);
	}
		
	public static function graphicsGradientFill(result:IGraphicsData):void
	{
		finalizePath();
		var ggf:GraphicsGradientFill = result as GraphicsGradientFill;
		beginGradientFill( ggf.type, ggf.colors, ggf.alphas, ggf.ratios, ggf.matrix, ggf.spreadMethod, ggf.interpolationMethod, ggf.focalPointRatio );
	}
	
	private static function beginGradientFill(type:String, colors:Array, alphas:Array, ratios:Array, matrix:Matrix = null, spreadMethod:String = SpreadMethod.PAD, interpolationMethod:String = InterpolationMethod.RGB, focalPointRatio:Number = 0):void {
		delete path.@["stroke-opacity"];
		var gradient:XML = (type == GradientType.LINEAR) ? <linearGradient /> : <radialGradient />;
		populateGradientElement(gradient, type, colors, alphas, ratios, matrix, spreadMethod, interpolationMethod, focalPointRatio);
		var id:int = gradients.indexOf(gradient.toXMLString());
		if(id < 0) {
			id = gradients.length;
			gradients.push(gradient.toXMLString());
		}
		gradient.@id = "gradient" + id;
		path.@stroke = "none";
		path.@fill = "url(#gradient" + id + ")";
		svg.s::defs.appendChild(gradient);
	}
	
	private static function populateGradientElement(gradient:XML, type:String, colors:Array, alphas:Array, ratios:Array, matrix:Matrix, spreadMethod:String, interpolationMethod:String, focalPointRatio:Number):void {
		gradient.@gradientUnits = "userSpaceOnUse";
		if(type == GradientType.LINEAR) {
			gradient.@x1 = -819.2;
			gradient.@x2 = 819.2;
		} else {
			gradient.@r = 819.2;
			gradient.@cx = 0;
			gradient.@cy = 0;
			if(focalPointRatio != 0) {
				gradient.@fx = 819.2 * focalPointRatio;
				gradient.@fy = 0;
			}
		}
		if(spreadMethod != SpreadMethod.PAD) { gradient.@spreadMethod = spreadMethod; }
		switch(spreadMethod) {
			case SpreadMethod.PAD: gradient.@spreadMethod = "pad"; break;
			case SpreadMethod.REFLECT: gradient.@spreadMethod = "reflect"; break;
			case SpreadMethod.REPEAT: gradient.@spreadMethod = "repeat"; break;
		}
		if(interpolationMethod == InterpolationMethod.LINEAR_RGB) { gradient.@["color-interpolation"] = "linearRGB"; }
		if(matrix) {
			var gradientValues:Array = [matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty];
			gradient.@gradientTransform = "matrix(" + gradientValues.join(" ") + ")";
		}
		for(var i:uint = 0; i < colors.length; i++) {
			var gradientEntry:XML = <stop offset={ratios[i] / 255} />
			if(colors[i] != 0) { gradientEntry.@["stop-color"] = toHex(colors[i]); }
			if(alphas[i] != 1) { gradientEntry.@["stop-opacity"] = alphas[i]; }
			gradient.appendChild(gradientEntry);
		}
	}
	
	private static function lineStyle(thickness:Number = NaN, color:uint = 0, alpha:Number = 1.0, pixelHinting:Boolean = false, scaleMode:String = LineScaleMode.NORMAL, startCaps:String = null, endCaps:String = null, joints:String = null, miterLimit:Number = 3):void {
		path.@fill = "none";
		path.@stroke = toHex(color);
		path.@["stroke-width"] = isNaN(thickness) ? 1 : thickness;
		if(alpha != 1) { path.@["stroke-opacity"] = alpha; }
		switch(startCaps) {
			case CapsStyle.NONE: path.@["stroke-linecap"] = "butt"; break;
			case CapsStyle.SQUARE: path.@["stroke-linecap"] = "square"; break;
			default: path.@["stroke-linecap"] = "round"; break;
		}
		switch(joints) {
			case JointStyle.BEVEL: path.@["stroke-linejoin"] = "bevel"; break;
			case JointStyle.ROUND: path.@["stroke-linejoin"] = "round"; break;
			default:
				path.@["stroke-linejoin"] = "miter";
				if(miterLimit >= 1 && miterLimit != 4) {
					path.@["stroke-miterlimit"] = miterLimit;
				}
				break;
		}
	}
	
	public static function finalizePath():void
	{
		if(path)
		{
			svg.s::g.appendChild(path);
		}
		path = <path />;
	}
}