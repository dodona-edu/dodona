export default class Drawer {
  constructor(toggleSelector =".drawer-toggle",
              drawerSelector ="#drawer") {
    this.$drawer = $(drawerSelector);
    this.$toggle = $(toggleSelector);

    this.$toggle.click(() => {
      this.$drawer.toggleClass("active");
    });
  }
}

$(() => new Drawer());
