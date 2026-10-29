package haxe.ui.backend.heaps;

import h2d.Graphics;
import h2d.RenderContext;

/**
 * A component's background and borders (StyleHelper), drawn on the screen's pixel grid.
 *
 * Layout positions are whole layout units, but at a scale that is not a whole number they fall
 * between screen pixels (at 150% an odd x is 1.5 pixels in), and h2d.Graphics fills only the
 * pixels whose centres a shape covers. A 1px border is 1.5 pixels wide there, so it came out 1
 * pixel on one side of a box and 2 on the other, depending on where each of its edges fell.
 *
 * StyleHelper builds the shape at `builtScaleX`/`builtScaleY` with its size and borders in whole
 * screen pixels, and this draws it from a whole screen pixel, so every edge lands on a pixel
 * boundary and every side of a box is as thick as the others. The origin moves at most half a
 * pixel and only for the draw, as ComponentImpl.drawFilters moves a filter pass's, so a moving or
 * scrolled box needs no rebuild. A box whose screen scale is not the one it was built at (the app
 * scale changed, or it was built before it was in a scene) is built again when it is synced.
 */
class PixelGraphics extends Graphics {
    /** Screen pixels per unit of this object's own space when the shape was built. */
    public var builtScaleX:Float = 1;
    public var builtScaleY:Float = 1;
    /** Builds the shape again: StyleHelper.apply with the style and size it was last built from. */
    public var rebuild:Null<Void->Void> = null;

    /** Screen pixels per unit of `o`'s own space, from its ancestors' scales (its absolute matrix is stale until it is synced). */
    public static function screenScaleX(o:h2d.Object):Float {
        var s = 1.0;
        var p = o;
        while (p != null) {
            var scene = Std.downcast(p, h2d.Scene);
            s *= scene != null ? scene.viewportScaleX : p.scaleX;
            p = p.parent;
        }
        return Math.abs(s);
    }

    public static function screenScaleY(o:h2d.Object):Float {
        var s = 1.0;
        var p = o;
        while (p != null) {
            var scene = Std.downcast(p, h2d.Scene);
            s *= scene != null ? scene.viewportScaleY : p.scaleY;
            p = p.parent;
        }
        return Math.abs(s);
    }

    override function sync(ctx:RenderContext) {
        super.sync(ctx);
        if (rebuild == null || ctx.scene == null) {
            return;
        }
        var sx = Math.abs(matA * ctx.scene.viewportScaleX);
        var sy = Math.abs(matD * ctx.scene.viewportScaleY);
        if (Math.abs(sx - builtScaleX) > 1e-4 || Math.abs(sy - builtScaleY) > 1e-4) {
            rebuild();
            // super.sync has flushed the old shape already: this frame draws the new one.
            flush();
            content.flush();
        }
    }

    override function draw(ctx:RenderContext) {
        var ax = absX, ay = absY;
        var sx = ctx.scene != null ? ctx.scene.viewportScaleX : 1.0;
        var sy = ctx.scene != null ? ctx.scene.viewportScaleY : 1.0;
        absX = Math.round(ax * sx) / sx;
        absY = Math.round(ay * sy) / sy;
        super.draw(ctx);
        absX = ax;
        absY = ay;
    }
}
