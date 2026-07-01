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
    const METRIC_RADIUS = 23;
    const ICON_HEART = 0;
    const ICON_STEPS = 1;
    const ICON_ENERGY = 2;
    const ICON_BATTERY = 3;

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
    var _frames = null;

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

    function onLayout(dc) {
        loadFrameResources();
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

    function onComplicationChanged(id as Complications.Id) as Void {
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

    function readComplication(id as Complications.Id) {
        try {
            var complication = Complications.getComplication(id);
            if (complication != null && complication.value != null) {
                return complication.value.toString();
            }
        } catch (ex) {
        }

        return "--";
    }

    function loadFrameResources() {
        if (_frames != null) {
            return;
        }

        _frames = [];
        for (var i = 0; i < FRAME_COUNT; i++) {
            _frames.add(WatchUi.loadResource(_frameResources[i]));
        }
    }

    function drawFace(dc, clock) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var originX = (dc.getWidth() - WIDTH) / 2;
        var originY = (dc.getHeight() - HEIGHT) / 2;

        drawTime(dc, clock, originX, originY);
        drawIkun(dc, originX, originY);
        drawMetrics(dc, originX, originY);
    }

    function drawTime(dc, clock, originX, originY) {
        var timeText = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateText = today.month.format("%02d") + "/" + today.day.format("%02d");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(originX + CENTER_X, originY + 18, Graphics.FONT_LARGE, timeText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(originX + CENTER_X, originY + 52, Graphics.FONT_XTINY, dateText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawIkun(dc, originX, originY) {
        loadFrameResources();
        dc.drawBitmap(originX + IMAGE_X, originY + IMAGE_Y, _frames[_frameIndex]);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(originX + CENTER_X, originY + IMAGE_Y + IMAGE_HEIGHT + 8, 3);
    }

    function drawMetrics(dc, originX, originY) {
        drawMetric(dc, originX + 56, originY + 104, ICON_HEART, _heartRate);
        drawMetric(dc, originX + 204, originY + 104, ICON_STEPS, _steps);
        drawMetric(dc, originX + 68, originY + 197, ICON_ENERGY, _bodyBattery);
        drawMetric(dc, originX + 192, originY + 197, ICON_BATTERY, _battery);
    }

    function drawMetric(dc, x, y, icon, value) {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, METRIC_RADIUS);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawMetricIcon(dc, x, y - 11, icon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + 2, Graphics.FONT_TINY, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawMetricIcon(dc, x, y, icon) {
        if (icon == ICON_HEART) {
            drawHeartIcon(dc, x, y);
        } else if (icon == ICON_STEPS) {
            drawStepsIcon(dc, x, y);
        } else if (icon == ICON_ENERGY) {
            drawEnergyIcon(dc, x, y);
        } else {
            drawBatteryIcon(dc, x, y);
        }
    }

    function drawHeartIcon(dc, x, y) {
        dc.fillCircle(x - 3, y - 2, 3);
        dc.fillCircle(x + 3, y - 2, 3);
        dc.fillPolygon([[x - 7, y - 1], [x + 7, y - 1], [x, y + 7]]);
    }

    function drawStepsIcon(dc, x, y) {
        drawFootIcon(dc, x - 5, y + 1);
        drawFootIcon(dc, x + 5, y - 2);
    }

    function drawEnergyIcon(dc, x, y) {
        dc.drawCircle(x - 2, y, 5);
        dc.fillCircle(x - 2, y, 2);
        dc.drawLine(x - 9, y, x - 7, y);
        dc.drawLine(x - 6, y - 6, x - 5, y - 4);
        dc.drawLine(x - 6, y + 6, x - 5, y + 4);
        dc.fillPolygon([[x + 4, y - 7], [x + 8, y - 7], [x + 6, y - 1],
            [x + 9, y - 1], [x + 3, y + 8], [x + 5, y + 2], [x + 2, y + 2]]);
    }

    function drawBatteryIcon(dc, x, y) {
        dc.drawRectangle(x - 8, y - 5, 14, 10);
        dc.fillRectangle(x + 7, y - 2, 2, 4);
        dc.fillRectangle(x - 5, y - 2, 7, 4);
    }

    function drawFootIcon(dc, x, y) {
        dc.fillCircle(x, y + 2, 3);
        dc.fillCircle(x - 2, y - 3, 1);
        dc.fillCircle(x, y - 4, 1);
        dc.fillCircle(x + 2, y - 3, 1);
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
            return stats.battery.format("%d");
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
