import { LitElement } from "lit";
import { ready } from "util.js";

type Constructor = new (...args: any[]) => LitElement;

export function i18nMixin<T extends Constructor>(superClass: T): T {
    /**
     * This mixin makes a LitElement that integrates I18n
     * It also makes sure that the component is rerendered when the language becomes available
     */
    class I18nMixinClass extends superClass {
        constructor(...args: any[]) {
            super(args);
            // Reload when I18n is available
            ready.then(() => this.requestUpdate());
        }
    }

    // Cast return type to the superClass type passed in
    return I18nMixinClass as T;
}
