package haxe.ui.backend;

class BackendImpl {
    public static var id:String = "heaps";
    
    public static function update() {
        TimerImpl.update();
    }
}
