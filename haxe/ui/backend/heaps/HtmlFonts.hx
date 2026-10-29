package haxe.ui.backend.heaps;

/**
 * Registry of the font resources behind the faces `HtmlFaces.normalize` produces.
 *
 * Faces are `"bold"`, `"italic"` and `"bolditalic"`; the resource is whatever the caller
 * later passes to heaps to load that face (for example a resource path).
 */
class HtmlFonts {
    private static var _faces:Map<String, String> = new Map<String, String>();

    /**
     * Registers (or replaces) the resource used for `face`.
     */
    public static function register(face:String, resource:String):Void {
        _faces.set(face, resource);
    }

    /**
     * Returns the resource registered for `face`, or null when there is none.
     */
    public static function resource(face:String):Null<String> {
        return _faces.get(face);
    }
}
