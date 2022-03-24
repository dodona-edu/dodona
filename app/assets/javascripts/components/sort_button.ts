import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

export class SortQuery {
    active_column: string;
    ascending: boolean;
    buttons: Array<SortButton> = [];

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
        this.active_column = column;
        this.ascending = ascending;
        console.log(this.active_column, this.ascending ? "ASC" : "DESC");
        this.notifySortButtons();
    }
}

dodona.sort_query = new SortQuery();

@customElement("dodona-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
        column: string;
    @property({ type: String })
        active_column: string;
    @property({ type: Boolean })
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
        dodona.sort_query.sortBy(this.column, !this.isActive() || !this.ascending);
    }

    constructor() {
        super();
        dodona.sort_query.registerSortButton(this);
    }

    render(): TemplateResult {
        return html`
            <i class="mdi mdi-16 mdi-${this.getSortIcon()} sort-icon" @click=${() => this.sort()}></i>
        `;
    }
}
