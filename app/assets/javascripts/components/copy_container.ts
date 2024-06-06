import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import "components/copy_button";
import { DodonaElement } from "components/meta/dodona_element";

/**
 * A container that holds code that can be copied to the clipboard.
 *
 * @element d-copy-container
 *
 * @property {string} content - The content that is copied to the clipboard.
 */
@customElement("d-copy-container")
export class CopyContainer extends DodonaElement {
    @property({ type: String })
    content: string;

    @property({ state: true })
    containerId: string;

    constructor() {
        super();
        this.containerId = "copy-container-" + Math.random().toString(36).substring(7);
    }

    protected render(): TemplateResult {
        return html`<pre class="code-wrapper"><code id="${this.containerId}">${this.content}</code><d-copy-button targetId="${this.containerId}"></d-copy-button></pre>`;
    }
}
