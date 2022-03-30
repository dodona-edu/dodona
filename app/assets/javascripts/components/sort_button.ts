import "search.ts";
import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

export class SortQuery {
    active_column: string;
    ascending: boolean;
    buttons: Array<SortButton> = [];

    constructor() {
        const sortParams = [...dodona.search_query.query_params.params.entries()].filter(
            ([k, v]) => k.startsWith("order_by_") && (v=== "ASC" || v === "DESC")
        );

        if (sortParams.length > 0) {
            this.active_column = sortParams[0][0].substring(9);
            this.ascending = sortParams[0][1] === "ASC";
            console.log(this.active_column, this.ascending);
            sortParams.slice(1).forEach(([k, _]) => {
                dodona.search_query.query_params.updateParam(k, undefined);
            });
        }
        dodona.search_query.query_params.subscribe((k, o, n) => {
            if (
                k.startsWith("order_by_") &&
                !(k === this.getQueryKey() && n === this.getQueryValue()) &&
                (n === "ASC" || n === "DESC")
            ) {
                this.active_column = k.substring(9);
                this.ascending = n === "ASC";
                this.notifySortButtons();
            }
        });
    }

    getQueryKey(): string {
        return "order_by_" + this.active_column;
    }

    getQueryValue(): string {
        return this.ascending ? "ASC" : "DESC";
    }

    registerSortButton(b: SortButton): void {
        this.buttons.push(b);
    }

    notifySortButtons(): void {
        this.buttons.forEach(b => {
            b.active_column = this.active_column;
            b.ascending = this.ascending;
        });
    }

    sortBy(column: string, ascending: boolean): void {
        if (this.active_column === column && this.ascending === ascending){
            return;
        }

        if (this.active_column !== column) {
            dodona.search_query.query_params.updateParam(this.getQueryKey(), undefined);
            this.active_column = column;
        }
        this.ascending = ascending;
        this.notifySortButtons();
        dodona.search_query.query_params.updateParam(this.getQueryKey(), this.getQueryValue());
    }
}
dodona.state = {};
dodona.state.sort_query = new SortQuery();

@customElement("dodona-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
        column: string;
    // @state()
        active_column: string;
    // @state()
        ascending: boolean;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    isActive(): boolean {
        return this.column === this.active_column;
    }

    getSortIcon(): string {
        return this.isActive() ? this.ascending ? "sort-ascending" : "sort-descending" : "sort";
    }

    sort(): void {
        dodona.state.sort_query.sortBy(this.column, !this.isActive() || !this.ascending);
    }

    constructor() {
        super();
        dodona.state.sort_query.registerSortButton(this);
        this.ascending = dodona.state.sort_query.ascending;
        this.active_column = dodona.state.sort_query.active_column;
    }

    render(): TemplateResult {
        return html`
            <i class="mdi mdi-16 mdi-${this.getSortIcon()} sort-icon" @click=${() => this.sort()}></i>
        `;
    }
}
