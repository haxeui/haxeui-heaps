package haxe.ui.backend;

class TimerImpl {
    static private var __timers:Array<TimerImpl> = [];

    static public function update() {
        if (__timers.length == 0) {
            return;
        }

        var currentTime:Float = hxd.Timer.lastTimeStamp;

        // Walk a COPY of the list. A timer callback is arbitrary application
        // code: it can add timers, stop timers, or re-enter update() itself
        // (a callback that rebuilds part of a UI commonly ends up pumping the
        // backend again), and each of those mutates __timers underneath this
        // loop. Indexing the live array here meant a callback that shortened
        // it left the remaining indices pointing at the wrong timer, or past
        // the end of the array entirely.
        var timers:Array<TimerImpl> = __timers.copy();
        for (timer in timers) {
            if (timer._stopped) {
                continue;
            }
            if (currentTime >= timer._end) {
                timer._end = currentTime + timer._delay;
                if (timer.callback != null) {
                    timer.callback();
                }
            }
        }

        // Sweep the stopped timers off the LIVE list, taking its length HERE
        // rather than reusing the one measured before the callbacks ran. That
        // stale length was the crash: a callback that re-entered update()
        // removed the stopped timers itself, and the outer sweep then indexed
        // past the end of a now-shorter array and dereferenced null
        // ("Null access ._stopped").
        var i:Int = __timers.length;
        while (--i >= 0) {
            if (__timers[i]._stopped) {
                __timers.splice(i, 1);
            }
        }
    }

    public var callback:Void->Void = null;
    private var _end:Float;
    private var _delay:Float;
    // Explicitly false: on dynamic targets an uninitialised Bool reads null,
    // and every test here is on the un-negated value.
    private var _stopped:Bool = false;

    public function new(delay:Int, callback:Void->Void) {
        this.callback = callback;
        _delay = delay / 1000;
        _end = hxd.Timer.lastTimeStamp + _delay;
        __timers.push(this);
    }

    public function stop() {
        callback = null;
        _stopped = true;
    }
}