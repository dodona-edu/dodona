export class Drawer {
    drawer: Element;

    constructor(drawerSelector = "#drawer",
        toggleSelector = ".drawer-toggle",
        backgroundSelector = ".drawer-background") {
        this.drawer = document.querySelector(drawerSelector);

        document
            .querySelector(toggleSelector)
            ?.addEventListener("click", () => this.toggle());
        document
            .querySelector(backgroundSelector)
            ?.addEventListener("click", () => this.hide());
    }

    toggle(): void {
        this.drawer.classList.toggle("active");
    }

    hide(): void {
        this.drawer.classList.remove("active");
    }

    show(): void {
        this.drawer.classList.add("active");
    }
}
