package haxe.ui.backend.heaps;

/**
 * The `h2d.HtmlText` a label draws its `htmlText` with (see TextDisplayImpl).
 *
 * What it adds to heaps' own:
 *
 * - **Faces by name.** The markup arrives through `HtmlFaces.normalize`, so every styled run names
 *   one face (`bold`, `italic`, `bolditalic`); `loadFont` looks the face up in `HtmlFonts` and builds
 *   it at `deviceSize`. A face nobody registered is drawn in the label's own font.
 * - **Links as areas, not Interactives.** heaps puts an `h2d.Interactive` over every link, and an
 *   Interactive takes clicks however the component it sits in is clipped or scrolled - HaxeUI's
 *   mouse handling never hears of them. Each one is measured and removed again, and `linkRects`
 *   keeps where it was, for TextDisplayImpl to hit-test in HaxeUI's own events.
 *
 * Everything else is as plain `h2d.Text` draws a label: whitespace is kept as typed (a newline
 * breaks the line, as it does in a plain label) and the text colour defaults to white, until the
 * style sets it.
 */
class HtmlLabelText extends h2d.HtmlText {
    /**
        The pixel size fonts are BUILT at: the label's font size in device pixels, which is what its
        own font has been resized to (TextDisplayImpl.validateStyle). The faces are built at the same
        size so that they stand scaled down with the rest of the text, by the same factor.

        Set it BEFORE `font`: the rebuild that follows a new font loads the faces again, and loads them
        at whatever this says.
    **/
    public var deviceSize:Int = 12;

    /**
        The `href` of every link in the text, by its place in the text (0 is the first).

        Read when the text is parsed, which is as soon as it is set: the markup's own hrefs are
        swapped for these indexes on the way in, so that the link each area belongs to survives
        heaps' layout - two links to the same address stay two links.
    **/
    public var linkHrefs(default, null):Array<String> = [];

    /**
        Where the links were drawn by the last layout, in this text's own units (device pixels, from
        its own origin): one area for each line a link is on, `index` being its place in `linkHrefs`.
    **/
    public var linkRects(default, null):Array<{index:Int, x:Float, y:Float, width:Float, height:Float}> = [];

    // Faces by resource and size. Shared by every label: a face at a size is the same font wherever
    // it is drawn, and nothing here changes one once it is built.
    private static var _faces:Map<String, h2d.Font> = new Map<String, h2d.Font>();
    private static var _failed:Map<String, Bool> = new Map<String, Bool>();

    public function new(font:h2d.Font, ?parent:h2d.Object) {
        super(font, parent);
        condenseWhite = false;
    }

    /**
        The font for a face named in the markup: the resource `HtmlFonts` has for it, at `deviceSize`.
        A signed distance field font (one registered with `SDFFonts` under the same resource) is built
        at that size from its field; any other is a bitmap font, scaled to it.

        A face with no resource, or one that fails to load, is drawn in this text's own font - the
        style is lost, the words are not.
    **/
    public override dynamic function loadFont(name:String):h2d.Font {
        var resource = HtmlFonts.resource(name);
        if (resource == null || _failed.exists(resource)) {
            return font;
        }
        var size = (deviceSize < 1) ? 1 : deviceSize;
        var key = resource + "@" + size;
        var face = _faces.get(key);
        if (face != null) {
            return face;
        }
        try {
            var source = hxd.Res.loader.loadCache(resource, hxd.res.BitmapFont);
            var sdf = SDFFonts.get(resource);
            if (sdf != null) {
                // cached by heaps per size and parameters, and never changed here
                face = source.toSdfFont(size, sdf.channel, sdf.alphaCutoff, sdf.smoothing);
            } else {
                // toFont's instance is heaps' cached one: resize a copy. A bitmap font's size can be
                // negative (TextDisplayImpl.resizeFont), and resizeTo scales by the ratio of the two.
                var bitmap = source.toFont();
                face = bitmap.clone();
                face.resizeTo(bitmap.size < 0 ? -size : size);
            }
        } catch (e:Dynamic) {
            _failed.set(resource, true);
            trace('HtmlLabelText: could not load the "$name" face from $resource: $e');
            return font;
        }
        _faces.set(key, face);
        return face;
    }

    /** The link at a point in this text's own units (device pixels, from its origin), or -1. **/
    public function linkAt(x:Float, y:Float):Int {
        var width = textWidth; // lays the text out if it has changed since it was last drawn
        for (r in linkRects) {
            if (x >= r.x && x <= r.x + r.width && y >= r.y && y <= r.y + r.height) {
                return r.index;
            }
        }
        return -1;
    }

    // Every pass that parses the text - when it is set, and when it is laid out again - numbers the
    // links: each `<a href>` gets its place in the text for an href, and the real one is kept in
    // `linkHrefs`. heaps hands that href to the link's Interactive, which is how initGlyphs tells
    // which link an area belongs to.
    //
    // Only for the text this object shows: calcTextWidth lays out other text with the same
    // settings, and that must not replace these links with its own.
    private override function parseText(text:String):Xml {
        var doc = super.parseText(text);
        var hrefs:Array<String> = [];
        numberLinks(doc, hrefs);
        if (text == this.text) {
            linkHrefs = hrefs;
        }
        return doc;
    }

    private static function numberLinks(node:Xml, hrefs:Array<String>) {
        if (node.nodeType == Xml.Element && node.nodeName.toLowerCase() == "a" && node.exists("href")) {
            hrefs.push(node.get("href"));
            node.set("href", Std.string(hrefs.length - 1));
        }
        if (node.nodeType == Xml.Element || node.nodeType == Xml.Document) {
            for (child in node) {
                numberLinks(child, hrefs);
            }
        }
    }

    private override function initGlyphs(text:String, rebuild:Bool = true) {
        super.initGlyphs(text, rebuild);

        // heaps creates a link's Interactives on EVERY pass, rebuild or not, so every pass removes
        // them again. The href each one was given is its link's index (parseText), and its click
        // handler is the only place heaps keeps it: call that with onHyperlink caught.
        var rects = [];
        for (element in elements.copy()) {
            var area = Std.downcast(element, h2d.Interactive);
            if (area == null) {
                continue;
            }
            var href:String = null;
            var original = onHyperlink;
            onHyperlink = function(url:String) {
                href = url;
            }
            area.onClick(null);
            onHyperlink = original;

            var index = (href == null) ? null : Std.parseInt(href);
            // an area is opened at every line break inside a link, so one can end where it began
            if (index != null && area.width > 0) {
                // heaps makes it as tall as the line's baseline, which leaves out the descenders
                rects.push({index: index, x: area.x, y: area.y, width: area.width, height: Math.max(area.height, font.lineHeight)});
            }
            elements.remove(area);
            area.remove();
        }

        // A face drawn from a distance field needs linear sampling, which h2d.Text turns on for its
        // own font and HtmlText copies to each face's glyphs from this object. A label whose own font
        // is a bitmap one leaves it unset, and its bold run would be sampled nearest - jagged edges.
        for (element in elements) {
            var glyphGroup = Std.downcast(element, h2d.TileGroup);
            if (glyphGroup != null && glyphGroup.smooth == null && glyphGroup.getShader(h3d.shader.SignedDistanceField) != null) {
                glyphGroup.smooth = true;
            }
        }

        if (text == this.text) {
            linkRects = rects;
        }
    }
}
