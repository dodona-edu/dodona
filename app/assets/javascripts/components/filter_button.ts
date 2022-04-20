import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, TemplateResult } from "lit";
import { Tooltip } from "bootstrap";
import { ref } from "lit/directives/ref.js";
import { searchQuery } from "search";
import {ShadowlessLitElement} from "components/shadowless_lit_element";

@customElement("dodona-filter-button")
export class FilterButton extends LitElement {
    @property({ type: String })
        param: string;
    @property({ type: String })
        value: string;
    @property({ type: Boolean })
        multi = false;

    static styles = css`
        :host {
          cursor: pointer;
        }
    `;

    addFilter(): void {
        if (this.multi) {
            const selected = new Set(searchQuery.array_query_params.params.get(this.param));
            selected.add(this.value);
            searchQuery.array_query_params.updateParam(this.param, Array.from(selected));
        } else {
            searchQuery.query_params.updateParam(this.param, this.value);
        }
    }

    render(): TemplateResult {
        return html`<slot @click=${() => this.addFilter()}></slot>`;
    }
}

@customElement("dodona-filter-icon")
export class FilterIcon extends ShadowlessLitElement {
    @property({ type: String })
        value: string;
    @property({ type: String })
        title: string;

    element: Element;

    initialiseTooltip(e: Element): void {
        if (e) {
            this.element = e;
            const tooltip = Tooltip.getInstance(this.element);
            if (!tooltip) {
                new Tooltip(this.element);
            }
        }
    }

    disconnectedCallback(): void {
        const tooltip = Tooltip.getInstance(this.element);
        tooltip.hide();
        super.disconnectedCallback();
    }

    render(): TemplateResult {
        return html`
        <dodona-filter-button param="filter" .value=${this.value}>
            <i class="mdi mdi-filter-outline mdi-18 filter-icon"
               title="${this.title}"
               data-bs-toggle="tooltip"
               data-bs-placement="top"
               ${ref(r => this.initialiseTooltip(r))}
            >
            </i>
        </dodona-filter-button>
        `;
    }
}
