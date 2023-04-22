package haxe.ui.backend.heaps;

class SDFFonts {
    private static var _sdfFonts:Map<String, {channel:h2d.Font.SDFChannel, alphaCutoff:Float, smoothing:Float}> = new Map<String, {channel:h2d.Font.SDFChannel, alphaCutoff:Float, smoothing:Float}>();
    public static function register(name:String, channel:h2d.Font.SDFChannel = 0, alphaCutoff:Float = 0.5, smoothing:Float = 0.5) {
        _sdfFonts.set(name, {
            channel: channel,
            alphaCutoff: alphaCutoff,
            smoothing: smoothing
        });
    }

    public static function get(name:String):{channel:h2d.Font.SDFChannel, alphaCutoff:Float, smoothing:Float} {
        return _sdfFonts.get(name);
    }
}