package haxe.ui.backend.heaps;

import h2d.Graphics;
import h2d.Interactive;
import h2d.Sprite;
import h2d.Tile;
import haxe.ui.util.Rectangle;
import hxd.Cursor;

class UISprite extends Graphics
{
    public var width(get, set):Float;
    public var height(get, set):Float;
    public var interactive(default, set):Bool = false;
    public var interactiveObj(default, null):Interactive;
    public var clipRect:Rectangle;
    public var cursor(default, set):Cursor = Cursor.Default;

    private var backgroundTile:Tile;
    private var backgroundX:Int = 0;
    private var backgroundY:Int = 0;

    private var _width:Float = 0;
    private function set_width(value:Float):Float {
        if (_width != value) {
            _width = value;

            if (interactiveObj != null) {
                interactiveObj.width = value;
            }
        }

        return value;
    }
    private function get_width():Float {
        return _width;
    }

    private var _height:Float = 0;
    private function set_height(value:Float):Float {
        if (_height != value) {
            _height = value;

            if (interactiveObj != null) {
                interactiveObj.height = value;
            }
        }

        return value;
    }
    private function get_height():Float {
        return _height;
    }

    private function set_interactive(value:Bool):Bool {
        if (interactive != value) {
            interactive = value;
            checkInteraction();
        }

        return value;
    }

    private function set_cursor(value:Cursor):Cursor {
        if (cursor != value) {
            cursor = value;
            checkInteraction();
        }

        return value;
    }

    public function new(parent:Sprite) {
        super(parent);
    }

    public function hasFocus():Bool {
        return interactiveObj != null && interactiveObj.hasFocus();
    }

    public function focus() {
        if (interactiveObj != null) {
            interactiveObj.focus();
        }
    }

    public inline function setBackground(tile:Tile=null, x:Int=0, y=0)
    {
        backgroundTile = tile;
        backgroundX = x;
        backgroundY = y;
    }

    override function getBoundsRec(relativeTo, out:h2d.col.Bounds, forSize) {
        if (clipRect != null) {
            var xMin = out.xMin, yMin = out.yMin, xMax = out.xMax, yMax = out.yMax;
            out.empty();
            if( posChanged ) {
                calcAbsPos();
                for( c in children )
                    c.posChanged = true;
                posChanged = false;
            }
            addBounds(relativeTo, out, clipRect.left, clipRect.top, clipRect.width, clipRect.height);
            var bxMin = out.xMin, byMin = out.yMin, bxMax = out.xMax, byMax = out.yMax;
            out.xMin = xMin;
            out.xMax = xMax;
            out.yMin = yMin;
            out.yMax = yMax;
            super.getBoundsRec(relativeTo, out, forSize);
            if( out.xMin < bxMin ) out.xMin = hxd.Math.min(xMin, bxMin);
            if( out.yMin < byMin ) out.yMin = hxd.Math.min(yMin, byMin);
            if( out.xMax > bxMax ) out.xMax = hxd.Math.max(xMax, bxMax);
            if( out.yMax > byMax ) out.yMax = hxd.Math.max(yMax, byMax);
        }
        else {
            super.getBoundsRec(relativeTo, out, forSize);
            if (forSize) {
                addBounds(relativeTo, out, 0, 0, width, height);
            }
        }
    }

    override function drawRec(ctx : h2d.RenderContext) @:privateAccess {
        if( !visible ) return;

        if (clipRect != null) {
            var x1 = absX + clipRect.left;
            var y1 = absY + clipRect.top;

            var x2 = clipRect.width * matA + clipRect.height * matC + absX + clipRect.left;
            var y2 = clipRect.width * matB + clipRect.height * matD + absY + clipRect.top;

            var tmp;
            if (x1 > x2) {
                tmp = x1;
                x1 = x2;
                x2 = tmp;
            }

            if (y1 > y2) {
                tmp = y1;
                y1 = y2;
                y2 = tmp;
            }

            ctx.flush();
            if( ctx.hasRenderZone ) {
                var oldX = ctx.renderX, oldY = ctx.renderY, oldW = ctx.renderW, oldH = ctx.renderH;
                ctx.setRenderZone(x1, y1, x2-x1, y2-y1);
                super.drawRec(ctx);
                ctx.flush();
                ctx.setRenderZone(oldX, oldY, oldW, oldH);
            } else {
                ctx.setRenderZone(x1, y1, x2-x1, y2-y1);
                super.drawRec(ctx);
                ctx.flush();
                ctx.clearRenderZone();
            }
        } else {
            super.drawRec(ctx);
        }
    }

    override function calcAbsPos() {
        super.calcAbsPos();

        if (clipRect != null) {
            absX -= clipRect.left;
            absY -= clipRect.top;
        }
    }

    public function drawRoundRect(x:Float, y:Float, width:Float, height:Float) {

    }

    private function checkInteraction() {
        if (interactive || cursor != Cursor.Default) {
            if (interactiveObj == null) {
                interactiveObj = new Interactive(width, height, this);
                interactiveObj.propagateEvents = interactive;
            }
        } else if (interactiveObj == null) {
            interactiveObj.remove();
            interactiveObj = null;
        }
    }

    override function draw(ctx:h2d.RenderContext) {
        if (backgroundTile != null) {
            backgroundTile.dx += backgroundX;
            backgroundTile.dy += backgroundY;
            emitTile(ctx, backgroundTile);
            backgroundTile.dx -= backgroundX;
            backgroundTile.dy -= backgroundY;
        }

        super.draw(ctx);
    }
}
