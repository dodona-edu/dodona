import { Annotation, AnnotationData } from "code_listing/annotation";

import { UserAnnotation, UserAnnotationInterface, SubmitUserAnnotation } from "code_listing/user_annotation";

export class CodeListing {
    private readonly table: HTMLTableElement;
    readonly annotations: Annotation[];
    userAnnotations: UserAnnotation[];

    public readonly code: string;

    private readonly markingClass: string = "marked";
    private readonly submissionId: string;
    private readonly localePrefix: string;

    private hideAllButton: HTMLButtonElement;
    private showOnlyErrorButton: HTMLButtonElement;
    private showAllButton: HTMLButtonElement;
    private annotationsWereHidden: HTMLSpanElement;
    private diffSwitchPrefix: HTMLSpanElement;

    constructor(code, localePrefix = "nl") {
        this.table = document.querySelector("table.code-listing") as HTMLTableElement;
        this.code = code;
        this.annotations = [];
        this.userAnnotations = [];

        const htmlDivElement = document.querySelector(".code-table[data-submission-id]") as HTMLDivElement;
        if (htmlDivElement) {
            this.submissionId = htmlDivElement.dataset["submissionId"];
        } else {
            console.error("There was no code-table to be found with a submission id");
        }

        if (this.table === null) {
            console.error("The code listing could not be found");
        }

        this.table.addEventListener("copy", function (e) {
            e.clipboardData.setData("text/plain", window.dodona.codeListing.getSelectedCode());
            e.preventDefault();
        });

        this.initAnnotationToggleButtons();

        this.localePrefix = localePrefix;
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
        this.annotations.push(new Annotation(this.userAnnotations.length, annotation, this.table, this));

        this.showAllButton.classList.remove("hide");
        this.hideAllButton.classList.remove("hide");
        this.diffSwitchPrefix.classList.remove("hide");

        if (annotation.type === "error") {
            this.showOnlyErrorButton.classList.remove("hide");
            this.annotationsWereHidden.classList.remove("hide");
        }

        const errorCount = this.annotations.filter(a => a.type !== "error").length;
        if (errorCount > 0) {
            const nonErrorAnnotationCount = this.createHiddenMessage(errorCount);
            this.annotationsWereHidden.innerHTML = "";
            this.annotationsWereHidden.appendChild(nonErrorAnnotationCount);
        }
    }

    addUserAnnotations(userAnnotationURL: string): void {
        this.getAnnotationIndex(userAnnotationURL).done(
            (data: UserAnnotationInterface[]) => {
                data.forEach((annotation: UserAnnotationInterface) => {
                    this.addUserAnnotation(annotation);
                });
            }
        );
    }

    addUserAnnotation(annotation: UserAnnotationInterface): void {
        const annotationObj = new UserAnnotation(annotation, this.table, this);
        annotationObj.createAnnotationDiv();
        this.userAnnotations.push(annotationObj);
    }

    compressAnnotations(): void {
        this.showAllAnnotations();

        const errors = this.annotations.filter(m => m.type === "error");
        if (errors.length !== 0) {
            const others = this.annotations.filter(m => m.type !== "error");
            others.forEach(m => m.hide());
            errors.forEach(m => m.show());
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
            // TODO: When adding user annotations, edit this to make sure only code remains. The
            // class is being changed
            documentFragment.querySelectorAll(".rouge-gutter, .annotation-set").forEach(n => n.remove());

            // Only select the preformatted nodes as they will contain the code
            // (with trailing newline)
            // In the case of an empty line (empty string), a newline is substituted.
            const fullNodes = documentFragment.querySelectorAll("pre");
            fullNodes.forEach((v, _n, _l) => {
                strings.push(v.textContent || "\n");
            });
        }

        return strings.join("");
    }

    public getAnnotationsForLine(lineNr: number): Annotation[] {
        return this.annotations.filter(a => a.line === lineNr);
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

    initButtonForComment(): void {
        const codeLines = this.table.querySelectorAll(".lineno .rouge-code");
        codeLines.forEach((codeLine: HTMLTableDataCellElement) => {
            const line = codeLine.closest(".lineno");
            const idParts = line.id.split("-");
            const annotationButton: HTMLButtonElement = document.createElement("button");
            annotationButton.setAttribute("class", "annotation-button");
            annotationButton.setAttribute("data-line-id", (Number(idParts[idParts.length - 1]) - 1).toString());
            annotationButton.addEventListener("click", e => this.handleCommentButtonClick(e));

            const annotationButtonPlus = document.createElement("i");
            annotationButtonPlus.setAttribute("class", "mdi mdi-plus mdi-12");
            annotationButton.appendChild(annotationButtonPlus);

            codeLine.prepend(annotationButton);
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

    handleCommentButtonClick(clickEvent: MouseEvent): void {
        const targetButton: HTMLButtonElement = clickEvent.currentTarget as HTMLButtonElement;
        const lineId: string = targetButton.dataset["lineId"];

        const tableRowId: number = (targetButton.closest("tr") as HTMLTableRowElement).rowIndex;

        // Remove previous submission window
        const tr: HTMLTableRowElement = this.findOrCreateTableRow(+lineId, tableRowId + 1, +lineId);
        const existingAnnotationSubmissionDiv: HTMLFormElement = tr.querySelector("form.annotation-submission");
        if (existingAnnotationSubmissionDiv) {
            return;
        }

        const annotationSubmissionDiv: HTMLFormElement = this.createAnnotationSubmissionDiv(lineId);
        const annotationCell: HTMLTableDataCellElement = tr.querySelector("td.annotation-cell");
        annotationCell.append(annotationSubmissionDiv);
    }

    createAnnotationSubmissionDiv(lineId: string, annotation?: UserAnnotation): HTMLFormElement {
        const annotationSubmissionDiv: HTMLFormElement = document.createElement("form");
        const annotationSubmissionClasses = ["annotation-submission"];
        if (annotation) {
            annotationSubmissionClasses.push("annotation-edit");
        }

        annotationSubmissionDiv.setAttribute("class", annotationSubmissionClasses.join(" "));
        annotationSubmissionDiv.dataset["lineId"] = lineId;

        const inputField: HTMLTextAreaElement = document.createElement("textarea");
        inputField.setAttribute("class", "form-control");
        inputField.setAttribute("id", "submission-textarea");
        inputField.setAttribute("rows", "1");

        if (annotation) {
            inputField.textContent = annotation.annotation_text;
            inputField.setAttribute("rows", String(annotation.annotation_text.split("\n").length));
        }

        const buttonGroup: HTMLDivElement = document.createElement("div");
        buttonGroup.setAttribute("class", "annotation-submission-button-container");

        const sendButton: HTMLButtonElement = document.createElement("button");
        sendButton.setAttribute("class", "btn-text annotation-control-button annotation-submission-button");
        const sendButtonText: Text = document.createTextNode(I18n.t("js.user_annotation.send"));
        sendButton.append(sendButtonText);
        buttonGroup.append(sendButton);

        if (annotation != null && annotation.permission.delete) {
            const deleteButton: HTMLButtonElement = document.createElement("button");
            const deleteButtonText: Text = document.createTextNode(I18n.t("js.user_annotation.delete"));
            deleteButton.append(deleteButtonText);
            deleteButton.setAttribute("class", "btn-text annotation-control-button annotation-delete-button");
            deleteButton.addEventListener("click", e => annotation.handleDeleteButtonClick(e));
            buttonGroup.append(deleteButton);
        }

        const cancelButton: HTMLButtonElement = document.createElement("button");
        cancelButton.setAttribute("class", "btn-text annotation-control-button annotation-cancel-button");
        const cancelButtonText: Text = document.createTextNode(I18n.t("js.user_annotation.cancel"));
        cancelButton.append(cancelButtonText);

        buttonGroup.append(cancelButton);

        inputField.addEventListener("input", function () {
            $(inputField).height(0).height(inputField.scrollHeight);
        });

        if (annotation) {
            cancelButton.addEventListener("click", e => annotation.handleAnnotationEditCancelButtonClick(e));
            sendButton.addEventListener("click", e => annotation.handleAnnotationEditSubmissionButtonClick(e));
        } else {
            cancelButton.addEventListener("click", e => this.handleAnnotationSubmissionCancelButtonClick(e));
            sendButton.addEventListener("click", e => this.handleAnnotationSubmissionButtonClick(e));
        }

        annotationSubmissionDiv.append(inputField, buttonGroup);
        return annotationSubmissionDiv;
    }

    handleAnnotationSubmissionButtonClick(clickEvent: MouseEvent): void {
        clickEvent.preventDefault();
        const clickTarget: HTMLButtonElement = clickEvent.currentTarget as HTMLButtonElement;
        const form: HTMLFormElement = clickTarget.closest("form.annotation-submission");

        const line: number = +form.dataset["lineId"] as number;
        const text: string = (form.querySelector("#submission-textarea") as HTMLTextAreaElement).value;

        const annotation: SubmitUserAnnotation = {
            "annotation_text": text,
            "line_nr": line,
        };

        this.sendAnnotationPost(annotation)
            .done(data => {
                const createdAnnotation = new UserAnnotation(data, this.table, this);
                this.userAnnotations.push(createdAnnotation);
                createdAnnotation.createAnnotationDiv();
                form.remove();
            }).fail(error => {
                const errorList: HTMLUListElement = UserAnnotation.processErrorMessage(error.responseJSON);

                // Remove previous error list
                const previousErrorList = form.querySelector(".annotation-submission-error-list");
                previousErrorList?.remove();

                form.querySelector(".annotation-submission-button-container").appendChild(errorList);
            });
    }

    handleAnnotationSubmissionCancelButtonClick(clickEvent: MouseEvent): void {
        const clickTarget: HTMLElement = clickEvent.currentTarget as HTMLElement;
        const annotationForm = clickTarget.closest("form.annotation-submission");
        annotationForm.remove();
    }

    getAnnotationIndex(annotationIndexUrl: string): JQuery.jqXHR {
        return $.get(annotationIndexUrl);
    }

    sendAnnotationPost(annotation: SubmitUserAnnotation): JQuery.jqXHR {
        return $.post(`/${this.localePrefix}/submissions/${this.submissionId}/annotations`, {
            annotation: {
                "annotation_text": annotation.annotation_text,
                "line_nr": annotation.line_nr,
            },
        });
    }

    sendAnnotationPatch(annotation: UserAnnotation): JQuery.jqXHR {
        const data = {
            annotation: {
                "annotation_text": annotation.annotation_text,
            },
        };
        return $.ajax({
            data: JSON.stringify(data),
            url: `/${this.localePrefix}/submissions/${this.submissionId}/annotations/${annotation.id}`,
            type: "PATCH",
            contentType: "application/json",
        });
    }

    sendAnnotationDelete(annotationId: number): JQuery.jqXHR {
        return $.ajax({
            data: {},
            url: `/${this.localePrefix}/submissions/${this.submissionId}/annotations/${annotationId}`,
            type: "DELETE",
            contentType: "application/json",
        });
    }
}
