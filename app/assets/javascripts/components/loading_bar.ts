import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { searchQuery } from "search";

/**
 * This component represents a loading bar.
 * It will be triggered by search
 *
 * @element d-loading-bar
 */
@customElement("d-loading-bar")
export class LoadingBar extends ShadowlessLitElement {
    @property({ type: Boolean, state: true })
    loading = false;

    constructor() {
        super();
        searchQuery.loadingBars.push(this);
    }

    show(): void {
        this.loading = true;
    }

    hide(): void {
        this.loading = false;
    }

    render(): TemplateResult {
        return html`
            <div class="dodona-progress dodona-progress-indeterminate" style="visibility: ${this.loading ? "visible" : "hidden"};">
                <div class="progressbar bar bar1" style="width: 0%;"></div>
                <div class="bufferbar bar bar2" style="width: 100%;"></div>
                <div class="auxbar bar bar3" style="width: 0%;"></div>
            </div>
        `;
    }
}
