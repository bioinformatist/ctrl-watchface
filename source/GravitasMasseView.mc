using Toybox.ActivityMonitor;
using Toybox.Complications;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class GravitasMasseView extends WatchUi.WatchFace {
    const WIDTH = 260;
    const HEIGHT = 260;
    const CENTER_X = 130;
    const IMAGE_X = 72;
    const IMAGE_Y = 77;
    const IMAGE_WIDTH = 116;
    const IMAGE_HEIGHT = 106;
    const FRAME_COUNT = 16;

    var _awake = true;
    var _frameIndex = 0;
    var _lastSecond = -1;
    var _heartRate = "--";
    var _bodyBattery = "--";
    var _steps = "--";
    var _battery = "--";
    var _lastMetricMinute = -1;
    var _heartRateId;
    var _bodyBatteryId;

    var _frameResources = [
        Rez.Drawables.IkunFrame00,
        Rez.Drawables.IkunFrame01,
        Rez.Drawables.IkunFrame02,
        Rez.Drawables.IkunFrame03,
        Rez.Drawables.IkunFrame04,
        Rez.Drawables.IkunFrame05,
        Rez.Drawables.IkunFrame06,
        Rez.Drawables.IkunFrame07,
        Rez.Drawables.IkunFrame08,
        Rez.Drawables.IkunFrame09,
        Rez.Drawables.IkunFrame10,
        Rez.Drawables.IkunFrame11,
        Rez.Drawables.IkunFrame12,
        Rez.Drawables.IkunFrame13,
        Rez.Drawables.IkunFrame14,
        Rez.Drawables.IkunFrame15
    ];

    function initialize() {
        WatchFace.initialize();
        _heartRateId = new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE);
        _bodyBatteryId = new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY);
        registerComplications();
    }

    function onUpdate(dc) {
        var clock = System.getClockTime();

        if (_awake && clock.sec != _lastSecond) {
            _frameIndex = (_frameIndex + 1) % FRAME_COUNT;
            _lastSecond = clock.sec;
        }

        refreshMinuteMetrics(clock);
        drawFace(dc, clock);
    }

    function onEnterSleep() {
        _awake = false;
    }

    function onExitSleep() {
        _awake = true;
        _lastSecond = -1;
        WatchUi.requestUpdate();
    }

    function onComplicationChanged(id) {
        refreshComplicationValues();
        WatchUi.requestUpdate();
    }

    function registerComplications() {
        try {
            Complications.registerComplicationChangeCallback(method(:onComplicationChanged));
            Complications.subscribeToUpdates(_heartRateId);
            Complications.subscribeToUpdates(_bodyBatteryId);
            refreshComplicationValues();
        } catch (ex) {
            _heartRate = "--";
            _bodyBattery = "--";
        }
    }

    function refreshComplicationValues() {
        _heartRate = readComplication(_heartRateId);
        _bodyBattery = readComplication(_bodyBatteryId);
    }

    function refreshMinuteMetrics(clock) {
        if (clock.min == _lastMetricMinute) {
            return;
        }

        _steps = readSteps();
        _battery = readBattery();
        _lastMetricMinute = clock.min;
    }

    function readComplication(id) {
        try {
            var complication = Complications.getComplication(id);
            if (complication != null && complication.value != null) {
                return complication.value.toString();
            }
        } catch (ex) {
        }

        return "--";
    }

    function drawFace(dc, clock) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawTime(dc, clock);
        drawIkun(dc);
        drawMetrics(dc);
    }

    function drawTime(dc, clock) {
        var timeText = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateText = today.month.format("%02d") + "/" + today.day.format("%02d");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CENTER_X, 18, Graphics.FONT_LARGE, timeText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(CENTER_X, 52, Graphics.FONT_XTINY, dateText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawIkun(dc) {
        var frame = WatchUi.loadResource(_frameResources[_frameIndex]);
        dc.drawBitmap(IMAGE_X, IMAGE_Y, frame);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(CENTER_X, IMAGE_Y + IMAGE_HEIGHT + 8, 3);
    }

    function drawMetrics(dc) {
        drawMetric(dc, 51, 104, "HR", _heartRate);
        drawMetric(dc, 209, 104, "STP", _steps);
        drawMetric(dc, 52, 211, "BB", _bodyBattery);
        drawMetric(dc, 208, 211, "BAT", _battery);
    }

    function drawMetric(dc, x, y, label, value) {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, 25);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - 15, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y + 1, Graphics.FONT_TINY, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function readSteps() {
        try {
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                return compactNumber(info.steps);
            }
        } catch (ex) {
        }

        return "--";
    }

    function readBattery() {
        try {
            var stats = System.getSystemStats();
            return stats.battery.format("%d") + "%";
        } catch (ex) {
        }

        return "--";
    }

    function compactNumber(value) {
        if (value >= 10000) {
            return (value / 1000).format("%d") + "k";
        }

        return value.format("%d");
    }
}
