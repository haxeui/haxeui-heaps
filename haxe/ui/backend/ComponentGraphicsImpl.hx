package haxe.ui.backend;

import h2d.Bitmap;
import h2d.Graphics;
import h2d.Tile;
import h3d.mat.Texture;
import haxe.io.Bytes;
import haxe.ui.core.Component;
import haxe.ui.util.Color;
import haxe.ui.util.Variant;
import hxd.PixelFormat;
import hxd.Pixels;

class ComponentGraphicsImpl extends ComponentGraphicsBase {
    private var _styleGraphics:Graphics = null;
    private var _hasSize:Bool = false;
    
    public function new(component:Component) {
        super(component);
        component.styleable = false;
        createGraphics();
    }
    
    public override function clear() {
        if (_hasSize == false) {
            return super.clear();
        }
        _styleGraphics.clear();
    }
    
    public override function setPixel(x:Float, y:Float, color:Color) {
        if (_hasSize == false) {
            return super.setPixel(x, y, color);
        }
    }
    
    private var _bitmap:Bitmap = null;
    private var _texture:Texture = null;
    public override function setPixels(pixels:Bytes) {
        if (_hasSize == false) {
            return super.setPixels(pixels);
        }

        if (_bitmap == null) {
            _bitmap = new Bitmap();
            _component.addChild(_bitmap);
        }
        
        var p = new Pixels(Std.int(_component.width), Std.int(_component.height), pixels, PixelFormat.RGBA);
        if (_texture == null) {
            _texture = Texture.fromPixels(p);
            _bitmap.tile = Tile.fromTexture(_texture);
        } else {
            if (_texture.width != _component.width || _texture.height != _component.height) {
                _texture.resize(Std.int(_component.width), Std.int(_component.height));
                _bitmap.tile = Tile.fromTexture(_texture); // To ensure size is correct.
            }
            _texture.uploadPixels(p);
        }
    }
    
    public override function moveTo(x:Float, y:Float) {
        if (_hasSize == false) {
            return super.moveTo(x, y);
        }
        _styleGraphics.moveTo(x, y);
    }
    
    public override function lineTo(x:Float, y:Float) {
        if (_hasSize == false) {
            return super.lineTo(x, y);
        }
        _styleGraphics.lineTo(x, y);
    }
    
    public override function strokeStyle( color:Null<Color>, thickness:Null<Float> = 1, alpha:Null<Float> = 1) {
        if (_hasSize == false) {
            return super.strokeStyle(color, thickness, alpha);
        }
        _styleGraphics.lineStyle(thickness, color, alpha);
    }
    
    public override function circle(x:Float, y:Float, radius:Float) {
        if (_hasSize == false) {
            return super.circle(x, y, radius);
        }
        _styleGraphics.drawCircle(x, y, radius, Std.int(radius * 10));
    }
    
    public override function fillStyle(color:Null<Color>, alpha:Null<Float> = 1) {
        if (_hasSize == false) {
            return super.fillStyle(color, alpha);
        }
        if (color == null) {
            _styleGraphics.endFill();
            return;
        }
        _styleGraphics.beginFill(color, alpha);
    }
    
    public override function curveTo(controlX:Float, controlY:Float, anchorX:Float, anchorY:Float) {
        if (_hasSize == false) {
            return super.curveTo(controlX, controlY, anchorX, anchorY);
        }
        _styleGraphics.curveTo(controlX, controlY, anchorX, anchorY);
    }
    
    public override function cubicCurveTo(controlX1:Float, controlY1:Float, controlX2:Float, controlY2:Float, anchorX:Float, anchorY:Float) {
        if (_hasSize == false) {
            return super.cubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY);
        }
        _styleGraphics.cubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY);
    }
    
    public override function rectangle(x:Float, y:Float, width:Float, height:Float) {
        if (_hasSize == false) {
            return super.rectangle(x, y, width, height);
        }
        _styleGraphics.drawRect(x, y, width, height);
    }
    
    public override function image(resource:Variant, x:Null<Float> = null, y:Null<Float> = null, width:Null<Float> = null, height:Null<Float> = null) {
        if (_hasSize == false) {
            return super.image(resource, x, y, width, height);
        }
    }
    
    private function createGraphics() {
        var container = _component.getChildAt(0); // first child is always the style-objects container
        if ( container == null ) {
            return; // fix crash resizing the window; container doesn't exist yet
        }
        
        if (container.numChildren == 0) {
            _styleGraphics = new Graphics();
            container.addChildAt(_styleGraphics, 0);
        } else {
            _styleGraphics = cast(container.getChildAt(0), Graphics);
        }
    }
    
    public override function resize(width:Null<Float>, height:Null<Float>) {
        if (width > 0 && height > 0) {
            if (_hasSize == false) {
                _hasSize = true;
                replayDrawCommands();
            }
        }
    }
}