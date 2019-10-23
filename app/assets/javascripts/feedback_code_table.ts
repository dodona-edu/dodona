export class FeedbackCodeTable {
    table: Element;
    messages;
    annotationCounter: number = 0;

    constructor(feedbackTableSelector = ".feedback-code-table") {
        this.table = document.querySelector(feedbackTableSelector);

        if (this.table === null) {
            console.error("The feedback table could not be found");
        }
    }

    private initAnnotations(messages: object[]): void {
        this.messages = messages;
        for (const message of this.messages) {
            // Linter counts from 0, rouge counts from 1
            const correspondingLine = this.table.querySelector(`#line-${message.row + 1}`);
            const annotationRow = this.createAnnotation(message);

            correspondingLine.parentElement.insertBefore(annotationRow, correspondingLine.nextSibling);
        }
    }

    private createAnnotationRow(lineNumber: number): object {
        const annotationRow: HTMLTableRowElement = document.createElement("tr");
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotation-row-id-${lineNumber}`);

        const annotationTD: HTMLTableDataCellElement = document.createElement("td");
        annotationTD.setAttribute("colspan", "2");
        annotationTD.setAttribute("class", "annotation-cell");

        annotationRow.appendChild(annotationTD);
        return {
            "row": annotationRow,
            "datacell": annotationTD,
        };
    }

    private createAnnotation(message): Element {
        let annotationRow: HTMLTableRowElement = this.table.querySelector(`#annotation-row-id-${message.row}`);
        let annotationTD: HTMLTableDataCellElement = null;

        if (annotationRow === null) {
            const created: object = this.createAnnotationRow(message.row);
            annotationRow = created["row"];
            annotationTD = created["datacell"];
        } else {
            annotationTD = annotationRow.firstChild as HTMLTableDataCellElement;
        }

        const annotationCell: HTMLDivElement = document.createElement("div");
        annotationCell.setAttribute("class", "annotation");
        annotationCell.setAttribute("id", `annotation-id-${this.annotationCounter}`);
        this.annotationCounter += 1;

        const textNode: Text = document.createTextNode(message.text.replace(/-*$/, ""));
        annotationCell.classList.add(message.type);
        annotationCell.appendChild(textNode);

        annotationTD.appendChild(annotationCell);
        return annotationRow;
    }
}
