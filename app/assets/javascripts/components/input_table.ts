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

    get tableWidth(): number {
        return this.tableRef.value.clientWidth;
    }

    get descriptionColWidth(): number {
        // full width - borders - name column - maximum column - visible column - index column
        const variableWidth = this.tableWidth - 6 - 200 - 100 - 100 - 50;
        return Math.max(200, variableWidth);
    }

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        const table: JspreadsheetInstance = jspreadsheet(this.tableRef.value, {
            root: this,
            data: [
                ["Test", "Test", 1, true],
            ],
            columns: [
                { type: "text", title: "Naam", width: 200, align: "left" },
                { type: "text", title: "Beschrijving", width: this.descriptionColWidth, align: "left" },
                { type: "numeric", title: "Maximum", width: 100 },
                { type: "checkbox", title: "Zichtbaar", width: 100 }
            ],
            about: false,
            allowDeleteColumn: false,
            allowDeleteRow: true,
            allowInsertColumn: false,
            allowInsertRow: true,
            allowManualInsertColumn: false,
            allowManualInsertRow: true,
            allowRenameColumn: false,
            columnResize: false,
            columnSorting: false,
            csvFileName: "scoresheet",
            minSpareRows: 1,
            parseFormulas: false,
            selectionCopy: false,
            wordWrap: true


        });
    }

    render(): TemplateResult {
        return html`<div ${ref(this.tableRef)}></div>`;
    }
}
