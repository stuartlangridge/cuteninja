import QtQuick 2.9
import QtQuick.Controls 1.0
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0

Window {
    id : root
    width: Screen.width
    height: Screen.height
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput | Qt.X11BypassWindowManagerHint
    title: "Cute Ninja"
    color: Qt.rgba(0, 0, 0, 0)
    screen: Qt.application.screens[0]
    x: screen.virtualX
    y: screen.virtualY

    property var queue: [];
    property string ninja_state: "";
    property int ninja_screen_x: 1000;
    property int ninja_screen_y: 100;

    NumberAnimation {
        id: ninja_fall_anim; target: ninja_fall; property: "y"
        to: 0; from: 0; duration: 0
        onRunningChanged: {
            if (!running) {
                root.ninja_screen_x = ninja_fall.x;
                root.ninja_screen_y = ninja_fall.y;
                root.nextInQueue();
            }}}
    NumberAnimation {
        id: ninja_run_along_anim; target: ninja_run_along; property: "x"
        to: 0; from: 0; duration: 0
        onRunningChanged: {
            if (!running) {
                root.ninja_screen_x = ninja_run_along.x;
                root.ninja_screen_y = ninja_run_along.y;
                root.nextInQueue();
            }}}
    NumberAnimation {
        id: ninja_climb_anim; target: ninja_climb; property: "y"
        to: 0; from: 0; duration: 0
        onRunningChanged: {
            if (!running) {
                root.ninja_screen_x = ninja_climb.x;
                root.ninja_screen_y = ninja_climb.y;
                root.nextInQueue();
            }}}
    NumberAnimation {
        id: rope_grow_height_anim; target: rope; property: "height"
        to: 0; from: 0; duration: 500 }
    NumberAnimation {
        id: rope_y_anim; target: rope; property: "y"
        to: 0; from: 0; duration: 500
        onRunningChanged: { if (!running) { root.nextInQueue(); }}}


    Image {
        id: rope
        source: "rope.png"
        width: 32
        fillMode: Image.TileVertically
        visible: ninja_climb.visible || ninja_fire.visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: rope.flipped ? -1 : 1 }
    }

    AnimatedSprite {
        id: ninja_fall; source: "sprites.png"; frameX: 256; width: 32; height: 40
        frameCount: 1; frameWidth: 32; frameHeight: 40; frameRate: 1
        visible: root.ninja_state == "fall"; interpolate: false; running: visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: ninja_fall.flipped ? -1 : 1 }
    }
    AnimatedSprite {
        id: ninja_run_along; source: "sprites.png"; frameX: 32; width: 32; height: 40
        frameCount: 3; frameWidth: 32; frameHeight: 40; frameRate: 3 * 3
        visible: root.ninja_state == "run_along"; interpolate: false; running: visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: ninja_run_along.flipped ? -1 : 1 }
    }
    AnimatedSprite {
        id: ninja_stand; source: "sprites.png"; frameX: 0; width: 32; height: 40
        frameCount: 1; frameWidth: 32; frameHeight: 40; frameRate: 1
        visible: root.ninja_state == "stand"; interpolate: false; running: visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: ninja_stand.flipped ? -1 : 1 }
    }
    AnimatedSprite {
        id: ninja_climb; source: "sprites.png"; frameX: 128; width: 32; height: 40
        frameCount: 3; frameWidth: 32; frameHeight: 40; frameRate: 5
        visible: root.ninja_state == "climb"; interpolate: false; running: visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: ninja_climb.flipped ? -1 : 1 }
    }
    AnimatedSprite {
        id: ninja_reach; source: "sprites.png"; frameX: 224; width: 32; height: 40
        frameCount: 1; frameWidth: 32; frameHeight: 40; frameRate: 1
        visible: root.ninja_state == "reach"; interpolate: false; running: visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: ninja_reach.flipped ? -1 : 1 }
    }
    AnimatedSprite {
        id: ninja_fire; source: "sprites.png"; frameX: 0; frameY: 40; width: 32; height: 40
        frameCount: 2; frameWidth: 32; frameHeight: 40; frameRate: 6; loops: 1; // doesn't loop
        visible: root.ninja_state == "fire"; interpolate: false; running: visible
        property bool flipped: false; transform: Scale { origin.x: 16; xScale: ninja_fire.flipped ? -1 : 1 }
    }

    function fall() {
        ninja_fall.x = root.ninja_screen_x;
        ninja_fall.y = root.ninja_screen_y;

        // fall the length of the window
        ninja_fall_anim.to = root.height - 40; // sprite height
        ninja_fall_anim.from = root.ninja_screen_y;
        ninja_fall_anim.duration = 1000 * Math.abs(ninja_fall_anim.to - ninja_fall_anim.from) / 20 / 60 // 20px is one step
        ninja_fall_anim.start();
        console.log("fall");
    }
    function run_along() {
        ninja_run_along.x = root.ninja_screen_x;
        ninja_run_along.y = root.ninja_screen_y;

        // fall the length of the window
        var window_left = active_xwindow.x - root.screen.virtualX - 32;
        var window_right = active_xwindow.x - root.screen.virtualX + active_xwindow.w;
        if (ninja_run_along.x > window_right) {
            ninja_run_along_anim.to = window_right;
            ninja_run_along.flipped = true;
        } else if (ninja_run_along.x < window_left) {
            ninja_run_along_anim.to = window_left;
            ninja_run_along.flipped = false;
        } else {
            // we are between left and right of the window, so go left
            ninja_run_along_anim.to = window_left;
            ninja_run_along.flipped = true;
        }
        ninja_run_along_anim.from = ninja_run_along.x;
        ninja_run_along_anim.duration = 1000 * Math.abs(ninja_run_along_anim.to - ninja_run_along_anim.from) / 20 / 20 // 20px is one step
        ninja_run_along.flipped = ninja_run_along_anim.from > ninja_run_along_anim.to
        ninja_run_along_anim.start();
        console.log("run_along from", ninja_run_along_anim.from, "to", ninja_run_along_anim.to, ninja_run_along.flipped);
    }
    function climb() {
        ninja_climb.x = root.ninja_screen_x;
        ninja_climb.y = root.ninja_screen_y;

        var window_left = active_xwindow.x - root.screen.virtualX - 32;
        var window_right = active_xwindow.x - root.screen.virtualX + active_xwindow.w;
        if (ninja_climb.x <= window_left) {
            ninja_climb.flipped = true;
            rope.flipped = true;
        } else {
            ninja_climb.flipped = false;
            rope.flipped = false;
        }

        // climb to the right height
        ninja_climb_anim.to = active_xwindow.y - root.screen.virtualY - 40 - 28; // sprite height, window decs
        ninja_climb_anim.from = ninja_climb.y;
        ninja_climb_anim.duration = 1000 * Math.abs(ninja_climb_anim.to - ninja_climb_anim.from) / 20 / 6 // 20px is one step
        ninja_climb_anim.start();

        rope.x = ninja_climb.x
        rope.y = ninja_climb_anim.to + 40 // so it reaches only to the top of the window, not the top of the sprite above
        rope.height = root.screen.height - rope.y
        console.log("climb from", ninja_climb_anim.from, "to", ninja_climb_anim.to);
    }
    function fire() {
        ninja_fire.x = root.ninja_screen_x;
        ninja_fire.y = root.ninja_screen_y;

        var window_left = active_xwindow.x - root.screen.virtualX - 32;
        var window_right = active_xwindow.x - root.screen.virtualX + active_xwindow.w;
        if (ninja_climb.x <= window_left) {
            ninja_fire.flipped = true;
        } else {
            ninja_fire.flipped = false;
        }

        // rope grows to the right place
        var eventual_rope_length = root.screen.height - active_xwindow.y - root.screen.virtualY - 40 - 28 + 40 + 20; // the +20 is so the rope hangs into our sprite
        var eventual_rope_top = active_xwindow.y - root.screen.virtualY - 40 - 28 + 40;

        ninja_climb_anim.to = active_xwindow.y - root.screen.virtualY - 40 - 28; // sprite height, window decs
        ninja_climb_anim.from = ninja_climb.y;
        ninja_climb_anim.duration = 1000 * Math.abs(ninja_climb_anim.to - ninja_climb_anim.from) / 20 / 6 // 20px is one step
        ninja_climb_anim.start();

        rope.x = ninja_fire.x
        rope_grow_height_anim.to = eventual_rope_length;
        rope_grow_height_anim.from = 0;
        rope_y_anim.to = eventual_rope_top;
        rope_y_anim.from = eventual_rope_top + eventual_rope_length;
        rope_grow_height_anim.start();
        rope_y_anim.start();

        console.log("fire, rope y", rope_y_anim.from, "->", rope_y_anim.to,
            " height", rope_grow_height_anim.from, "->", rope_grow_height_anim.to);
    }
    function stand() {
        ninja_stand.x = root.ninja_screen_x;
        ninja_stand.y = root.ninja_screen_y;

        var window_left = active_xwindow.x - root.screen.virtualX - 32;
        var window_right = active_xwindow.x - root.screen.virtualX + active_xwindow.w;
        if (ninja_climb.x <= window_left) {
            ninja_stand.x += 40;
        } else {
            ninja_stand.x -= 40;
        }
        root.ninja_screen_x = ninja_stand.x;
        console.log("stand");
    }
    function nextInQueue() {
        if (root.queue.length == 0) {
            return;
        }
        var next_name = root.queue.shift();
        var next_fn = root[next_name];
        root.ninja_state = next_name;
        console.log("begin step", next_name);
        next_fn();
    }

    Connections {
        target: active_xwindow

        function window_change() {
            // work out if we need to change screens
            if (active_xwindow.wid != 0) {
                var screen_for_window = -1;
                for (var i=0; i<Qt.application.screens.length; i++) {
                    if (active_xwindow.x > Qt.application.screens[i].virtualX && 
                        active_xwindow.x < Qt.application.screens[i].virtualX + Qt.application.screens[i].width &&
                        active_xwindow.y > Qt.application.screens[i].virtualY && 
                        active_xwindow.y < Qt.application.screens[i].virtualY + Qt.application.screens[i].height) {
                        screen_for_window = i;
                    }
                }
                if (Qt.application.screens[screen_for_window] != root.screen) {
                    root.screen = Qt.application.screens[screen_for_window];
                }
            }

            if (active_xwindow.wid == 0) {
                // no window yet, so we're still in setup
            } else if (active_xwindow.y == root.y && active_xwindow.x == root.x) {
                console.log("no change");
            } else if (active_xwindow.x < root.ninja_screen_x && 
                       (active_xwindow.x + active_xwindow.width) > root.ninja_screen_x &&
                       active_xwindow.y > root.ninja_screen_y) {
                // fall from current position onto new window
            } else if (root.ninja_state == "fall") {
                // we're already falling, so don't do anything
                console.log("already falling");
            } else {
                // fall to base of screen, run along base, climb up to new window top, run around
                root.queue = ["fall", "run_along", "fire", "climb", "stand"];
                root.nextInQueue();
            }
        }

        onXChanged: window_change()
        onYChanged: window_change()
        onHChanged: window_change()
        onWChanged: window_change()
        onWidChanged: window_change()
    }

}