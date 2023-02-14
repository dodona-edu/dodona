import { LitElement } from "lit";
import "@boulevard/vampire";

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
 *
 * it reintroduces the slot functionality using https://github.com/Boulevard/vampire
 * Usage in component:
 * html`
 *      <h5>Example</h5>
 *      <v-slot></v-slot>
 *      <div class="footer">
 *          <v-slot name="footer">Default footer</v-slot>
 *      </div>
 *     `
 *
 * Usage in parent:
 * <my-component>
 *     <div slot="footer">Footer</div>
 *     <div>Content</div>
 *     <div>Content</div>
 * </my-component>
 */
export class ShadowlessLitElement extends LitElement {
    createRenderRoot(): Element | ShadowRoot {
        this.appendChild(document.createElement("v-root"));
        return this;
    }
}
