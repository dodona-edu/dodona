import * as jQuery from "jquery";

const $ = jQuery;

export default class Drawer {
    $drawer: JQuery<HTMLElement>;
    $handle: JQuery<HTMLElement>;
    $toggle: JQuery<HTMLElement>;
    $background: JQuery<HTMLElement>;

    constructor(toggleSelector = ".drawer-toggle",
                drawerSelector = "#drawer",
                handleSelector = ".drawer-handle",
                backgroundSelector = ".drawer-background") {

        this.$drawer = $(drawerSelector);
        this.$handle = $(handleSelector);
        this.$toggle = $(toggleSelector);
        this.$background = $(backgroundSelector);

        this.$toggle.on('click', () => this.toggle());
        this.$handle.on('click', () => this.toggle());
        this.$background.on('click', () => this.hide());
    }

    toggle() {
        this.$drawer.toggleClass("active");
    }

    hide() {
        this.$drawer.removeClass("active");
    }
}

$(() => new Drawer());
