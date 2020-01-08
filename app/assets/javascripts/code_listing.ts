interface Message {
    id?: number;

    type: string;
    text: string;
    row: number;
}

export class CodeListing {
    private readonly table: HTMLTableElement;
    private messages: Message[];

    private readonly markingClass: string = "marked";

    constructor(feedbackTableSelector = "table.code-listing") {
        this.table = document.querySelector(feedbackTableSelector) as HTMLTableElement;
        this.messages = [];

        if (this.table === null) {
            console.error("The code listing could not be found");
        }

        // Override the default copy behaviour of the browser to have a standard format for code copying.
        this.table.addEventListener("copy", function (e) {
            e.clipboardData.setData("text/plain", window.dodona.codeListing.getSelectededCode());
            e.preventDefault();
        });
    }

    addAnnotations(messages: Message[]): void {
        let idOffset: number = this.messages.length;
        for (const message of messages) {
            message.id = idOffset + 1;
            idOffset += 1;
            // Linter counts from 0, rouge counts from 1
            const correspondingLine: HTMLTableRowElement = this.table.querySelector(`#line-${message.row + 1}`);
            this.createAnnotation(message, correspondingLine.rowIndex + 1, message.row + 1);
            this.messages.push(message);
        }
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

        const textNode: Text = document.createTextNode(message.text.split("\n").filter(s => !s.match("^--*$")).join("\n"));
        annotationCell.classList.add(message.type);
        annotationCell.appendChild(textNode);

        annotationTD.appendChild(annotationCell);

        const edgeCopyBlocker = document.createElement("div");
        edgeCopyBlocker.setAttribute("class", "copy-blocker");
        annotationTD.appendChild(edgeCopyBlocker);

        return annotationRow;
    }

    clearHighlights(): void {
        const markedAnnotations = this.table.querySelectorAll(`.tr.lineno.${this.markingClass}`);
        markedAnnotations.forEach(markedAnnotation => {
            markedAnnotation.classList.remove(this.markingClass);
        });
    }

    highlightLine(lineNr: number): void {
        const toMarkAnnotationRow = this.table.querySelector(`tr.lineno#line-${lineNr}`);
        toMarkAnnotationRow.classList.add(this.markingClass);
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
