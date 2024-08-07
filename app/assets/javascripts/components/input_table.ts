import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import jspreadsheet, { JspreadsheetInstance } from "jspreadsheet-ce";
import { createRef, ref, Ref } from "lit/directives/ref.js";
import { DodonaElement } from "components/meta/dodona_element";
import { fetch } from "utilities";

type CellData = string | number | boolean;
type ScoreItem = {
    id: number | null;
    name: string;
    description: string;
    maximum: number;
    visible: boolean;
}


@customElement("d-score-item-input-table")
export class ScoreItemInputTable extends DodonaElement {
    @property({ type: String })
    route: string = "";
    @property({ type: Array, attribute: "score-items" })
    scoreItems: ScoreItem[] = [];

    tableRef: Ref<HTMLDivElement> = createRef();
    table: JspreadsheetInstance;

    get tableWidth(): number {
        return this.tableRef.value.clientWidth;
    }

    get descriptionColWidth(): number {
        // full width - borders - name column - maximum column - visible column - index column
        const variableWidth = this.tableWidth - 6 - 200 - 100 - 100 - 50;
        return Math.max(200, variableWidth);
    }

    get data(): CellData[][] {
        return this.scoreItems.map(item => [
            item.id,
            item.name,
            item.description,
            item.maximum,
            item.visible
        ]);
    }

    get editedScoreItems(): ScoreItem[] {
        const tableData = this.table.getData();

        // Remove the last row if it is empty
        if (tableData[tableData.length - 1].every(cell => cell === "" || cell === false)) {
            tableData.pop();
        }

        return tableData.map((row: CellData[]) => {
            return {
                id: row[0] as number | null,
                name: row[1] as string,
                description: row[2] as string,
                maximum: row[3] as number,
                visible: row[4] as boolean
            };
        });
    }

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        this.table = jspreadsheet(this.tableRef.value, {
            root: this,
            data: this.data,
            columns: [
                { type: "hidden", title: "id" },
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

    async save(): Promise<void> {
        const response = await fetch(this.route, {
            method: "PATCH",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                score_items: this.editedScoreItems
            })
        });
        if (response.ok) {
            const js = await response.text();
            eval(js);
        }
    }


    render(): TemplateResult {
        return html`
            <div ${ref(this.tableRef)}></div>
            <button @click=${this.save} class="btn btn-filled">Opslaan</button>
        `;
    }
}
