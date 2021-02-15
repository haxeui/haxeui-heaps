package haxe.ui.backend;

class ImageDisplayImpl extends ImageBase {
    public var sprite:h2d.Bitmap;

    public function new() {
        super();
        sprite = new h2d.Bitmap();
    }

    private override function validateData() {
        if (_imageInfo != null) {
            sprite.tile = h2d.Tile.fromBitmap(_imageInfo.data);
        } else {
            sprite.tile.dispose();
            sprite.tile = null;
        }
    }

    private override function validatePosition() {
        if (sprite.x != _left) {
            sprite.x = _left;
        }

        if (sprite.y != _top) {
            sprite.y = _top;
        }
    }

    private override function validateDisplay() {
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
        }
    }
    
    public override function dispose() {
        if (sprite.tile != null) {
            sprite.tile.dispose();
            sprite.tile = null;
        }
    }
}