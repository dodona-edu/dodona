type MessageType = "error" | "warning" | "info";
interface MessageData {
    id?: number;
    type: MessageType;
    text: string;
    row: number;
}

class Message {
    id: number;
    readonly type: MessageType;
    readonly text: string;
    readonly row: number;

    private shown = true;

    private element: HTMLDivElement;

    constructor(m: MessageData) {
        this.id = m.id;
        this.type = m.type;
        this.text = m.text;
        this.row = m.row;
    }

    setElement(element: HTMLDivElement): void {
        this.element = element;
    }

    hide(): void {
        if (this.element) {
            this.element.classList.add("hide");
            this.addDot();
        }
    }

    show(): void {
        if (this.element) {
            this.element.classList.remove("hide");
            this.removeDot();
        }
    }

    private addDot(): void {
        if (this.element) {
            const tableRow: HTMLTableRowElement = this.element.closest("tr.annotation-set");
            const lineNumberElement: HTMLTableDataCellElement = tableRow.querySelector(".rouge-gutter.gl");

            const dotChild = lineNumberElement.querySelectorAll(`.dot-${this.type}`);
            if (dotChild.length == 0) {
                const dot: HTMLSpanElement = document.createElement("span");
                dot.setAttribute("class", `dot dot-${this.type}`);
                lineNumberElement.appendChild(dot);
            }
        }
    }

    private removeDot(): void {
        if (this.element) {
            const tableRow: HTMLTableRowElement = this.element.closest("tr.annotation-set");
            const lineNumberElement: HTMLTableDataCellElement = tableRow.querySelector(".rouge-gutter.gl");
            const dotChildren = lineNumberElement.querySelectorAll(`.dot.dot-${this.type}`);
            dotChildren.forEach(removal => {
                removal.remove();
            });
        }
    }
}

export class CodeListing {
    private readonly table: HTMLTableElement;
    private readonly messages: Message[];

    private readonly markingClass: string = "marked";
    private static readonly ORDERING = ["error", "warning", "info"];


    constructor(feedbackTableSelector = "table.code-listing") {
        this.table = document.querySelector(feedbackTableSelector) as HTMLTableElement;
        this.messages = [];

        if (this.table === null) {
            console.error("The code listing could not be found");
        }
        this.initButtonsForView();

        this.table.addEventListener("copy", function (e) {
            e.clipboardData.setData("text/plain", window.dodona.codeListing.getSelectededCode());
            e.preventDefault();
        });
    }

    private initButtonsForView(): void {
        const hideAllButton: HTMLButtonElement = document.querySelector("#hide_all_annotations");
        const showOnlyErrorButton: HTMLButtonElement = document.querySelector("#show_only_errors");
        const showAllButton: HTMLButtonElement = document.querySelector("#show_all_annotations");

        const messagesWereHidden = document.querySelector("#messages-were-hidden");
        const showAllListener = (): void => {
            this.showAllAnnotations();
            if (messagesWereHidden) {
                messagesWereHidden.remove();
            }
        };

        if (hideAllButton && showAllButton) {
            showAllButton.addEventListener("click", showAllListener.bind(this));
            hideAllButton.addEventListener("click", this.hideAllAnnotations.bind(this));
        }

        if (showOnlyErrorButton && hideAllButton && showAllButton) {
            showOnlyErrorButton.addEventListener("click", this.checkForErrorAndCompress.bind(this));
        }

        if (messagesWereHidden && showAllButton) {
            messagesWereHidden.addEventListener("click", () => showAllButton.click());
        }
    }

    removeAllAnnotations(): void {
        this.table.querySelectorAll(".annotation").forEach(annotation => {
            const potentialCopyBlocker: HTMLDivElement = annotation.nextSibling as HTMLDivElement;
            annotation.remove();
            if (potentialCopyBlocker.classList.contains("copy-blocker")) {
                potentialCopyBlocker.remove();
            }
        });
    }

    addAnnotations(messages: MessageData[]): void {
        let idOffset: number = this.messages.length;

        this.removeAllAnnotations();
        const messageObj = messages.map(m => new Message(m));
        this.messages.push(...messageObj);

        this.messages.sort((a, b) => {
            return CodeListing.ORDERING.indexOf(a.type) - CodeListing.ORDERING.indexOf(b.type);
        });

        for (const message of this.messages) {
            message.id = idOffset + 1;
            idOffset += 1;
            // Linter counts from 0, rouge counts from 1
            const correspondingLine: HTMLTableRowElement = this.table.querySelector(`#line-${message.row + 1}`);
            this.createAnnotation(message, correspondingLine.rowIndex + 1, message.row + 1);
        }

        const hideExtraButton = document.querySelector("#hide_extra_annotations");
        if (hideExtraButton && hideExtraButton.classList.contains("active")) {
            this.checkForErrorAndCompress();
        }
    }

    checkForErrorAndCompress(): void {
        this.showAllAnnotations();

        const errors = this.messages.filter(m => m.type === "error");
        if (errors.length != 0) {
            const others = this.messages.filter(m => m.type !== "error");
            others.forEach(m => m.hide());
        }
    }

    showAllAnnotations(): void {
        this.messages.forEach(m => m.show());
    }

    hideAllAnnotations(): void {
        this.messages.forEach(m => m.hide());
    }

    private createAnnotationRow(lineNumber: number, rougeRow: number): HTMLTableRowElement {
        const annotationRow: HTMLTableRowElement = this.table.insertRow(lineNumber);
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotation-row-id-${rougeRow}`);
        const gutterTD: HTMLTableDataCellElement = annotationRow.insertCell();
        gutterTD.setAttribute("class", "rouge-gutter gl");
        const annotationTD: HTMLTableDataCellElement = annotationRow.insertCell();
        annotationTD.setAttribute("class", "annotation-cell");
        return annotationRow;
    }

    private createAnnotation(message: Message, tableIndex: number, rougeRow: number): HTMLTableRowElement {
        if (message.text.match("^--*$")) {
            return null;
        }

        let annotationRow: HTMLTableRowElement = this.table.querySelector(`#annotation-row-id-${message.row + 1}`);
        if (annotationRow === null) {
            annotationRow = this.createAnnotationRow(tableIndex, rougeRow);
        }

        const annotationTD: HTMLTableDataCellElement = annotationRow.lastChild as HTMLTableDataCellElement;

        const annotationCell: HTMLDivElement = document.createElement("div");
        annotationCell.setAttribute("class", "annotation");
        annotationCell.setAttribute("id", `annotation-id-${message.id}`);
        annotationCell.setAttribute("title", message.type[0].toUpperCase() + message.type.substring(1));
        annotationCell.dataset.type = message.type;

        const textNode: Text = document.createTextNode(message.text.split("\n").filter(s => !s.match("^--*$")).join("\n"));
        annotationCell.classList.add(message.type);
        annotationCell.appendChild(textNode);

        annotationTD.appendChild(annotationCell);
        message.setElement(annotationCell);

        const edgeCopyBlocker = document.createElement("div");
        edgeCopyBlocker.setAttribute("class", "copy-blocker");
        annotationTD.appendChild(edgeCopyBlocker);

        return annotationRow;
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

    getCode(): string {
        const submissionCode = [];
        this.table.querySelectorAll(".lineno .rouge-code")
            .forEach(codeLine => submissionCode.push(codeLine.textContent.replace(/\n$/, "")));
        return submissionCode.join("\n");
    }

    private getSelectededCode(): string {
        const selection = window.getSelection();
        const strings = [];

        // A selection can have many different selected ranges
        // Firefox: Selecting multiple rows in a table -> Multiple ranges, with the final one possibly being a preformatted node, while the original content of the selection was a part of a div
        // Chrome: Selecting multiple rows in a table -> Single range that lists everything in HTML order (even observed some gutter elements)
        for (let rangeIndex = 0; rangeIndex < selection.rangeCount; rangeIndex++) {
            // Extract the selected HTML ranges into a DocumentFragment
            const documentFragment = selection.getRangeAt(rangeIndex).cloneContents();

            // Remove any gutter element or annotation element in the document fragment
            // As observed, some browsers (Safari) can ignore user-select: none, and as such allow the user to select line numbers.
            // To avoid any problems later we remove anything in a rouge-gutter or annotation-set class.
            // TODO: When adding user annotations, edit this to make sure only code remains. The class is being changed
            documentFragment.querySelectorAll(".rouge-gutter, .annotation-set").forEach(n => n.remove());

            // Only select the preformatted nodes as they will contain the code (with trailing newline)
            // In the case of an empty line (empty string), a newline is substituted.
            const fullNodes = documentFragment.querySelectorAll("pre");
            fullNodes.forEach((v, _n, _l) => {
                strings.push(v.textContent || "\n");
            });
        }

        return strings.join("");
    }
}
