interface Message {
    id?: number;

    type: string;
    text: string;
    row: number;
}

export class FeedbackCodeTable {
    table: HTMLTableElement;
    messages: Message[];

    private markingClass: string = "marked";

    constructor(feedbackTableSelector = "table.feedback-code-table") {
        this.table = document.querySelector(feedbackTableSelector) as HTMLTableElement;
        this.messages = [];

        if (this.table === null) {
            console.error("The feedback table could not be found");
        }
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
        let annotationRow: HTMLTableRowElement = this.table.querySelector(`#annotation-row-id-${message.row + 1}`);
        if (annotationRow === null) {
            annotationRow = this.createAnnotationRow(tableIndex, rougeRow);
        }

        const annotationTD: HTMLTableDataCellElement = annotationRow.lastChild as HTMLTableDataCellElement;

        const annotationCell: HTMLDivElement = document.createElement("div");
        annotationCell.setAttribute("class", "annotation");
        annotationCell.setAttribute("id", `annotation-id-${message.id}`);

        const textNode: Text = document.createTextNode(message.text.replace(/-*$/, ""));
        annotationCell.classList.add(message.type);
        annotationCell.appendChild(textNode);

        annotationTD.appendChild(annotationCell);
        return annotationRow;
    }

    clearHighlights(): void {
        const markedAnnotations = this.table.querySelectorAll(`.tr.lineno.${this.markingClass}`);
        markedAnnotations.forEach(markedAnnotation => {
            markedAnnotation.classList.remove(this.markingClass);
        });
    }

    highlightLine(lineNr: number): void {
        this.clearHighlights();

        const toMarkAnnotationRow = this.table.querySelector(`tr.lineno#line-${lineNr}`);
        toMarkAnnotationRow.classList.add(this.markingClass);
    }

    setSubmissionEditorCode(editor): void {
        const submissionCode = [];
        document.querySelectorAll(".lineno .rouge-code")
            .forEach( codeLine => submissionCode.push(codeLine.textContent));
        editor.setValue(submissionCode.join(""), 1);
    }
}
