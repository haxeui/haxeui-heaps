package haxe.ui.backend;

import haxe.ui.assets.ImageInfo;
import haxe.ui.core.Component;
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
        if (_imageInfo != null) {
            sprite.tile = h2d.Tile.fromBitmap(_imageInfo.data);
        }
    }

    private function validatePosition() {
        if (sprite.x != _left) {
            sprite.x = _left;
        }

        if (sprite.y != _top) {
            sprite.y = _top;
        }
    }

    private function validateDisplay() {
        if (sprite.tile != null) {
            var scaleX:Float = _imageWidth / sprite.tile.width;
            if (sprite.scaleX != scaleX) {
                sprite.scaleX = scaleX;
            }

            var scaleY:Float = _imageHeight / sprite.tile.height;
            if (sprite.scaleY != scaleY) {
                sprite.scaleY = scaleY;
            }

            sprite.smooth = scaleX != 1 || scaleY != 1;

            //TODO - imageClipRect
        }
    }
}
