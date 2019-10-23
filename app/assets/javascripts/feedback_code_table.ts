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
            const annotationRow = this.createAnnotation(message, this.annotationCounter);
            message.id = this.annotationCounter;
            this.annotationCounter += 1;

            // Decide the location in the list of siblings where we should insert
            // Skip over any previous annotations to conserve the order
            const parentElement = correspondingLine.parentElement;
            let sibling = correspondingLine.nextElementSibling;

            // Sibling is either a line in the middle of the code or the last line
            if (sibling === null) {
                parentElement.appendChild(annotationRow);
            } else {
                while (sibling != null && sibling.classList.contains("annotation")) {
                    sibling = sibling.nextElementSibling;
                }
                parentElement.insertBefore(annotationRow, sibling);
            }
        }
    }

    private createAnnotation(message, lineId): Element {
        const annotationRow = document.createElement("tr");
        annotationRow.setAttribute("class", "annotation");
        annotationRow.setAttribute("id", `annotation-id-${lineId}`);
        annotationRow.classList.add(`annotation-line-${message.row}`);

        const annotationLine = document.createElement("td");
        annotationLine.setAttribute("colspan", "2");

        const annotationCell = document.createElement("div");

        const textNode = document.createTextNode(message.text.replace(/-*$/, ""));
        annotationCell.setAttribute("class", "annotation-text");
        annotationCell.classList.add(message.type);
        annotationCell.appendChild(textNode);

        annotationLine.appendChild(annotationCell);
        annotationRow.appendChild(annotationLine);
        return annotationRow;
    }
}
