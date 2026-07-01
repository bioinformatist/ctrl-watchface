using Toybox.Application;
using Toybox.WatchUi;

class CtrlWatchfaceApp extends Application.AppBase {
    function getInitialView() {
        return [ new CtrlWatchfaceView() ];
    }
}
