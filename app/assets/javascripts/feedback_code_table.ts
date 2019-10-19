export class FeedbackCodeTable {
    table: Element;
    messages;

    annotationCounter: number = 0;

    constructor(messages, feedbackTableSelector = ".feedback-code-table") {
        this.table = document.querySelector(feedbackTableSelector);

        if (this.table == null) {
            console.error("The feedback table could not be found");
        }

        this.messages = messages;

        this.initAnnotations();
    }

    private initAnnotations(): void {
        for (const message of this.messages) {
            const correspondingLine = this.table.querySelector(`#line-${message.row}`);
            const annotationRow = this.createAnnotation(message, this.annotationCounter);
            message.id = this.annotationCounter;
            this.annotationCounter += 1;

            const parentElement = correspondingLine.parentElement;
            let sibling = correspondingLine.nextElementSibling;
            while (sibling.classList.contains("annotation")) {
                sibling = sibling.nextElementSibling;
            }
            parentElement.insertBefore(annotationRow, sibling);
        }
    }

    private createAnnotation(message, lineId): Element {
        const annotationRow = document.createElement("tr");
        annotationRow.setAttribute("class", "annotation");
        annotationRow.setAttribute("id", `annotation-id-${lineId}`);
        annotationRow.classList.add(`annotation-line-${message.row}`);

        const lineNumberOffset = document.createElement("td");
        const annotationLine = document.createElement("td");
        annotationLine.setAttribute("class", "annotation-text");
        annotationLine.classList.add(message.type);
        annotationLine.innerHTML = message.text;

        annotationRow.appendChild(lineNumberOffset);
        annotationRow.appendChild(annotationLine);
        return annotationRow;
    }
}
