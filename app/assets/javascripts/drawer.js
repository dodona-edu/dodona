const breakpoint_width = 1170;

export default class Drawer {
  constructor(toggleSelector = ".drawer-toggle",
              drawerSelector = "#drawer",
              mainSelector = "#main-container") {
    this.$drawer = $(drawerSelector);
    this.$toggle = $(toggleSelector);
    this.$main = $(mainSelector);

    if(localStorage.getItem("show_drawer") == null){
      localStorage.setItem("show_drawer", "true");
    }

    this.shown = false;
    // localStorage somehow only saves strings,
    // so it can retutn the "false" string, which is truhty
    if(localStorage.getItem("show_drawer") === "true"
       && window.innerWidth > breakpoint_width) {
      this.show(false);
    } else {
      this.hide();
    }


    this.$toggle.click(() => this.toggle());
  }

  toggle(){
    if(this.shown){
      this.hide();
    } else {
      this.show();
    }
    localStorage.setItem("show_drawer", this.shown);
  }

  show(transition = true) {
    this.shown = true;
    this.$drawer.addClass("active");
    this.$main.addClass("drawer-shown");
    this.setTransition(transition);
  }

  hide(transition = true) {
    this.shown = false;
    this.$drawer.removeClass("active");
    this.$main.removeClass("drawer-shown");
    this.setTransition(transition);
  }

  setTransition(doTransition){
    if(doTransition){
      this.$drawer.addClass("with-transition");
      this.$main.addClass("with-transition");
    } else {
      this.$drawer.removeClass("with-transition");
      this.$main.removeClass("with-transition");
    }
  }
}

// Directly 'start' the drawer, waiting for the document
// to be loaded makes the drawer 'jump' in
new Drawer();
