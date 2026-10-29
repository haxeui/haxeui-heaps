package haxe.ui.backend;
import haxe.ui.Toolkit;
import haxe.ui.backend.heaps.VectorBitmapData;
import haxe.ui.backend.heaps.VectorSource;

class ImageDisplayImpl extends ImageBase {
    public var sprite:h2d.Bitmap;

    /** The displays holding a vector image, for refreshVectors. */
    static var liveVectors:Array<ImageDisplayImpl> = [];

    /** Renders every vector image on screen again at the size it is drawn: for when what they draw
        from has changed (an icon palette, say) while their size has not. */
    public static function refreshVectors() {
        for (d in liveVectors.copy()) d.syncVector(true);
    }

    public function new() {
        super();
        sprite = new ImageSprite(this);
    }

    /** The image has more pixels than it measures (a `name@4x.png`, see AssetsImpl): always scaled down. */
    private var _hiRes:Bool = false;

    /** A vector image's source (see VectorSource), and the pixel size of the tile it gave us. */
    private var _vector:VectorSource = null;
    private var _vectorW:Int = 0;
    private var _vectorH:Int = 0;

    private override function validateData() {
        releaseVector();
        // releaseVector only clears a vector's tile: a leftover PNG/@4x tile (this display's own,
        // never a vector's) is still here on any change of _imageInfo, including a vector taking a
        // PNG's place, so it is disposed here rather than by _vector.release().
        if (sprite.tile != null) {
            sprite.tile.dispose();
            sprite.tile = null;
        }
        if (_imageInfo != null) {
            var vector = Std.downcast(_imageInfo.data, VectorBitmapData);
            if (vector != null) {
                _hiRes = false;
                _vector = vector.source;
                liveVectors.push(this);
                syncVector(true);
                return;
            }
            var bmp = _imageInfo.data;
            _hiRes = bmp.width > _imageInfo.width;
            if (_hiRes) {
                // Mipmapped, so however far it is scaled down it is filtered from a level near the
                // size it is drawn at, rather than sampling a few of its pixels and aliasing.
                var tex = new h3d.mat.Texture(bmp.width, bmp.height, [MipMapped]);
                tex.uploadBitmap(bmp);
                tex.mipMap = Linear;
                sprite.tile = h2d.Tile.fromTexture(tex);
            } else {
                sprite.tile = h2d.Tile.fromBitmap(bmp);
            }
        }
        // _imageInfo == null: nothing to show, and the tile above already covers disposing any
        // leftover one.
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
        if (_vector != null) {
            syncVector(false);
            return;
        }
        if (sprite.tile != null) {
            var scaleX:Float = (_imageWidth / sprite.tile.width);
            if (sprite.scaleX != scaleX) {
                sprite.scaleX = scaleX;
            }

            var scaleY:Float = (_imageHeight / sprite.tile.height);
            if (sprite.scaleY != scaleY) {
                sprite.scaleY = scaleY;
            }

            // A plain image stays pixel-exact; a high-resolution one is filtered down to its size.
            sprite.smooth = _hiRes;
        }
    }

    /** Keeps a vector image's tile at the pixels it covers on screen. `_imageWidth` is in unscaled
        units: Toolkit.scale reaches the sprite as its ancestors' scale (the root components'), so
        that is read from the parent's absolute transform. The tile then lands one texel per pixel. */
    private function syncVector(force:Bool) {
        if (_vector == null) return;
        var sx = Toolkit.scaleX, sy = Toolkit.scaleY;
        if (sprite.parent != null) {
            // syncPos (rather than getAbsPos, which allocates a Matrix every call) brings the
            // parent's matA..matD up to date; they are h2d.Object's private absolute-transform
            // fields, read directly instead.
            @:privateAccess sprite.parent.syncPos();
            @:privateAccess sx = Math.sqrt(sprite.parent.matA * sprite.parent.matA + sprite.parent.matB * sprite.parent.matB);
            @:privateAccess sy = Math.sqrt(sprite.parent.matC * sprite.parent.matC + sprite.parent.matD * sprite.parent.matD);
        }
        var w = Math.round(_imageWidth * sx), h = Math.round(_imageHeight * sy);
        if (w < 1) w = 1;
        if (h < 1) h = 1;
        if (force || sprite.tile == null || w != _vectorW || h != _vectorH) {
            var old = sprite.tile;
            sprite.tile = _vector.acquire(w, h);
            if (old != null) _vector.release(old);
            _vectorW = w;
            _vectorH = h;
        }
        // Assigning scaleX/scaleY/smooth (even to their current value) marks the sprite's
        // posChanged, forcing calcAbsPos work on every synced frame: skip the ones unchanged.
        var scaleX = _imageWidth / w, scaleY = _imageHeight / h;
        if (sprite.scaleX != scaleX) sprite.scaleX = scaleX;
        if (sprite.scaleY != scaleY) sprite.scaleY = scaleY;
        if (sprite.smooth != false) sprite.smooth = false;
    }

    private function releaseVector() {
        if (_vector == null) return;
        if (sprite.tile != null) _vector.release(sprite.tile);
        sprite.tile = null;
        _vector = null;
        _vectorW = 0;
        _vectorH = 0;
        liveVectors.remove(this);
    }

    public override function dispose() {
        if (_vector != null) {
            releaseVector();
            return;
        }
        if (sprite.tile != null) {
            sprite.tile.dispose();
            sprite.tile = null;
        }
    }
}

/** The display's bitmap. For a vector image it checks the on-screen size each frame, so a change
    of Toolkit.scale re-renders without waiting for haxeui to revalidate the image. */
private class ImageSprite extends h2d.Bitmap {
    var owner:ImageDisplayImpl;

    public function new(owner:ImageDisplayImpl) {
        super();
        this.owner = owner;
    }

    override function sync(ctx:h2d.RenderContext) {
        super.sync(ctx);
        @:privateAccess owner.syncVector(false);
    }
}
