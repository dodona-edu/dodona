import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import jspreadsheet, { Column, JspreadsheetInstance } from "jspreadsheet-ce";
import { createRef, ref, Ref } from "lit/directives/ref.js";
import { DodonaElement } from "components/meta/dodona_element";
import { fetch } from "utilities";
import { i18n } from "i18n/i18n";
import { Tooltip } from "bootstrap";

type CellData = string | number | boolean;
type ScoreItem = {
    id: number | null;
    name: string;
    description?: string;
    maximum: string;
    visible: boolean;
    order?: number;
}

type ColumnWithTooltip = Column & { tooltip?: string };

/**
 * A spreadsheet table to edit score items.
 *
 * @element d-score-item-input-table
 *
 * @fires cancel - When the cancel button is clicked.
 *
 * @prop {string} route - The route to send the updated score items to.
 * @prop {ScoreItem[]} scoreItems - The original score items, that will be displayed in the table.
 */
@customElement("d-score-item-input-table")
export class ScoreItemInputTable extends DodonaElement {
    @property({ type: String })
    route: string = "";
    @property({ type: Array, attribute: "score-items" })
    scoreItems: ScoreItem[] = [];

    tableRef: Ref<HTMLDivElement> = createRef();
    table: JspreadsheetInstance;

    @property({ state: true })
    hasErrors: boolean = false;

    get tableWidth(): number {
        return this.tableRef.value.clientWidth;
    }

    get descriptionColWidth(): number {
        if (!this.tableRef.value) {
            return 200;
        }

        // full width - borders - name column - maximum column - visible column - index column
        const variableWidth = this.tableWidth - 14 - 200 - 100 - 100 - 50;
        return Math.max(200, variableWidth);
    }

    get data(): CellData[][] {
        return [
            ...this.scoreItems.map(item => [
                item.id,
                item.name,
                item.description,
                item.maximum,
                item.visible
            ]),
            ["", "", "", "", false]
        ];
    }

    get editedScoreItems(): ScoreItem[] {
        const tableData = this.table.getData();

        const scoreItems = tableData.map((row: CellData[], index: number) => {
            return {
                id: row[0] as number | null,
                name: row[1] as string,
                description: row[2] as string,
                maximum: row[3] as string,
                visible: row[4] as boolean,
                order: index,
            };
        });

        // filter out empty rows
        return scoreItems.filter(item => !(item.name === "" && item.maximum === "" && item.description === "" && item.visible === false));
    }

    get columnConfig(): ColumnWithTooltip[] {
        return [
            { type: "hidden", title: "id" },
            { type: "text", title: i18n.t("js.score_items.name"), width: 200, align: "left" },
            { type: "text", title: i18n.t("js.score_items.description"), width: this.descriptionColWidth, align: "left", tooltip: i18n.t("js.score_items.description_help") },
            { type: "numeric", title: i18n.t("js.score_items.maximum"), width: 100, tooltip: i18n.t("js.score_items.maximum_help") },
            { type: "checkbox", title: i18n.t("js.score_items.visible"), width: 100, tooltip: i18n.t("js.score_items.visible_help") },
        ];
    }

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        this.table = jspreadsheet(this.tableRef.value, {
            root: this,
            data: this.data,
            columns: this.columnConfig,
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
            minSpareRows: 1,
            parseFormulas: false,
            selectionCopy: false,
            wordWrap: true,
            defaultRowHeight: 30,
            allowExport: false,
        });

        // update description column width when the window is resized
        new ResizeObserver(() => {
            this.table.setWidth(2, this.descriptionColWidth);
        }).observe(this.tableRef.value);
    }

    validate(): boolean {
        // Remove all error classes
        this.tableRef.value.querySelectorAll("td.error").forEach(cell => {
            cell.classList.remove("error");
        });

        const invalidCells: string[] = [];
        const data = this.editedScoreItems;
        data.forEach(item => {
            const row = item.order + 1;
            if (item.name === "") {
                invalidCells.push("B" + row);
            }
            const max = parseFloat(item.maximum);
            if (Number.isNaN(max) || max <= 0) {
                invalidCells.push("D" + row);
            }
        });
        invalidCells.forEach(cell => {
            this.table.getCell(cell).classList.add("error");
        });
        this.hasErrors = invalidCells.length > 0;
        return !this.hasErrors;
    }

    confirmWarnings(): boolean {
        const old = this.scoreItems;
        const edited = this.editedScoreItems;
        const removed = old.some(item => !edited.some(e => e.id === item.id));
        const maxEdited = old.some(item => edited.some(e => e.id === item.id && e.maximum !== item.maximum));

        let warnings = "";
        if (removed) {
            warnings += i18n.t("js.score_items.deleted_warning") + "\n";
        }
        if (maxEdited) {
            warnings += i18n.t("js.score_items.modified_warning") + "\n";
        }

        return warnings === "" || confirm(warnings);
    }

    async save(): Promise<void> {
        if (!this.validate()) {
            return;
        }

        if (!this.confirmWarnings()) {
            return;
        }

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

    updateTitlesAndTooltips(): void {
        this.columnConfig.forEach((column, index) => {
            this.table.setHeader(index, column.title);

            const td = this.tableRef.value.querySelector(`thead td[data-x="${index}"]`);
            if (td && column.tooltip) {
                td.setAttribute("title", column.tooltip);
                new Tooltip(td);
            }
        });
    }

    cancel(): void {
        if (this.table) {
            this.table.setData(this.data);
        }
        this.dispatchEvent(new Event("cancel"));
    }


    render(): TemplateResult {
        if (this.table && this.tableRef.value) {
            // Reset column headers as language might have changed
            this.updateTitlesAndTooltips();
        }

        return html`
            ${this.hasErrors ? html`<div class="alert alert-danger">${i18n.t("js.score_items.validation_warning")}</div>` : ""}
            <div style="width: 100%" ${ref(this.tableRef)}></div>
            <div class="d-flex justify-content-end">
                <button @click=${this.cancel} class="btn btn-outline">
                    ${i18n.t("js.score_items.cancel")}
                </button>
                <button @click=${this.save} class="btn btn-filled">
                    ${i18n.t("js.score_items.save")}
                </button>
            </div>
        `;
    }
}
