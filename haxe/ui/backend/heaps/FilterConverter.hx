package haxe.ui.backend.heaps;

import h2d.RenderContext;
import h2d.filter.Blur;
import h2d.filter.ColorMatrix;
import h2d.filter.Filter;
import h2d.filter.Glow;
import h3d.Matrix;
import h3d.mat.Pass;
import haxe.ui.filters.Saturate;
import haxe.ui.filters.Tint;
import haxe.ui.util.Color;

class FilterConverter {
    public static function convertFilter(input:haxe.ui.filters.Filter):Filter {
        if (input == null) {
            return null;
        }
        
        var output:Filter = null;
        
        if ((input is haxe.ui.filters.DropShadow)) {
            var inputDropShadow:haxe.ui.filters.DropShadow = cast(input, haxe.ui.filters.DropShadow);
            if (inputDropShadow.inner) { // TODO: temp
                return new h2d.filter.InnerGlow(inputDropShadow.color, .1, 1, 1);
            }
            var dropShadow = new h2d.filter.DropShadow(inputDropShadow.distance, 0.785, inputDropShadow.color, inputDropShadow.alpha * 2, 1, 1, 1, true);
            output = dropShadow;
        } else if ((input is haxe.ui.filters.BoxShadow)) {
            var inputDropShadow:haxe.ui.filters.BoxShadow = cast(input, haxe.ui.filters.BoxShadow);
            if (inputDropShadow.inset) { // TODO: temp
                return new h2d.filter.InnerGlow(inputDropShadow.color, .1, 1, 1);
            }
            var dropShadow = new BoxShadow(inputDropShadow.offsetX,inputDropShadow.offsetY, inputDropShadow.color, inputDropShadow.alpha, inputDropShadow.blurRadius, inputDropShadow.spreadRadius, false);
            output = dropShadow;
        } else if ((input is haxe.ui.filters.Tint)) {
            var inputTintFilter:haxe.ui.filters.Tint = cast(input, Tint);
            var cM = new ColorMatrix();
            var tintFilter = new TintFilter(inputTintFilter.color, inputTintFilter.amount);
            output = tintFilter;
        }  else if ((input is haxe.ui.filters.Blur)) {
            var inputBlur:haxe.ui.filters.Blur = cast(input, haxe.ui.filters.Blur);
            output = new Blur(inputBlur.amount); //  BlurFilter(inputBlur.amount, inputBlur.amount);
        } else if ((input is haxe.ui.filters.Grayscale)) {
            var inputGrayscale:haxe.ui.filters.Grayscale = cast(input, haxe.ui.filters.Grayscale);
            output = new GrayscaleFilter(inputGrayscale.amount / 100);
        } else if ((input is haxe.ui.filters.HueRotate)) {
            var inputHue:haxe.ui.filters.HueRotate = cast(input, haxe.ui.filters.HueRotate);
            var cM = new ColorMatrix();
            cM.matrix.colorHue(inputHue.angleDegree);
            output = cM;
        } else if ((input is haxe.ui.filters.Contrast)) {
            var contrast:haxe.ui.filters.Contrast = cast(input, haxe.ui.filters.Contrast);
            var cM = new ColorMatrix();
            cM.matrix.colorContrast(contrast.multiplier);
            output = cM;
        } else if ((input is haxe.ui.filters.Saturate)) {
            var saturate:haxe.ui.filters.Saturate = cast(input, Saturate);
            var cM = new ColorMatrix();
            cM.matrix.colorSaturate(saturate.multiplier);
            output = cM;
        } else if ((input is haxe.ui.filters.Invert)) {
            var inputInvert:haxe.ui.filters.Invert = cast(input, haxe.ui.filters.Invert);
            output = new InvertFilter(inputInvert.multiplier);
        } else if ((input is haxe.ui.filters.Brightness)) {
            var inputBrightness:haxe.ui.filters.Brightness = cast(input, haxe.ui.filters.Brightness);
            output = new BrightnessFilter(inputBrightness.multiplier);
        }
        
        return output;
    }
}

class TintFilter extends ColorMatrix {
    
    //public var filter:ColorMatrix;

    // These numbers come from the CIE XYZ Color Model
    public static inline var LUMA_R = 0.212671;
    public static inline var LUMA_G = 0.71516;
    public static inline var LUMA_B = 0.072169;
    
    public function new(color:Int = 0, amount:Float = 1) {

        var color:Color = cast color;

        var r:Float = color.r / 255;
        var g:Float = color.g / 255;
        var b:Float = color.b / 255;
        var q:Float = 1 - amount;

        var rA:Float = amount * r;
        var gA:Float = amount * g;
        var bA:Float = amount * b;
        
        var m = new Matrix();
        m.zero();

        m._11 = q + rA * LUMA_R;
        m._12 = gA * LUMA_R;
        m._13 = bA * LUMA_R;
        m._21 = rA * LUMA_G;
        m._22 = q + gA * LUMA_G;
        m._23 = bA * LUMA_G;
        m._31 = rA * LUMA_B;
        m._32 = gA * LUMA_B;
        m._33 = q + bA * LUMA_B;
        m._44 = 1;

        super(m);
    }
}

class GrayscaleFilter extends ColorMatrix {
    /**
     * Color multipliers recommended by the ITU to make the result appear to the
     * human eye to have the correct brightness. See page 3 of the article at
     * http://www.itu.int/rec/R-REC-BT.601-7-201103-I/en for more information.
     */
    private static inline var RED:Float = 0.299;
    private static inline var GREEN:Float = 0.587;
    private static inline var BLUE:Float = 0.114;
    
    public function new(amount:Float = 1) {
        var m = new Matrix();
        m.zero();
        m._11 = 1 + (RED - 1) * amount;
        m._12 = RED * amount;
        m._13 = RED * amount;
        m._21 = GREEN * amount;
        m._22 = 1 + (GREEN - 1) * amount;
        m._23 = GREEN * amount;
        m._31 = BLUE * amount;
        m._32 = BLUE * amount;
        m._33 = 1 + (BLUE - 1) * amount;
        m._44 = 1;

        super(m);
    }
}

class InvertFilter extends ColorMatrix {
    public function new(multiplier:Float = 1) {
        var m = new Matrix();
        m.zero();
        m._11 = -1 * multiplier;
        m._22 = -1 * multiplier;
        m._33 = -1 * multiplier;
        m._41 = 1;
        m._42 = 1;
        m._43 = 1;
        m._44 = 1;
        super(m);
    }
}

class BrightnessFilter extends ColorMatrix { 
    public function new(multiplier:Float = 1) {
        // In html, 0 is a black image, 1 has no effect, over it's a multiplier
        // So we adapt
        if (multiplier <= 1) multiplier = (multiplier -1) * 1;
        if (multiplier > 1) multiplier = (multiplier -1) * 110/255;

        var m = new Matrix();
        m.identity();
        m._41 = multiplier;
        m._42 = multiplier;
        m._43 = multiplier;
        super(m);
    }
}

class BoxShadow extends Glow {
    
    public var offsetX:Float = 0;
    public var offsetY:Float = 0;
    public var spreadRadius:Float = 0;

	var alphaPass = new h3d.mat.Pass("");
    var sizePass = new h3d.mat.Pass("");

	/**
		Create a new Shadow filter.
		@param distance The offset of the shadow in the `angle` direction.
		@param angle Shadow offset direction angle.
		@param color The color of the shadow.
		@param alpha Transparency value of the shadow.
		@param radius The shadow glow distance in pixels.
		@param gain The shadow color intensity.
		@param quality The sample count on each pixel as a tradeoff of speed/quality.
		@param smoothColor Produce gradient shadow when enabled, otherwise creates hard shadow without smoothing.
	**/
	public function new( offsetX:Float = 4, offsetY:Float = 4, color : Int = 0, alpha = 1., blurRadius : Float = 1., spreadRadius : Float = 1., inset:Bool ) {
		super(color, alpha, blurRadius, 1, 1, true);
		this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.spreadRadius = spreadRadius;
		alphaPass.addShader(new h3d.shader.UVDelta());
        sizePass.addShader(new h3d.shader.UVDelta());
	}

	override function sync(ctx, s) {
		super.sync(ctx, s);
		boundsExtend += Math.max(Math.abs(offsetX + spreadRadius), Math.abs(offsetY + spreadRadius));
	}

	override function draw( ctx : h3d.impl.RenderContext, t : h2d.Tile ) {
		setParams();

		var save = ctx.textures.allocTileTarget("glowSave", t);
        var perW = spreadRadius/t.width;
        var perH = spreadRadius/t.height;
        sizePass.getShader(h3d.shader.UVDelta).uvScale.set(1/(1+perW), 1/(1+perH));
        
	    h3d.pass.Copy.run(t.getTexture(), save, sizePass);
        
		pass.apply(ctx, save);
		alphaPass.getShader(h3d.shader.UVDelta).uvDelta.set(offsetX/t.width, offsetY/t.height);
		h3d.pass.Copy.run(t.getTexture(), save, Alpha, alphaPass);
		var ret = h2d.Tile.fromTexture(save);
		ret.dx = offsetX;
		ret.dy = offsetY;
        
		return ret;
	}
}