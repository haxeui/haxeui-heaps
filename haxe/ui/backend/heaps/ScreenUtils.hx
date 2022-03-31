package haxe.ui.backend.heaps;

class ScreenUtils {
    private static var _dpi:Float = 0;
    public static var dpi(get, null):Float;
    private static function get_dpi():Float {
        #if js
        
        if (_dpi != 0) {
            return _dpi;
        }

        var div = js.Browser.document.createElement("div");
        div.style.width = "1in";
        div.style.height = "1in";
        div.style.position = "absolute";
        div.style.top = "-99999px"; // position off-screen!
        div.style.left = "-99999px"; // position off-screen!
        js.Browser.document.body.appendChild(div);
        
        var devicePixelRatio:Null<Float> = js.Browser.window.devicePixelRatio;
        if (devicePixelRatio == null) {
            devicePixelRatio = 1;
        }
        
        _dpi = div.offsetWidth * devicePixelRatio;
        removeElement(div);
        return _dpi;
        
        #else
        
        return hxd.System.screenDPI;
        
        #end
    }
    
    private static var _isRetina:Null<Bool> = null;
    public static function isRetinaDisplay():Bool {
        #if js
        
        if (_isRetina == null) {
            var query = "(-webkit-min-device-pixel-ratio: 2), (min-device-pixel-ratio: 2), (min-resolution: 192dpi)";
            if (js.Browser.window.matchMedia(query).matches) {
                _isRetina = true;
            } else {
                _isRetina = false;
            }
        }
        return _isRetina;
        
        #else
        
        return false;
        
        #end
    }
    
    #if js
    private static function removeElement(el:js.html.Element) {
        // el.remove() - IE is crap
        if  (el != null && el.parentElement != null) {
            el.parentElement.removeChild(el);
        }
    }
    #end
}