package haxe.ui.backend.heaps;

import h2d.Graphics;
import h2d.Interactive;
import h2d.Object;
import haxe.ui.util.Rectangle;
import hxd.Cursor;

class UISprite extends Graphics
{
    public var interactive(default, set):Bool = false;
    public var interactiveObj(default, null):Interactive;
    public var clipRect:Rectangle;
    public var cursor(default, set):Cursor = Cursor.Default;

    private var _backgrounds:Map<String, IBackground>;

    private var __width:Float = 0;
    private var __height:Float = 0;

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

    public function new(parent:Object) {
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

    public function addBackground(id:String, background:IBackground) {
        if (_backgrounds == null) {
            _backgrounds = new Map<String, IBackground>();
        }

        _backgrounds.set(id, background);
    }

    public function removeBackground(id:String) {
        if (_backgrounds != null) {
            _backgrounds.remove(id);
        }
    }

    public function removeAllBackground() {
        if (_backgrounds != null) {
            for(k in _backgrounds.keys()) {
                _backgrounds.remove(k);
            }
        }
    }

    public inline function getBackground(id:String):IBackground {
        return _backgrounds != null ? _backgrounds.get(id) : null;
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

    public function drawRoundRect(x:Float, y:Float, width:Float, height:Float, radius:Float) {
        flush();

        var angleStart:Float = 0;
        var angleLength:Float = Math.PI / 2;
        var nsegments:Int = Math.ceil(Math.abs(radius * angleLength / 4));
        if( nsegments < 3 ) nsegments = 3;
        var angle = angleLength / (nsegments - 1);

        if (radius > width/2) {
            radius = width/2;
        }
        if (radius > height/2) {
            radius = height/2;
        }

        radius = Math.floor(radius / 2);

        var insetX:Float = x + radius;
        var insetY:Float = y + radius;
        var insetW:Float = width - 2 * radius;
        var insetH:Float = height - 2 * radius;

        inline function drawArc(x:Float, y:Float, aStart:Float) {
            for( i in 1...nsegments ) {
                var a = i * angle + aStart;
                lineTo(x + Math.cos(a) * radius, y + Math.sin(a) * radius);
            }
        }

        moveTo(insetX, y);
        lineTo(insetX + insetW, y);
        drawArc(insetX + insetW, insetY, -Math.PI/2);

        lineTo(x + width, insetY + insetH);
        drawArc(insetX + insetW, insetY + insetH, 0);

        lineTo(insetX, y + height);
        drawArc(insetX, insetY + insetH, Math.PI/2);

        lineTo(x, insetY);
        drawArc(insetX, insetY, -Math.PI);

        flush();
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

    override function draw(ctx:h2d.RenderContext) {
        if (_backgrounds != null) {
            for(background in _backgrounds) {
                background.draw(this, ctx);
            }
        }

        super.draw(ctx);
    }
}
