import jQuery from "jquery";
const $ = jQuery;

export default class Drawer {
  constructor(toggleSelector = ".drawer-toggle",
              drawerSelector = "#drawer",
              mainSelector = "#main-container") {

    this.$drawer = $(drawerSelector);
    this.$toggle = $(toggleSelector);
    this.$main = $(mainSelector);

    this.$toggle.click(() => this.toggle());
  }

  toggle() {
    this.$drawer.toggleClass("active");
  }
}

$(() => new Drawer());
