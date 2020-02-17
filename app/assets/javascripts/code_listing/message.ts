import { CodeListing } from "code_listing/code_listing";

type MessageType = "error" | "warning" | "info";
const ORDERING = ["error", "warning", "info"];

export interface MessageData {
    type: MessageType;
    text: string;
    row: number;
}

export class Message {
    readonly id: number;
    readonly type: MessageType;
    readonly text: string;
    readonly line: number;

    private shown = true;
    private dotShown = false;

    private readonly codeListingHTML: HTMLTableElement;
    private annotation: HTMLDivElement;
    private dot: HTMLSpanElement;

    private readonly codeListing: CodeListing;

    constructor(id: number, m: MessageData, listing: HTMLTableElement, codeListing: CodeListing) {
        this.id = id;
        this.type = m.type;
        this.text = m.text;
        this.line = m.row + 1; // Linter counts from 0, rouge counts from 1
        this.codeListingHTML = listing;

        this.codeListing = codeListing;

        this.createAnnotation();
        this.createDot();
    }

    hide(): void {
        this.annotation.classList.add("hide");
        this.shown = false;
        this.addDot();
    }

    show(): void {
        this.annotation.classList.remove("hide");
        this.shown = true;
        this.removeDot();
    }

    private createAnnotation(): void {
        let annotationsRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#annotations-${this.line}`);
        if (annotationsRow === null) {
            annotationsRow = this.createAnnotationRow();
        }

        this.annotation = document.createElement("div");
        this.annotation.setAttribute("id", `annotation-${this.id}`);
        this.annotation.setAttribute("title", this.type[0].toUpperCase() + this.type.substring(1));
        this.annotation.classList.add("annotation", this.type);
        this.annotation.appendChild(document.createTextNode(
            this.text.split("\n").filter(s => !s.match("^--*$")).join("\n")
        ));

        const edgeCopyBlocker = document.createElement("div");
        edgeCopyBlocker.setAttribute("class", "copy-blocker");

        const annotationGroup: HTMLDivElement = annotationsRow.querySelector(`.annotation-cell .annotation-group-${this.type}`);
        annotationGroup.appendChild(this.annotation);
        annotationGroup.appendChild(edgeCopyBlocker);
    }

    private createAnnotationRow(): HTMLTableRowElement {
        const codeRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#line-${this.line}`);
        const annotationRow: HTMLTableRowElement = this.codeListingHTML.insertRow(codeRow.rowIndex + 1);
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotations-${this.line}`);
        annotationRow.insertCell().setAttribute("class", "rouge-gutter gl");
        const annotationTDC = annotationRow.insertCell();
        annotationTDC.setAttribute("class", "annotation-cell");

        for (const type of ORDERING) {
            const groupDiv: HTMLDivElement = document.createElement("div");
            groupDiv.setAttribute("class", `annotation-group-${type}`);
            annotationTDC.appendChild(groupDiv);
        }

        return annotationRow;
    }

    private createDot(): void {
        const codeGutter = this.codeListingHTML.querySelector(`tr#line-${this.line} .rouge-gutter.gl`);
        this.dot = document.createElement("span");
        this.dot.setAttribute("class", `dot dot-${this.type} hide`);
        let titleAttr = this.type.toString();

        // Runtime for Jest does not have the i18n defined
        if (Object.prototype.hasOwnProperty.call(window, "I18n")) {
            const translatedType = I18n.t(`js.message.type.${this.type}`);
            titleAttr = I18n.t("js.message.hidden") + " \"" + translatedType + "\"";
        }

        this.dot.setAttribute("title", titleAttr);
        codeGutter.prepend(this.dot);
    }

    addDot(): void {
        const messagesForLine = this.codeListing.getMessagesForLine(this.line);
        const ownSeverity = this.severity();
        messagesForLine.filter(m => m.dotShown && m.severity() >= ownSeverity).forEach(m => m.removeDot());
        if (messagesForLine.filter(m => m.severity() < ownSeverity && !m.shown).length !== 0) {
            return;
        }
        this.dot.classList.remove("hide");
        this.dotShown = true;
    }

    removeDot(): void {
        this.dot.classList.add("hide");
        this.dotShown = false;
    }

    severity(): number {
        return ORDERING.indexOf(this.type);
    }
}
