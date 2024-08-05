import { LitElement } from "lit";
import { ready } from "utilities";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Constructor = new (...args: any[]) => LitElement;

export function i18nMixin<T extends Constructor>(superClass: T): T {
    /**
     * This mixin makes a LitElement that integrates I18n
     * It also makes sure that the component is rerendered when the language becomes available
     */
    class I18nMixinClass extends superClass {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        constructor(...args: any[]) {
            super(args);
            // Reload when I18n is available
            this.initI18n();
        }

        async initI18n(): Promise<void> {
            // Reload when I18n is available
            await ready;
            this.requestUpdate();
        }
    }

    // Cast return type to the superClass type passed in
    return I18nMixinClass as T;
}
