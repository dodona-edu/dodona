export default class Drawer {
  constructor(drawerSelector=".drawer-list") {
    this.$drawer = $(drawerSelector);
    this.$drawer.find("a").filter('[href^="#"]').click(function (e) {
      e.preventDefault();
      $(this).tab("show");
      window.scrollTo(0, 0);
      // Alter history to put # in url bar (?)
      history.pushState({}, this.text(), this.href);
    });
    this.checkLocationHash();
  }

  /**
   * Auto open tab in which the location.hash is
   * TODO: make jump more
   */
  checkLocationHash() {
    this.setGroup(this.containedGroup(location.hash))
}

  containedGroup(selector) {
    if(selector){
      const $containedTab = $(selector).closest(".tab-pane");
      return $containedTab.get(0).id || null;
    }
  }

  setGroup(group=null) {
    if (group !== null) {
      // $("#"+group).tab("show") does not work
      this.$drawer.find(`a[href="#${group}]`).tab("show");
      window.scrollTo(0, 0);
    }
  }
}

$(()=>{new Drawer();}) // TODO remove
