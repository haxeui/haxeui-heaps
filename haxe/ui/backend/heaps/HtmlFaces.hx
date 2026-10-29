package haxe.ui.backend.heaps;

/**
 * Rewrites bold and italic markup so every styled run names one combined font face.
 *
 * `h2d.HtmlText` handles `<b>` and `<i>` by loading the face "bold" or "italic", so italic is lost
 * inside bold (and the other way round). `normalize` turns `b`, `strong`, `i` and `em` into
 * `<font face="...">` where the face is `bold`, `italic` or `bolditalic`, whichever the surrounding
 * markup adds up to. All other tags and attributes are kept, comments are dropped (h2d.HtmlText would
 * show them as text). Void `<br>` tags are accepted and written as `<br/>`.
 *
 * Entities: `Xml.parse` decodes the standard ones (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#NN;`) and the
 * output encodes them again (`&`, `<`, `>` in text; `&`, `<`, `"` in attribute values), so the text
 * round trips. Names the parser does not know (`&nbsp;`) are not decoded and come out as `&amp;nbsp;`.
 *
 * Pure on purpose: nothing from heaps or HaxeUI is imported.
 */
class HtmlFaces {
    private static var _voidBr:EReg = ~/<br\s*>/gi;

    /**
     * Returns `markup` with `b`/`strong`/`i`/`em` replaced by `font` tags naming the combined face.
     * A void `<br>` (any case, optional spaces) is rewritten to `<br/>` before parsing.
     * Markup that is still not well formed is returned as plain text, with `&`, `<`, `>` and `"` escaped.
     * `null` gives `null`, an empty string gives an empty string.
     */
    public static function normalize(markup:String):String {
        if (markup == null) {
            return null;
        }
        var doc:Xml = null;
        try {
            doc = Xml.parse(_voidBr.replace(markup, "<br/>"));
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
        if (node.nodeType == Xml.Comment) {
            return;
        }
        if (node.nodeType != Xml.Element) {
            // text is encoded again by toString, other node types are passed through
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
        text = StringTools.replace(text, "&", "&amp;");
        text = StringTools.replace(text, "<", "&lt;");
        text = StringTools.replace(text, ">", "&gt;");
        return StringTools.replace(text, '"', "&quot;");
    }
}
