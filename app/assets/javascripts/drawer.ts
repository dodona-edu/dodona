export class Drawer {
    drawer: Element;

    constructor(toggleSelector = ".drawer-toggle",
                drawerSelector = "#drawer",
                backgroundSelector = ".drawer-background") {

        this.drawer = document.querySelector(drawerSelector);

        document
          .querySelector(toggleSelector)
          .addEventListener("click", () => this.toggle());
        document
          .querySelector(backgroundSelector)
          .addEventListener("click", () => this.hide());
    }

    toggle() {
        this.drawer.classList.toggle("active");
    }

    hide() {
        this.drawer.classList.remove("active");
    }
}
