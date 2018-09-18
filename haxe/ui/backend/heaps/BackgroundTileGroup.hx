package haxe.ui.backend.heaps;

import haxe.ui.util.Slice9;
import haxe.ui.util.Rectangle;
import h2d.Tile;

class BackgroundTileGroup implements IBackground {

    public var tile(default, set):Tile;
    public var slice(default, set):Rectangle;

    public var x(default, set):Int;
    public var y(default, set):Int;
    public var width(default, set):Int;
    public var height(default, set):Int;

    private function set_tile(value:Tile):Tile {
        if(tile != value) {
            _hasChanges = true;
            tile = value;
        }

        return value;
    }

    private function set_slice(value:Rectangle):Rectangle {
        if(slice == null
            || slice.left != value.left
            || slice.top != value.top
            || slice.width != value.width
            || slice.height != value.height) {
            _hasChanges = true;
            slice = value;
        }

        return value;
    }

    private function set_x(value:Int):Int {
        if(x != value) {
            _hasChanges = true;
            x = value;
        }

        return value;
    }

    private function set_y(value:Int):Int {
        if(y != value) {
            _hasChanges = true;
            y = value;
        }

        return value;
    }

    private function set_width(value:Int):Int {
        if(width != value) {
            _hasChanges = true;
            width = value;
        }

        return value;
    }

    private function set_height(value:Int):Int {
        if(height != value) {
            _hasChanges = true;
            height = value;
        }

        return value;
    }

    private var _backgrounds:Array<BackgroundTile>;
    private var _hasChanges:Bool = false;

    public function new(tile:Tile, slice:Rectangle, x:Int, y:Int, width:Int, height:Int) {
        _backgrounds = [];

        set(tile, slice, x, y, width, height);
    }

    public function set(tile:Tile, slice:Rectangle, x:Int, y:Int, width:Int, height:Int) {
        this.tile = tile;
        this.slice = slice;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    public function draw(sprite:h2d.Drawable, ctx:h2d.RenderContext) {
        if (_hasChanges) {
            _backgrounds.splice(0, _backgrounds.length);

            var rects:Slice9Rects = Slice9.buildRects(width, height, tile.width, tile.height, slice);
            var srcRects:Array<Rectangle> = rects.src;
            var dstRects:Array<Rectangle> = rects.dst;

            for (i in 0...srcRects.length) {
                var srcRect = srcRects[i];
                var dstRect = dstRects[i];
                var background:BackgroundTile = new BackgroundTile(
                    tile.sub(Std.int(srcRect.left), Std.int(srcRect.top), Std.int(srcRect.width), Std.int(srcRect.height)),
                    Std.int(dstRect.left), Std.int(dstRect.top), Std.int(dstRect.width), Std.int(dstRect.height));
                _backgrounds.push(background);
            }

            _hasChanges = false;
        }

        for (t in _backgrounds) {
            t.draw(sprite, ctx);
        }
    }
}
