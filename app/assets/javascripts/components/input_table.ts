import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, render, TemplateResult } from "lit";
import jspreadsheet, {
    CellValue,
    Column,
    CustomEditor,
    JspreadsheetInstance,
    JspreadsheetInstanceElement
} from "jspreadsheet-ce";
import { createRef, ref, Ref } from "lit/directives/ref.js";
import { DodonaElement } from "components/meta/dodona_element";
import { fetch, ready } from "utilities";
import { i18n } from "i18n/i18n";
import { Tooltip } from "bootstrap";
import { watchMixin } from "components/meta/watch_mixin";

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

const toBoolean = (value: CellValue): boolean => {
    return value === "true" || value === true;
};

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
export class ScoreItemInputTable extends watchMixin(DodonaElement) {
    @property({ type: String })
    route: string = "";
    @property({ type: Array, attribute: "score-items" })
    scoreItems: ScoreItem[] = [];
    @property({ type: Boolean, attribute: "total-visible" })
    totalVisible: boolean = false;

    tableRef: Ref<HTMLDivElement> = createRef();
    table: JspreadsheetInstance;

    @property({ state: true })
    hasErrors: boolean = false;
    @property({ state: true })
    _totalVisible: boolean = false;

    watch = {
        totalVisible: () => {
            this._totalVisible = this.totalVisible;
        }
    };

    toggleTotalVisible(): void {
        this._totalVisible = !this._totalVisible;
    }

    get tableWidth(): number {
        return this.tableRef.value.clientWidth;
    }

    get descriptionColWidth(): number {
        if (!this.tableRef.value) {
            return 200;
        }

        // full width - borders - name column - maximum column - visible column - index column - delete column
        const variableWidth = this.tableWidth - 14 - 200 - 75 - 75 - 50 - 30;
        return Math.max(200, variableWidth);
    }

    get data(): CellData[][] {
        return [
            ...this.scoreItems.map(item => [
                item.name,
                item.description,
                item.maximum,
                item.visible,
                item.id,
            ]),
            ["", "", "", false, ""]
        ];
    }

    get editedScoreItems(): ScoreItem[] {
        const tableData = this.table.getData();

        const scoreItems = tableData.map((row: CellData[], index: number) => {
            return {
                name: row[0] as string,
                description: row[1] as string,
                maximum: (row[2] as string).replace(",", "."), // replace comma with dot for float representation
                visible: toBoolean(row[3]),
                id: row[4] as number | null,
                order: index,
            };
        });

        // filter out empty rows
        return scoreItems.filter(item => !(item.name === "" && item.maximum === "" && item.description === "" && item.visible === false));
    }

    deleteCellRow(cell: HTMLTableCellElement): void {
        const row = cell.parentElement as HTMLTableRowElement;
        this.table.deleteRow(row.rowIndex-1);
    }

    createDeleteButton(cell: HTMLTableCellElement): HTMLTableCellElement {
        const button = html`<button
            class="btn btn-icon d-btn-danger btn-icon-inline"
            title="${i18n.t("js.score_items.jspreadsheet.deleteRow")}"
            @click="${() => this.deleteCellRow(cell)}">
                <i class="mdi mdi-18 mdi-delete"></i>
            </button>`;
        render(button, cell);
        return cell;
    }

    customCheckboxEditor(): CustomEditor {
        const updateCell = (cell: HTMLTableCellElement): void => {
            this.table.setValue(cell, !toBoolean(this.table.getValue(cell)));
        };
        return {
            createCell: (cell: HTMLTableCellElement) => {
                const current = cell.innerHTML === "true";
                const checkbox = html`<div class="form-check" contenteditable="false" style="white-space: normal;">
                    <input type="checkbox"
                           class="form-check-input"
                           ?checked="${current}"
                           @change="${() => updateCell(cell)}">
                </div>`;
                cell.innerHTML = "";
                render(checkbox, cell);
                return cell;
            },
            openEditor: () => false,
            closeEditor: (cell: HTMLTableCellElement) => {
                return toBoolean(this.table.getValue(cell));
            },
            updateCell: (cell: HTMLTableCellElement, value: CellValue) => {
                const checkbox = cell.querySelector("input");
                if (checkbox) {
                    checkbox.checked = toBoolean(value);
                }
                return toBoolean(value);
            }
        };
    }

    get columnConfig(): ColumnWithTooltip[] {
        return [
            { type: "text", title: i18n.t("js.score_items.name"), width: 200, align: "left" },
            { type: "text", title: i18n.t("js.score_items.description"), width: this.descriptionColWidth, align: "left", tooltip: i18n.t("js.score_items.description_help") },
            { type: "numeric", title: i18n.t("js.score_items.maximum"), width: 75, align: "left", tooltip: i18n.t("js.score_items.maximum_help") },
            { type: "html", title: i18n.t("js.score_items.visible"), width: 75, align: "left", tooltip: i18n.t("js.score_items.visible_help"), editor: this.customCheckboxEditor() },
            { type: "hidden", title: "id" },
            { type: "html", title: " ", width: 30, align: "center", readOnly: true, editor: {
                createCell: (cell: HTMLTableCellElement) => this.createDeleteButton(cell),
            } },
        ];
    }

    async initTable(): Promise<void> {
        // Wait for translations to be present
        await ready;

        this.table = jspreadsheet(this.tableRef.value, {
            root: this,
            data: this.data,
            columns: this.columnConfig,
            text: {
                copy: i18n.t("js.score_items.jspreadsheet.copy"),
                deleteSelectedRows: i18n.t("js.score_items.jspreadsheet.deleteSelectedRows"),
                insertANewRowAfter: i18n.t("js.score_items.jspreadsheet.insertNewRowAfter"),
                insertANewRowBefore: i18n.t("js.score_items.jspreadsheet.insertNewRowBefore"),
                paste: i18n.t("js.score_items.jspreadsheet.paste"),
            },
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

        // init tooltips
        this.columnConfig.forEach((column, index) => {
            const td = this.tableRef.value.querySelector(`thead td[data-x="${index}"]`);
            if (td && column.tooltip) {
                td.setAttribute("title", column.tooltip);
                new Tooltip(td);
            }
        });

        // mark header and menu as non-editable
        this.tableRef.value.querySelector("thead").setAttribute("contenteditable", "false");
        this.tableRef.value.querySelector(".jexcel_contextmenu").setAttribute("contenteditable", "false");


        // update description column width when the window is resized
        new ResizeObserver(() => {
            this.table.setWidth(1, this.descriptionColWidth);
        }).observe(this.tableRef.value);
    }

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);

        this.initTable();
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
            // Check if maximum is a positive number < 1000
            // we use a regex instead of parseFloat because parseFloat is too lenient
            if (!/^\d{1,3}(\.\d+)?$/.test(item.maximum) || parseFloat(item.maximum) <= 0) {
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
                evaluation_exercise: {
                    visible_score: this._totalVisible,
                    score_items: this.editedScoreItems
                }
            })
        });
        if (response.ok) {
            const js = await response.text();
            eval(js);
        }
    }

    cancel(): void {
        if (this.table) {
            this.table.setData(this.data);
            this._totalVisible = this.totalVisible;
            this.hasErrors = false;
        }
        this.dispatchEvent(new Event("cancel"));
    }


    render(): TemplateResult {
        return html`
            ${this.hasErrors ? html`
                <div class="alert alert-danger">${i18n.t("js.score_items.validation_warning")}</div>` : ""}
            <div style="width: 100%" ${ref(this.tableRef)} contenteditable="true"></div>
            <div class="form-check ms-1">
                <label class="form-check-label" for="total-visible">
                    ${i18n.t("js.score_items.total_visible")}
                </label>
                <input type="checkbox"
                       class="form-check-input"
                       id="total-visible"
                       ?checked=${this._totalVisible}
                       @change=${() => this.toggleTotalVisible()}>
            </div>
            <div class="d-flex justify-content-end">
                <button @click=${this.cancel} class="btn btn-text me-1">
                    ${i18n.t("js.score_items.cancel")}
                </button>
                <button @click=${this.save} class="btn btn-filled">
                    ${i18n.t("js.score_items.save")}
                </button>
            </div>
        `;
    }
}
