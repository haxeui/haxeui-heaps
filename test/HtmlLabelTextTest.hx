import haxe.ui.backend.heaps.HtmlFaces;
import haxe.ui.backend.heaps.HtmlFonts;
import haxe.ui.backend.heaps.HtmlLabelText;

/**
 * Headless checks of HtmlLabelText: link numbering, link areas and face fallback. No GPU is
 * needed - the font is built by hand from empty tiles, every glyph 6 wide on a 12 line - so
 * nothing here says how the text LOOKS, only where heaps lays it out.
 */
@:access(h2d.Font) @:access(h2d.Tile)
class HtmlLabelTextTest {
    static var count:Int = 0;
    static var failures:Int = 0;

    static function eq(actual:Dynamic, expected:Dynamic, what:String) {
        count++;
        if (Std.string(actual) != Std.string(expected)) {
            failures++;
            Sys.println("FAIL #" + count + " " + what);
            Sys.println("  expected: " + expected);
            Sys.println("  actual:   " + actual);
        }
    }

    static inline var ADVANCE = 6;
    static inline var LINE = 12;

    static function testFont():h2d.Font {
        var font = new h2d.Font("test", 10);
        font.lineHeight = LINE;
        font.baseLine = 10;
        font.tile = new h2d.Tile(null, 0, 0, 0, 0);
        for (code in 32...127) {
            font.glyphs.set(code, new h2d.Font.FontChar(new h2d.Tile(null, 0, 0, ADVANCE, 10), ADVANCE));
        }
        return font;
    }

    static function interactives(t:h2d.Object):Int {
        var n = 0;
        for (i in 0...t.numChildren) {
            if (Std.isOfType(t.getChildAt(i), h2d.Interactive)) {
                n++;
            }
        }
        return n;
    }

    // the areas come from layout, which heaps does when the text is drawn or measured
    static function rects(t:HtmlLabelText):String {
        var laidOut = t.textWidth;
        return [for (r in t.linkRects) '${r.index}:${r.x},${r.y},${r.width},${r.height}'].join(" ");
    }

    static function main() {
        var font = testFont();

        // two links to the same address stay two links, numbered in order; one inside bold
        var t = new HtmlLabelText(font);
        t.text = HtmlFaces.normalize('see <a href="https://a.test/?x=1&amp;y=2">one</a> and <b><a href="https://a.test/?x=1&amp;y=2">two</a></b>');
        eq(t.linkHrefs.join("|"), "https://a.test/?x=1&y=2|https://a.test/?x=1&y=2", "hrefs, decoded, in order");
        eq(t.textWidth, 15 * ADVANCE, "width of the whole line (bold falls back to the label font)");
        eq(rects(t), '0:${4 * ADVANCE},0,${3 * ADVANCE},$LINE 1:${12 * ADVANCE},0,${3 * ADVANCE},$LINE', "one area per link");
        eq(interactives(t), 0, "heaps' link Interactives are removed");
        eq(t.linkAt(4 * ADVANCE + 1, 5), 0, "point on the first link");
        eq(t.linkAt(12 * ADVANCE + 1, 5), 1, "point on the second link");
        eq(t.linkAt(9 * ADVANCE, 5), -1, "point between the links");
        eq(t.linkAt(4 * ADVANCE + 1, LINE + 1), -1, "point below the line");

        // a link broken over two lines has an area on each, both its own index
        var w = new HtmlLabelText(font);
        w.text = HtmlFaces.normalize('ab <a href="u">cd\nef</a> gh');
        eq(rects(w), '0:${3 * ADVANCE},0,${2 * ADVANCE},$LINE 0:0,$LINE,${2 * ADVANCE},$LINE', "newline inside a link (whitespace kept)");
        eq(w.linkAt(1, LINE + 2), 0, "second line of the link");

        // word wrap inside a link
        var wrap = new HtmlLabelText(font);
        wrap.lineBreak = true;
        wrap.maxWidth = 8 * ADVANCE;
        wrap.text = HtmlFaces.normalize('xx <a href="v">aaaa bbbb</a>');
        eq(wrap.linkHrefs.length, 1, "one link");
        eq(rects(wrap).split(" ").length, 2, "wrapped link has two areas");
        eq(wrap.linkRects.length > 1 ? wrap.linkRects[1].y : -1, LINE, "second area on the second line");

        // layout of other text (calcTextWidth) leaves this text's links alone
        var before = rects(t);
        t.calcTextWidth('<a href="other">zzzz</a>');
        eq(t.linkHrefs.length, 2, "calcTextWidth keeps the hrefs");
        eq(rects(t), before, "calcTextWidth keeps the areas");
        eq(interactives(t), 0, "and leaves no Interactive behind");

        // changing the text replaces the links
        t.text = HtmlFaces.normalize("no links <i>here</i>");
        eq(t.linkHrefs.length, 0, "no hrefs");
        eq(t.linkAt(1, 1), -1, "no areas after the text changed");

        // not XML: shown as typed, nothing thrown
        t.text = HtmlFaces.normalize('<a href="x">unclosed');
        eq(t.linkHrefs.length, 0, "non-XML has no links");
        eq(t.textWidth, '<a href="x">unclosed'.length * ADVANCE, "non-XML drawn as typed");

        // faces: nothing registered, or a resource that cannot be loaded, is the label's own font
        eq(t.loadFont("bold") == t.font, true, "unregistered face");
        eq(t.loadFont("nonsense") == t.font, true, "unknown face");
        HtmlFonts.register("italic", "fonts/does-not-exist.fnt");
        eq(t.loadFont("italic") == t.font, true, "face that fails to load");
        eq(t.loadFont("italic") == t.font, true, "and again, without retrying");

        // plain h2d.Text defaults
        eq(t.condenseWhite, false, "whitespace kept as in h2d.Text");
        eq(t.textColor, 0xFFFFFF, "colour default as in h2d.Text");

        Sys.println(count + " assertions, " + failures + " failed");
        Sys.exit(failures == 0 ? 0 : 1);
    }
}
