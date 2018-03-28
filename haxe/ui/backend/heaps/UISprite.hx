package haxe.ui.backend.heaps;

import h2d.Interactive;
import h2d.Graphics;
import h2d.Sprite;

class UISprite extends Graphics
{
    public var width(default, set):Float = 0;
    public var height(default, set):Float = 0;
    public var interactive(default, set):Bool = false;
    public var interactiveObj(default, null):Interactive;

    private function set_width(value:Float):Float {
        if (width != value) {
            width = value;

            if (interactiveObj != null) {
                interactiveObj.width = value;
            }
        }

        return value;
    }

    private function set_height(value:Float):Float {
        if (height != value) {
            height = value;

            if (interactiveObj != null) {
                interactiveObj.height = value;
            }
        }

        return value;
    }

    private function set_interactive(value:Bool):Bool {
        if (interactive != value) {
            interactive = value;

            if (value) {
                interactiveObj = new Interactive(width, height, this);
                interactiveObj.propagateEvents = true;
            } else {
                interactiveObj.remove();
                interactiveObj = null;
            }
        }

        return value;
    }

    public function new(parent:Sprite) {
        super(parent);
    }

    override function getBoundsRec(relativeTo, out, forSize ) {
        super.getBoundsRec(relativeTo, out, forSize);
        if (forSize) {
            addBounds(relativeTo, out, 0, 0, width, height);
        }
    }

    public override function beginTileFill( ?dx : Float, ?dy : Float, ?scaleX : Float, ?scaleY : Float, ?tile : h2d.Tile ) {
        beginFill(0xFFFFFF);
        if( dx == null ) dx = 0;
        if( dy == null ) dy = 0;
        if( tile != null ) {
            if( this.tile != null && tile.getTexture() != this.tile.getTexture() ) {
                var tex = this.tile.getTexture();
//                if( tex.width != 1 || tex.height != 1 )   //TODO - original implementation??? :S Not working with our gradient system
//                    throw "All tiles must be of the same texture";
                this.tile = tile;
            }
            if( this.tile == null  )
                this.tile = tile;
        } else
            tile = this.tile;
        if( tile == null )
            throw "Tile not specified";
        if( scaleX == null ) scaleX = 1;
        if( scaleY == null ) scaleY = 1;
        dx -= tile.x;
        dy -= tile.y;

        var tex = tile.getTexture();
        var pixWidth = 1 / tex.width;
        var pixHeight = 1 / tex.height;
        ma = pixWidth / scaleX;
        mb = 0;
        mc = 0;
        md = pixHeight / scaleY;
        mx = -dx * ma;
        my = -dy * md;
    }

    public function drawRoundRect(x:Float, y:Float, width:Float, height:Float) {

    }
}
