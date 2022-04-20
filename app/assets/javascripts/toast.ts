/**
 * Shows a toast in the bottom left corner. By default, hides it after 3 seconds.
 */
export class Toast {
    static readonly hideDelay = 3000;
    static readonly removeDelay = 1000;
    static readonly toastsContainer = ".toasts";

    readonly toast: Element;

    constructor(readonly content: string, readonly autoHide = true, readonly loading = false) {
        this.toast = this.generateToastHTML(this.content, this.loading);
        this.show();

        if (this.autoHide) {
            setTimeout(() => {
                this.hide();
            }, Toast.hideDelay);
        }
    }

    private show(): void {
        document.querySelector(Toast.toastsContainer).prepend(this.toast);
        window.requestAnimationFrame(() => {
            this.toast.classList.remove("toast-show");
        });
    }

    hide(): void {
        this.toast.classList.add("toast-hide");
        setTimeout(() => {
            this.toast.remove();
        }, Toast.removeDelay);
    }

    private generateToastHTML(content: string, loading: boolean): Element {
        const element = this.htmlToElement(
            `<output role='status' class='toast toast-show'>${content}</output>`
        );
        if (loading) {
            element.appendChild(this.htmlToElement("<div class='spinner'></div>"));
        }
        return element;
    }

    private htmlToElement(html: string): Element {
        const template = document.createElement("template");
        template.innerHTML = html.trim();
        return template.content.firstChild as Element;
    }
}
