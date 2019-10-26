class Message {
    id: number;

    type: string;
    text: string;
    row: number;

    constructor(jsonS: object, id: number) {
        this.type = jsonS["type"];
        this.text = jsonS["text"];
        this.row = jsonS["row"];
        this.id = id;
    }
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

    addAnnotations(messages: object[]): void {
        const newMessages: Message[] = [];
        let idOffset: number = this.messages.length;
        for (const message of messages) {
            newMessages.push(new Message(message, idOffset + 1));
            idOffset += 1;
        }
        this.messages.push(...newMessages);

        for (const message of newMessages) {
            // Linter counts from 0, rouge counts from 1
            const correspondingLine: HTMLTableRowElement = this.table.querySelector(`#line-${message.row + 1}`);
            this.createAnnotation(message, correspondingLine.rowIndex + 1, message.row + 1);
        }
    }

    private createAnnotationRow(lineNumber: number, rougeRow: number): HTMLTableRowElement {
        const annotationRow: HTMLTableRowElement = this.table.insertRow(lineNumber);
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotation-row-id-${rougeRow}`);
        const annotationTD: HTMLTableDataCellElement = annotationRow.insertCell();
        annotationTD.setAttribute("colspan", "2");
        annotationTD.setAttribute("class", "annotation-cell");
        return annotationRow;
    }

    private createAnnotation(message: Message, tableIndex: number, rougeRow: number): HTMLTableRowElement {
        let annotationRow: HTMLTableRowElement = this.table.querySelector(`#annotation-row-id-${message.row + 1}`);
        if (annotationRow === null) {
            annotationRow = this.createAnnotationRow(tableIndex, rougeRow);
        }

        const annotationTD: HTMLTableDataCellElement = annotationRow.firstChild as HTMLTableDataCellElement;

        const annotationCell: HTMLDivElement = document.createElement("div");
        annotationCell.setAttribute("class", "annotation");
        annotationCell.setAttribute("id", `annotation-id-${message.id}`);

        const textNode: Text = document.createTextNode(message.text.replace(/-*$/, ""));
        annotationCell.classList.add(message.type);
        annotationCell.appendChild(textNode);

        annotationTD.appendChild(annotationCell);
        return annotationRow;
    }

    unmarkAllAnnotations(): void {
        const markedAnnotations = this.table.querySelectorAll(`.tr.lineno.${this.markingClass}`);
        markedAnnotations.forEach(markedAnnotation => {
            markedAnnotation.classList.remove(this.markingClass);
        });
    }

    setMarkedAnnotations(lineNr: number): void {
        this.unmarkAllAnnotations();

        const toMarkAnnotationRow = this.table.querySelector(`tr.lineno#line-${lineNr}`);
        toMarkAnnotationRow.classList.add(this.markingClass);
    }
}
