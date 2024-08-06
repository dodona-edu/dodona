import { customElement, property } from "lit/decorators.js";
import { html, LitElement, PropertyValues, TemplateResult } from "lit";
import jspreadsheet, { JspreadsheetInstance, Column } from "jspreadsheet-ce";
import { createRef, ref, Ref } from "lit/directives/ref.js";
import { DodonaElement } from "components/meta/dodona_element";

type CellData = string | number | boolean;


@customElement("d-input-table")
export class DInputTable extends DodonaElement {
    @property({ type: Array })
    data: CellData[][] = [];
    @property({ type: Array })
    columns: Column[] = [];

    tableRef: Ref<HTMLDivElement> = createRef();

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        const table: JspreadsheetInstance = jspreadsheet(this.tableRef.value, {
            root: this,
            data: [
                ["Test", "Test", 1, true],
            ],
            columns: [
                { type: "text", title: "Naam", width: 120 },
                { type: "text", title: "Beschrijving", width: 120 },
                { type: "numeric", title: "Maximum", width: 120 },
                { type: "checkbox", title: "Zichtbaar", width: 120 }
            ]
        });
    }

    render(): TemplateResult {
        return html`<div ${ref(this.tableRef)}></div>`;
    }
}
