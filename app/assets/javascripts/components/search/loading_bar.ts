import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { search } from "search";
import { DodonaElement } from "components/meta/dodona_element";
import { watchMixin } from "components/meta/watch_mixin";

/**
 * This component represents a loading bar.
 * It will be triggered by search
 *
 * @element d-loading-bar
 */
@customElement("d-loading-bar")
export class LoadingBar extends watchMixin(DodonaElement) {
    @property({ type: Boolean, attribute: "search-based" })
    searchBased = false;

    @property({ type: Boolean })
    loading = false;

    constructor() {
        super();
        if (this.searchBased) {
            search.loadingBars.push(this);
        }
    }

    watch = {
        searchBased: () => {
            if (this.searchBased) {
                search.loadingBars.push(this);
            }
        }
    };

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
