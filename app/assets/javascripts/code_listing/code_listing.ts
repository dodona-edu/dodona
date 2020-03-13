import { MachineAnnotation, AnnotationData } from "code_listing/machine_annotation";
import { UserAnnotation, UserAnnotationData } from "code_listing/user_annotation";
import { Annotation } from "code_listing/annotation";
import { fetch } from "util.js";

export class CodeListing {
    private readonly table: HTMLTableElement;

    private annotations: Annotation[];

    public readonly code: string;

    private readonly markingClass: string = "marked";
    private readonly submissionId: string;

    private hideAllButton: HTMLButtonElement;
    private showOnlyErrorButton: HTMLButtonElement;
    private showAllButton: HTMLButtonElement;
    private annotationsWereHidden: HTMLSpanElement;
    private diffSwitchPrefix: HTMLSpanElement;

    constructor(code: string) {
        this.table = document.querySelector("table.code-listing") as HTMLTableElement;
        this.code = code;
        this.annotations = [];

        const htmlDivElement = document.querySelector(".code-table[data-submission-id]") as HTMLDivElement;
        if (htmlDivElement) {
            this.submissionId = htmlDivElement.dataset["submissionId"];
        } else {
            console.error("There was no code-table to be found with a submission id");
        }

        if (this.table === null) {
            console.error("The code listing could not be found");
        }

        this.table.addEventListener("copy", e => {
            e.clipboardData.setData("text/plain", this.getSelectedCode());
            e.preventDefault();
        });

        this.initAnnotationToggleButtons();
    }

    private initAnnotationToggleButtons(): void {
        this.hideAllButton = document.querySelector("#hide_all_annotations");
        this.showOnlyErrorButton = document.querySelector("#show_only_errors");
        this.showAllButton = document.querySelector("#show_all_annotations");
        this.annotationsWereHidden = document.querySelector("#annotations-were-hidden");
        this.diffSwitchPrefix = document.querySelector("#diff-switch-prefix");

        const showAllListener = (): void => {
            this.showAllAnnotations();
            this.annotationsWereHidden?.remove();
        };

        this.showAllButton.addEventListener("click", () => showAllListener());
        this.hideAllButton.addEventListener("click", () => this.hideAllAnnotations());

        this.showOnlyErrorButton.addEventListener("click", () => this.compressAnnotations());
    }

    addAnnotations(annotations: AnnotationData[]): void {
        annotations.forEach(m => this.addAnnotation(m));
    }

    addAnnotation(annotation: AnnotationData): void {
        this.annotations.push(new MachineAnnotation(this.annotations.length, annotation, this.table, this));

        this.showAllButton.classList.remove("hide");
        this.hideAllButton.classList.remove("hide");
        this.diffSwitchPrefix.classList.remove("hide");

        if (annotation.type === "error") {
            this.showOnlyErrorButton.classList.remove("hide");
            this.annotationsWereHidden.classList.remove("hide");
        }

        const errorCount = this.annotations.filter(a => a.type !== "error" && a.type !== "user").length;
        if (errorCount > 0) {
            const nonErrorAnnotationCount = this.createHiddenMessage(errorCount);
            this.annotationsWereHidden.innerHTML = "";
            this.annotationsWereHidden.appendChild(nonErrorAnnotationCount);
        }
    }

    async addUserAnnotations(userAnnotationURL: string): Promise<void> {
        const response = await fetch(userAnnotationURL);
        if (response.ok) {
            const data: UserAnnotationData[] = await response.json();
            data.forEach(annotation => this.addUserAnnotation(annotation));
        }
    }

    addUserAnnotation(annotation: UserAnnotationData): void {
        const annotationObj = new UserAnnotation(annotation, this.table, this);
        this.annotations.push(annotationObj);
    }

    removeUserAnnotation(annotation: UserAnnotation): void {
        const index = this.annotations.indexOf(annotation);
        if (index !== -1) {
            this.annotations.splice(index, 1);
        }
    }

    compressAnnotations(): void {
        this.showAllAnnotations();

        const errorsAndUser = this.annotations.filter(m => m.type === "error" || m.type === "user");
        if (errorsAndUser.length !== 0) {
            const others = this.annotations.filter(m => m.type !== "error" && m.type !== "user");
            others.forEach(m => m.hide());
            errorsAndUser.forEach(m => m.show());
            this.showOnlyErrorButton.classList.add("active");
        }

        this.showAllButton.classList.remove("active");
        this.hideAllButton.classList.remove("active");
    }

    showAllAnnotations(): void {
        this.annotations.forEach(m => m.show());
    }

    hideAllAnnotations(): void {
        this.annotations.forEach(m => m.hide());
    }

    clearHighlights(): void {
        const markedAnnotations = this.table.querySelectorAll(`tr.lineno.${this.markingClass}`);
        markedAnnotations.forEach(markedAnnotation => {
            markedAnnotation.classList.remove(this.markingClass);
        });
    }

    highlightLine(lineNr: number, scrollToLine = false): void {
        const toMarkAnnotationRow = this.table.querySelector(`tr.lineno#line-${lineNr}`);
        toMarkAnnotationRow.classList.add(this.markingClass);
        if (scrollToLine) {
            toMarkAnnotationRow.scrollIntoView({ block: "center" });
        }
    }

    private getSelectedCode(): string {
        const selection = window.getSelection();
        const strings = [];

        // A selection can have many different selected ranges
        // Firefox: Selecting multiple rows in a table -> Multiple ranges, with the final one
        //     possibly being a preformatted node, while the original content of the selection was
        //     a part of a div
        // Chrome: Selecting multiple rows in a table -> Single range that lists everything in HTML
        //     order (even observed some gutter elements)
        for (let rangeIndex = 0; rangeIndex < selection.rangeCount; rangeIndex++) {
            // Extract the selected HTML ranges into a DocumentFragment
            const documentFragment = selection.getRangeAt(rangeIndex).cloneContents();

            // Remove any gutter element or annotation element in the document fragment
            // As observed, some browsers (Safari) can ignore user-select: none, and as such allow
            // the user to select line numbers.
            // To avoid any problems later we remove anything in a rouge-gutter or annotation-set
            // class.
            documentFragment.querySelectorAll(".rouge-gutter, .annotation-set").forEach(n => n.remove());

            // Only select the preformatted nodes as they will contain the code
            // (with trailing newline)
            // In the case of an empty line (empty string), a newline is substituted.
            const fullNodes = documentFragment.querySelectorAll("pre");
            fullNodes.forEach(v => strings.push(v.textContent || "\n"));
        }

        return strings.join("");
    }

    public getAnnotationsForLine(lineNr: number): Annotation[] {
        return this.annotations.filter(a => a.row === lineNr);
    }

    public createHiddenMessage(count: number): HTMLSpanElement {
        const span = document.createElement("span");

        const spanText: Text = document.createTextNode(I18n.t("js.annotation.were_hidden.first") + " ");
        span.appendChild(spanText);

        const link: HTMLAnchorElement = document.createElement("a");
        const data: string = I18n.t(`js.annotation.were_hidden.second.${count > 1 ? "plural" : "single"}`).replace(/{count}/g, String(count));
        const linkText: Text = document.createTextNode(data);
        link.href = "#";
        link.addEventListener("click", ev => {
            ev.preventDefault();
            this.showAllButton.click();
        });
        link.appendChild(linkText);
        span.appendChild(link);
        return span;
    }

    initButtonsForComment(): void {
        const codeLines = this.table.querySelectorAll(".lineno");
        codeLines.forEach((codeLine: HTMLTableRowElement) => {
            const idParts = codeLine.id.split("-");
            const lineNumber = parseInt(idParts[idParts.length - 1]) - 1;
            const annotationButton: HTMLButtonElement = document.createElement("button");
            annotationButton.setAttribute("class", "annotation-button");
            annotationButton.setAttribute("type", "button");
            annotationButton.addEventListener("click", () => this.handleCommentButtonClick(lineNumber, codeLine));

            const annotationButtonPlus = document.createElement("i");
            annotationButtonPlus.setAttribute("class", "mdi mdi-comment-plus mdi-18");
            annotationButton.appendChild(annotationButtonPlus);

            codeLine.querySelector(".rouge-code").prepend(annotationButton);
        });
    }

    private createRow(lineNumber: number, rougeRow: number): HTMLTableRowElement {
        const formSubmissionRow: HTMLTableRowElement = this.table.insertRow(lineNumber);
        formSubmissionRow.setAttribute("class", "annotation-set");
        formSubmissionRow.setAttribute("id", `annotation-row-id-${rougeRow}`);
        const gutterTD: HTMLTableDataCellElement = formSubmissionRow.insertCell();
        gutterTD.setAttribute("class", "rouge-gutter gl");
        const annotationTD: HTMLTableDataCellElement = formSubmissionRow.insertCell();
        annotationTD.setAttribute("class", "annotation-cell");
        return formSubmissionRow;
    }

    private findOrCreateTableRow(rowId: number, tableIndex: number, rougeRow: number): HTMLTableRowElement {
        let annotationRow: HTMLTableRowElement = this.table.querySelector(`#annotation-row-id-${rowId}`);
        if (annotationRow === null) {
            annotationRow = this.createRow(tableIndex, rougeRow);
        }
        return annotationRow;
    }

    handleCommentButtonClick(lineNumber: number, codeLine: HTMLTableRowElement): void {
        const tableRowId: number = codeLine.rowIndex;

        // Remove previous submission window
        const tr: HTMLTableRowElement = this.findOrCreateTableRow(lineNumber, tableRowId + 1, lineNumber);
        const existingAnnotationSubmissionDiv: HTMLFormElement = tr.querySelector("form.annotation-submission");
        if (existingAnnotationSubmissionDiv) {
            return;
        }

        const annotationSubmissionDiv: HTMLFormElement = this.createAnnotationSubmissionDiv(lineNumber);
        const annotationCell: HTMLTableDataCellElement = tr.querySelector("td.annotation-cell");
        annotationCell.append(annotationSubmissionDiv);
    }

    createAnnotationSubmissionDiv(lineId: number, annotation?: UserAnnotation): HTMLFormElement {
        const node = document.createElement("form");
        node.classList.add("annotation-submission");
        if (annotation) {
            node.classList.add("annotation-edit");
        }
        node.dataset["lineId"] = `${lineId}`;
        node.innerHTML = `
          <textarea class="form-control" id="submission-textarea" rows="3"></textarea>
          <div class="annotation-submission-button-container">
            <button class="btn btn-text btn-primary annotation-control-button annotation-submission-button" type="button">
              ${I18n.t("js.user_annotation.send")}
            </button>
            <button class="btn btn-text annotation-control-button annotation-cancel-button" type="button">
              ${I18n.t("js.user_annotation.cancel")}
            </button>
            ${annotation && annotation.annotationData.permission.destroy ? `
                  <button class="btn-text annotation-control-button annotation-delete-button" type="button">
                    ${I18n.t("js.user_annotation.delete")}
                  </button>
                ` : ""}
          </div>
        `;

        const inputField: HTMLTextAreaElement = node.querySelector("#submission-textarea");
        if (annotation) {
            inputField.textContent = annotation.annotationData.annotation_text;
            inputField.setAttribute("rows", String(annotation.annotationData.annotation_text.split("\n").length));
        } else {
            inputField.textContent = "";
        }

        if (annotation && annotation.annotationData.permission.destroy) {
            const deleteButton: HTMLButtonElement = node.querySelector(".annotation-delete-button");
            deleteButton.addEventListener("click", () => {
                annotation.delete(annotation.annotation);
            });
        }

        const cancelButton: HTMLButtonElement = node.querySelector(".annotation-cancel-button");
        const sendButton: HTMLButtonElement = node.querySelector(".annotation-submission-button");

        if (annotation) {
            sendButton.addEventListener("click", () => annotation.update(inputField.value, annotation.annotation, node));
            cancelButton.addEventListener("click", () => annotation.cancelEdit(annotation.annotation, node));
        } else {
            sendButton.addEventListener("click", () => this.createAnnotation(lineId, inputField.value, node));
            cancelButton.addEventListener("click", () => node.remove());
        }

        return node;
    }

    async createAnnotation(lineId: number, text: string, form: HTMLFormElement): Promise<void> {
        const response = await fetch(`/submissions/${this.submissionId}/annotations`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ annotation: {
                // eslint-disable-next-line @typescript-eslint/camelcase
                line_nr: lineId,
                // eslint-disable-next-line @typescript-eslint/camelcase
                annotation_text: text
            } })
        });
        if (response.ok) {
            this.addUserAnnotation(await response.json());
            form.remove();
        } else {
            const error = await response.json();
            const errorList: HTMLUListElement = UserAnnotation.processErrorMessage(error.responseJSON);

            // Remove previous error list
            const previousErrorList = form.querySelector(".annotation-submission-error-list");
            previousErrorList?.remove();

            form.querySelector(".annotation-submission-button-container").appendChild(errorList);
        }
    }
}
