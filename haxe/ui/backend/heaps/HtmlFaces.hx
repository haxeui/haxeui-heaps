package haxe.ui.backend.heaps;

/**
 * Rewrites bold and italic markup so every styled run names one combined font face.
 *
 * `h2d.HtmlText` handles `<b>` and `<i>` by loading the face "bold" or "italic", so italic is lost
 * inside bold (and the other way round). `normalize` turns `b`, `strong`, `i` and `em` into
 * `<font face="...">` where the face is `bold`, `italic` or `bolditalic`, whichever the surrounding
 * markup adds up to. All other tags and attributes are kept as written, entities stay escaped.
 *
 * Pure on purpose: nothing from heaps or HaxeUI is imported.
 */
class HtmlFaces {
    /**
     * Returns `markup` with `b`/`strong`/`i`/`em` replaced by `font` tags naming the combined face.
     * Markup that is not well formed is returned as plain text, with `<` and `>` escaped.
     */
    public static function normalize(markup:String):String {
        if (markup == null) {
            return null;
        }
        var doc:Xml = null;
        try {
            doc = Xml.parse(markup);
        } catch (e:Dynamic) {
            return escape(markup);
        }
        var out = new StringBuf();
        writeChildren(doc, false, false, out);
        return out.toString();
    }

    private static function writeChildren(parent:Xml, bold:Bool, italic:Bool, out:StringBuf) {
        for (child in parent) {
            writeNode(child, bold, italic, out);
        }
    }

    private static function writeNode(node:Xml, bold:Bool, italic:Bool, out:StringBuf) {
        if (node.nodeType != Xml.Element) {
            // text keeps its entities as written, comments and the like are passed through
            out.add(node.toString());
            return;
        }

        var name = node.nodeName;
        var lower = name.toLowerCase();
        var isBold = (lower == "b" || lower == "strong");
        var isItalic = (lower == "i" || lower == "em");
        if (isBold || isItalic) {
            bold = bold || isBold;
            italic = italic || isItalic;
            out.add('<font face="${faceFor(bold, italic)}">');
            writeChildren(node, bold, italic, out);
            out.add("</font>");
            return;
        }

        out.add("<" + name);
        for (attr in node.attributes()) {
            out.add(" " + attr + '="' + escapeAttribute(node.get(attr)) + '"');
        }
        if (!node.iterator().hasNext()) {
            out.add("/>");
            return;
        }
        out.add(">");
        writeChildren(node, bold, italic, out);
        out.add("</" + name + ">");
    }

    private static function faceFor(bold:Bool, italic:Bool):String {
        return if (bold && italic) "bolditalic" else if (bold) "bold" else "italic";
    }

    // Xml.parse decodes entities in attribute values, so they are escaped again on the way out
    private static function escapeAttribute(value:String):String {
        value = StringTools.replace(value, "&", "&amp;");
        value = StringTools.replace(value, "<", "&lt;");
        return StringTools.replace(value, '"', "&quot;");
    }

    private static function escape(text:String):String {
        return StringTools.replace(StringTools.replace(text, "<", "&lt;"), ">", "&gt;");
    }
}
