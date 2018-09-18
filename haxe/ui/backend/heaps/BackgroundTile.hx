package haxe.ui.backend.heaps;

import h2d.Tile;

class BackgroundTile implements IBackground {
    public var tile:Tile;
    public var x:Int;
    public var y:Int;
    public var width:Int;
    public var height:Int;
    public var repeat:Bool;

    public function new(tile:Tile, x:Int, y:Int, width:Int, height:Int, repeat:Bool = false) {
        set(tile, x, y, width, height);
        this.repeat = repeat;
    }

    public inline function set(tile:Tile, x:Int, y:Int, width:Int, height:Int) {
        this.tile = tile;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    public inline function draw(sprite:h2d.Drawable, ctx:h2d.RenderContext) {
        var sizeFunc = repeat ? tile.setSize : tile.scaleToSize;
        sprite.tileWrap = repeat;

        var oldw:Int = tile.width;
        var oldh:Int = tile.height;
        tile.dx += x;
        tile.dy += y;
        sizeFunc(width, height);
        @:privateAccess sprite.emitTile(ctx, tile);
        sizeFunc(oldw, oldh);
        tile.dx -= x;
        tile.dy -= y;
    }
}
