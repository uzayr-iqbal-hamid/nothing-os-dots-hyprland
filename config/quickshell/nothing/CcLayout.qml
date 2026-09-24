pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Where each piece of the control center sits, on a grid of `columns` columns and rows of
// `rowHeight`. Every piece has a fixed span in cells; its position is set in edit mode (the pencil)
// and kept in the state dir. Pieces never overlap: whatever a moved piece lands on is pushed down,
// or swapped with it when both are the same size, and rows left empty are closed up.
Singleton {
    id: root

    readonly property int columns: 8
    readonly property int rowHeight: 44

    // key: [columns, rows]
    readonly property var spans: ({
            wifi: [6, 1],
            bluetooth: [6, 1],
            output: [6, 1],
            volume: [1, 3],
            brightness: [1, 3],
            nightLight: [1, 1],
            caffeine: [1, 1],
            mic: [1, 1],
            record: [1, 1],
            screenshot: [1, 1],
            colorPicker: [1, 1],
            lock: [1, 1],
            power: [1, 1],
            media: [8, 2],
            remote: [4, 4],
            glyph: [4, 1],
            timer: [4, 3]
        })

    // key: [column, row]
    readonly property var defaults: ({
            wifi: [0, 0],
            bluetooth: [0, 1],
            output: [0, 2],
            volume: [6, 0],
            brightness: [7, 0],
            nightLight: [0, 3],
            caffeine: [1, 3],
            mic: [2, 3],
            record: [3, 3],
            screenshot: [4, 3],
            colorPicker: [5, 3],
            lock: [6, 3],
            power: [7, 3],
            media: [0, 4],
            remote: [0, 6],
            glyph: [4, 6],
            timer: [4, 7]
        })

    readonly property var keys: Object.keys(spans)

    // saved positions, with defaults for anything not saved yet (e.g. a piece added later)
    readonly property var positions: {
        let saved = {};
        try {
            saved = store.grid ? JSON.parse(store.grid) : {};
        } catch (e) {}
        const out = {};
        for (const key of keys)
            out[key] = Array.isArray(saved[key]) ? saved[key] : defaults[key];
        return out;
    }

    function collides(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    // `heights` overrides row spans for pieces that change size (media, the remote's QR code)
    function items(heights) {
        return keys.map(key => ({
                    key: key,
                    x: positions[key][0],
                    y: positions[key][1],
                    w: spans[key][0],
                    h: heights?.[key] ?? spans[key][1]
                }));
    }

    // Place pieces in order (`first` before the rest, then top to bottom), each pushed down
    // until it overlaps nothing already placed.
    function resolve(list, first) {
        const order = list.slice().sort((a, b) => (a.key === first) ? -1 : (b.key === first) ? 1 : (a.y - b.y) || (a.x - b.x));
        const placed = [];
        for (const item of order) {
            const p = Object.assign({}, item);
            p.x = Math.max(0, Math.min(columns - p.w, p.x));
            p.y = Math.max(0, p.y);
            while (placed.some(q => root.collides(p, q)))
                p.y++;
            placed.push(p);
        }
        return placed;
    }

    // Close up rows that no piece covers.
    function collapse(list) {
        const used = new Set();
        for (const item of list)
            for (let r = item.y; r < item.y + item.h; r++)
                used.add(r);
        return list.map(item => {
            let empty = 0;
            for (let r = 0; r < item.y; r++)
                if (!used.has(r))
                    empty++;
            return Object.assign({}, item, {
                y: item.y - empty
            });
        });
    }

    // Move `key` to column x, row y: a same-size piece it lands on squarely takes its old place,
    // anything else it overlaps is pushed down.
    function moved(list, key, x, y) {
        const all = list.map(i => Object.assign({}, i));
        const piece = all.find(i => i.key === key);
        const from = {
            x: piece.x,
            y: piece.y
        };
        piece.x = Math.max(0, Math.min(columns - piece.w, x));
        piece.y = Math.max(0, y);
        const hits = all.filter(i => i !== piece && root.collides(piece, i));
        if (hits.length === 1 && hits[0].w === piece.w && hits[0].h === piece.h && hits[0].x === piece.x && hits[0].y === piece.y) {
            hits[0].x = from.x;
            hits[0].y = from.y;
        }
        return collapse(resolve(all, key));
    }

    // The layout to draw: { items: { key: {x, y, w, h} }, rows }. `preview` ({key, x, y}) shows
    // where things would go while a piece is being dragged.
    function arrange(heights, preview) {
        const list = preview ? moved(items(heights), preview.key, preview.x, preview.y) : collapse(resolve(items(heights), ""));
        const out = {};
        let rows = 0;
        for (const item of list) {
            out[item.key] = item;
            rows = Math.max(rows, item.y + item.h);
        }
        return {
            items: out,
            rows: rows
        };
    }

    // Drop: save the new arrangement (computed with the fixed spans, so it doesn't depend on
    // whether music was playing or the QR code was showing at the time).
    function move(key, x, y) {
        const out = {};
        for (const item of moved(items(null), key, x, y))
            out[item.key] = [item.x, item.y];
        store.grid = JSON.stringify(out);
    }

    function reset() {
        store.grid = "";
    }

    FileView {
        path: Quickshell.statePath("controlcenter.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store

            property string grid: "" // JSON: { key: [column, row] }
        }
    }
}
