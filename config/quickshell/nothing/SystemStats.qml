import QtQuick
import Quickshell
import Quickshell.Io

// CPU/RAM/GPU usage and CPU package temperature, sampled every 2s.
// Lives inside the control center, so nothing is polled while it's closed.
Scope {
    id: root

    property real cpu: 0 // 0..1
    property real ram: 0 // 0..1
    property real gpu: -1 // 0..1, -1 until nvtop reports
    property real cpuTemp: NaN // °C

    property var _lastCpu: null
    property string _tempPath: ""

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const fields = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = fields[3] + fields[4];
            const total = fields.reduce((a, b) => a + b, 0);
            if (root._lastCpu && total > root._lastCpu.total)
                root.cpu = 1 - (idle - root._lastCpu.idle) / (total - root._lastCpu.total);
            root._lastCpu = {
                total,
                idle
            };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const text = meminfo.text();
            const total = text.match(/MemTotal:\s+(\d+)/);
            const available = text.match(/MemAvailable:\s+(\d+)/);
            if (total && available)
                root.ram = 1 - Number(available[1]) / Number(total[1]);
        }
    }

    // coretemp's temp1 is "Package id 0"; hwmon numbering changes between boots, so look it up
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = coretemp ] && echo $h/temp1_input && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root._tempPath = text.trim()
        }
    }

    // loaded only once the path is known (a FileView with an empty path logs a warning)
    LazyLoader {
        id: tempFile
        active: root._tempPath !== ""

        FileView {
            id: temp
            path: root._tempPath
            onLoaded: root.cpuTemp = Number(temp.text()) / 1000
        }
    }

    // Intel iGPU has no busy-percent file; nvtop reads it from DRM fdinfo
    Process {
        id: nvtop
        command: ["nvtop", "-s"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const util = JSON.parse(text)[0].gpu_util;
                    if (util)
                        root.gpu = parseFloat(util) / 100;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            tempFile.item?.reload();
            if (!nvtop.running)
                nvtop.running = true;
        }
    }
}
