import { LitElement } from "lit";
import { i18nMixin } from "components/meta/i18n_mixin";

/**
 * This class removes the shadow dom functionality from lit elements
 * Shadow dom allows for:
 *   - DOM scoping
 *   - Style Scoping
 *   - Composition
 * more info here: https://lit.dev/docs/components/shadow-dom/
 *
 * This class is often used to avoid style scoping. (To be able to use the style as defined in our general css)
 * When shadow dom is required just use a normal LitElement
 */
export class ShadowlessLitElement extends i18nMixin(LitElement) {
    // don't use shadow dom
    createRenderRoot(): HTMLElement {
        return this;
    }
}
