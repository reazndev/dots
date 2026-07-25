pragma Singleton
import QtQuick

QtObject {
    property var activeIsland: null

    property var _islands: []

    function _update() {
        if (_islands.length === 0) {
            activeIsland = null;
            return;
        }
        var sorted = _islands.slice().sort(function (a, b) {
            if (b.priority !== a.priority)
                return b.priority - a.priority;
            return b.timestamp - a.timestamp;
        });
        activeIsland = sorted[0];
    }

    function addIsland(type, priority, data) {
        removeIsland(type);
        _islands.push({
            type: type,
            priority: priority,
            data: data,
            timestamp: Date.now()
        });
        _update();
    }

    function removeIsland(type) {
        var idx = -1;
        for (var i = 0; i < _islands.length; i++) {
            if (_islands[i].type === type) {
                idx = i;
                break;
            }
        }
        if (idx !== -1) {
            _islands.splice(idx, 1);
            _update();
        }
    }
}
