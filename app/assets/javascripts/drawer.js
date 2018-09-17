import jQuery from "jquery";
const $ = jQuery;

export default class Drawer {
  constructor(toggleSelector = ".drawer-toggle",
              drawerSelector = "#drawer",
              handleSelector = ".drawer-handle",
              backgroundSelector = ".drawer-background") {

    this.$drawer = $(drawerSelector);
    this.$handle = $(handleSelector);
    this.$toggle = $(toggleSelector);
    this.$background = $(backgroundSelector);

    this.$toggle.click(() => this.toggle());
    this.$handle.click(() => this.toggle());
    this.$background.click(() => this.hide());
  }

  toggle() {
    this.$drawer.toggleClass("active");
  }

  hide() {
    this.$drawer.removeClass("active");
  }
}

$(() => new Drawer());
