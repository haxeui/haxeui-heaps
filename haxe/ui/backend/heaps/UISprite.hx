package haxe.ui.backend.heaps;

import h2d.Drawable;
import h2d.Interactive;
import h2d.Sprite;
import haxe.ui.backend.heaps.shader.StyleShader;
import haxe.ui.geom.Rectangle;
import hxd.Cursor;

class UISprite extends Drawable
{
    static private var __styleTile:h2d.Tile;

    public var interactive(default, set):Bool = false;
    public var interactiveObj(default, null):Interactive;
    public var clipRect:Rectangle;
    public var cursor(default, set):Cursor = Cursor.Default;

    private var __width:Float = 0;
    private var __height:Float = 0;
    private var __hasStyleShader:Bool;

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
//            checkInteraction();   //FIXME - we can't create the interactive object because it creates problems with button for example
                                    //It dispatches the "out" event in the Button when the mouse is on the Label.
        }

        return value;
    }

    public function new(parent:Sprite) {
        super(parent);
    }

    public function setSize(w:Float, h:Float) {
        __width = w;
        __height = h;
        if (interactiveObj != null) {
            interactiveObj.width = w;
            interactiveObj.height = h;
        }
    }

    public function hasFocus():Bool {
        return interactiveObj != null && interactiveObj.hasFocus();
    }

    public function setFocus() {
        if (interactiveObj != null) {
            interactiveObj.focus();
        }
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
                addBounds(relativeTo, out, 0, 0, __width, __height);
            }
        }
    }

    override function calcAbsPos() {
        super.calcAbsPos();

        if (clipRect != null) {
            absX -= clipRect.left;
            absY -= clipRect.top;
        }
    }

    override function draw(ctx:h2d.RenderContext) {
        if (__hasStyleShader)
        {
            __styleTile.scaleToSize(Std.int(__width), Std.int(__height));
            emitTile(ctx, __styleTile);
        }
        super.draw(ctx);
    }

    override public function addShader<T:hxsl.Shader>( s : T ) : T {
        if (!__hasStyleShader && Std.is(s, StyleShader)) {
            __hasStyleShader = true;
            if(__styleTile == null)
                __styleTile = h2d.Tile.fromColor(0,1,1);
        }
        return super.addShader(s);
    }

    override public function removeShader( s : hxsl.Shader ) {
        if (__hasStyleShader && Std.is(s, StyleShader)) {
            __hasStyleShader = false;
        }
        return super.removeShader(s);
    }

    private function checkInteraction() {
        if (interactive || cursor != Cursor.Default) {
            if (interactiveObj == null) {
                interactiveObj = new Interactive(__width, __height, this);
                interactiveObj.propagateEvents = !interactive;
            }
        } else if (interactiveObj == null) {
            interactiveObj.remove();
            interactiveObj = null;
        }
    }

}
