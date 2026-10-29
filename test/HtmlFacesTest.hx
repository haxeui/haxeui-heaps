import haxe.ui.backend.heaps.HtmlFaces;

class HtmlFacesTest {
    static var count:Int = 0;
    static var failures:Int = 0;

    static function eq(actual:String, expected:String) {
        count++;
        if (actual != expected) {
            failures++;
            Sys.println("FAIL #" + count);
            Sys.println("  expected: " + expected);
            Sys.println("  actual:   " + actual);
        }
    }

    static function main() {
        eq(HtmlFaces.normalize("<b>a</b>"), '<font face="bold">a</font>');
        eq(HtmlFaces.normalize("<b>a<i>b</i></b>"), '<font face="bold">a<font face="bolditalic">b</font></font>');
        eq(HtmlFaces.normalize("<em><strong>x</strong></em>"), '<font face="italic"><font face="bolditalic">x</font></font>');
        eq(HtmlFaces.normalize("a &amp; &lt;b&gt;"), "a &amp; &lt;b&gt;");
        eq(HtmlFaces.normalize('<a href="https://x.test/?a=1&amp;b=2"><font color="#2266CC">t</font></a>'),
           '<a href="https://x.test/?a=1&amp;b=2"><font color="#2266CC">t</font></a>');
        eq(HtmlFaces.normalize("<b>unclosed"), "&lt;b&gt;unclosed"); // not XML: shown as typed

        eq(HtmlFaces.normalize('<a title="say &quot;hi&quot;">x<br/></a>'), '<a title="say &quot;hi&quot;">x<br/></a>');
        eq(HtmlFaces.normalize("<b>a &amp; b</b>"), '<font face="bold">a &amp; b</font>');

        Sys.println(count + " assertions, " + failures + " failed");
        if (failures > 0) {
            Sys.exit(1);
        }
    }
}
