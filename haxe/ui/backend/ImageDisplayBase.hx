package haxe.ui.backend;

import haxe.ui.core.Component;
import haxe.ui.assets.ImageInfo;
import haxe.ui.util.Rectangle;

class ImageDisplayBase {
    public var sprite:h2d.Bitmap;

    public var parentComponent:Component;

    private var _left:Float;
    private var _top:Float;
    private var _imageWidth:Float;
    private var _imageHeight:Float;
    private var _imageInfo:ImageInfo;
    private var _imageClipRect:Rectangle;
    
    public function new() {
        sprite = new h2d.Bitmap();
    }

    private function validateData() {
        
    }
    
    private function validateStyle():Bool {
        return false;
    }
    
    private function validatePosition() {
        
    }
    
    private function validateDisplay() {
        
    }
}
