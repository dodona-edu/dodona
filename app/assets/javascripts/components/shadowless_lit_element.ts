import { LitElement } from "lit";

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
export class ShadowlessLitElement extends LitElement {
    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }
}
