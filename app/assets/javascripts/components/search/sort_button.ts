import { css, html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQueryState } from "state/SearchQuery";
import { StateController } from "state/state_system/StateController";
/**
 * This component represents a sort button.
 * It is clickable and contains an icon indicating the current sort direction.
 *
 * @element d-sort-button
 *
 * @prop {string} column - the column by which should be sorted
 * @prop {string} default - posible values: "ASC" or "DESC". if present this sortButton is supposed to be active when no sort params ore in the searchQuery
 * @prop {boolean} disabled - disables the functionality
 *
 * @slot - this contains the clickable button content (left of the sort icon)
 */
@customElement("d-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
    accessor column: string;
    @property({ type: String })
    accessor default: string;
    @property({ type: Boolean })
    accessor disabled = false;

    state = new StateController(this);

    update(changedProperties: Map<string, unknown>): void {
        if ( changedProperties.has("disabled") ) {
            if (!this.disabled) {
                this.addEventListener("click", this.sort);
            } else {
                this.removeEventListener("click", this.sort);
            }
        }
        super.update(changedProperties);
    }

    static styles = css`
        :host {
            white-space: nowrap;
        }

        .mdi::before {
            display: inline-block;
            font: normal normal normal 24px/1 "Material Design Icons";
            text-rendering: auto;
            box-sizing: border-box;
            line-height: 15px;
            font-size: 15px;
        }

        .mdi-none::before {
           content: "\\F0045";
           visibility: hidden;
        }

        :host(:hover) .mdi-none::before {
            opacity: 0.7;
            visibility: visible;
            content: "\\F0045";
        }

        .mdi-arrow-down::before {
          content: "\\F0045";
        }

        :host(:hover) .mdi-arrow-down::before {
            opacity: 0.7;
            content: "\\F005D";
        }

        .mdi-arrow-up::before {
          content: "\\F005D";
        }

        :host(:hover) .mdi-arrow-up::before {
            opacity: 0.7;
            content: "\\F0045";
        }
    `;

    isActive(): boolean {
        return this.column === searchQueryState.queryParams.get("order_by[column]") ||
            (this.default !== undefined && searchQueryState.queryParams.get("order_by[column]") === undefined);
    }

    get ascending(): boolean {
        return searchQueryState.queryParams.get("order_by[direction]") === "ASC" ||
            (this.default === "ASC" && searchQueryState.queryParams.get("order_by[direction]") === undefined);
    }

    getSortIcon(): string {
        return this.isActive() ? this.ascending ? "arrow-up" : "arrow-down" : "none";
    }

    sort(): void {
        searchQueryState.queryParams.set("order_by[column]", this.column);
        if (!this.isActive() || !this.ascending) {
            searchQueryState.queryParams.set("order_by[direction]", "ASC");
        } else {
            searchQueryState.queryParams.set("order_by[direction]", "DESC");
        }
    }

    render(): TemplateResult {
        return html`
            <slot></slot>
            ${this.disabled? "": html`
                <style>:host {cursor: pointer;}</style>
                <i class="mdi mdi-${this.getSortIcon()}"></i>
            `}
        `;
    }
}
