using Toybox.Application;
using Toybox.WatchUi;

class GravitasMasseApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new GravitasMasseView() ];
    }
}
