import { CodeListing } from "code_listing/code_listing";

type AnnotationType = "error" | "warning" | "info";
const ORDERING = ["error", "warning", "info"];

export interface AnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
}

export class Annotation {
    readonly id: number;
    readonly type: AnnotationType;
    readonly text: string;
    readonly line: number;

    private shown = true;

    private readonly codeListingHTML: HTMLTableElement;
    private message: HTMLDivElement;
    private dot: HTMLSpanElement;

    private readonly codeListing: CodeListing;

    constructor(id: number, m: AnnotationData, listing: HTMLTableElement, codeListing: CodeListing) {
        this.id = id;
        this.type = m.type;
        this.text = m.text;
        this.line = m.row + 1; // Linter counts from 0, rouge counts from 1
        this.codeListingHTML = listing;

        this.codeListing = codeListing;

        this.createMessage();
        this.createDot();
    }

    hide(): void {
        this.message.classList.add("hide");
        this.addDot();
        this.shown = false;
    }

    show(): void {
        this.message.classList.remove("hide");
        this.removeDot();
        this.shown = true;
    }

    private createMessage(): void {
        let messagesRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#messages-${this.line}`);
        if (messagesRow === null) {
            messagesRow = this.createMessageRow();
        }

        this.message = document.createElement("div");
        this.message.setAttribute("id", `messages-${this.id}`);
        this.message.setAttribute("title", this.type[0].toUpperCase() + this.type.substring(1));
        this.message.classList.add("message", this.type);
        this.message.appendChild(document.createTextNode(
            this.text.split("\n").filter(s => !s.match("^--*$")).join("\n")
        ));

        const edgeCopyBlocker = document.createElement("div");
        edgeCopyBlocker.setAttribute("class", "copy-blocker");

        const messageGroup: HTMLDivElement = messagesRow.querySelector(`.message-cell .message-group-${this.type}`);
        messageGroup.appendChild(this.message);
        messageGroup.appendChild(edgeCopyBlocker);
    }

    private createMessageRow(): HTMLTableRowElement {
        const codeRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#line-${this.line}`);
        const messageRow: HTMLTableRowElement = this.codeListingHTML.insertRow(codeRow.rowIndex + 1);
        messageRow.setAttribute("class", "message-set");
        messageRow.setAttribute("id", `messages-${this.line}`);
        const htmlTableDataCellElement = messageRow.insertCell();
        htmlTableDataCellElement.setAttribute("class", "rouge-gutter gl");
        htmlTableDataCellElement.appendChild(document.createElement("div"));
        const messageTDC: HTMLTableDataCellElement = messageRow.insertCell();
        messageTDC.setAttribute("class", "message-cell");

        for (const type of ORDERING) {
            const groupDiv: HTMLDivElement = document.createElement("div");
            groupDiv.setAttribute("class", `message-group-${type}`);
            messageTDC.appendChild(groupDiv);
        }

        return messageRow;
    }

    private createDot(): void {
        const codeGutter = this.codeListingHTML.querySelector(`tr#line-${this.line} .rouge-gutter.gl`);
        const potentialDot = codeGutter.querySelector("span.dot") as HTMLSpanElement;
        if (potentialDot !== null) {
            this.dot = potentialDot;
            return;
        }

        this.dot = document.createElement("span");
        this.dot.setAttribute("class", `dot dot-${this.type}`);

        const titleAttr = I18n.t("js.annotation.hidden");
        this.dot.setAttribute("title", titleAttr);

        codeGutter.prepend(this.dot);
    }

    addDot(): void {
        this.dot.classList.add(`dot-${this.type}`);
    }

    removeDot(): void {
        const allHiddenOfThisType = this.codeListing.getAnnotationsForLine(this.line).filter(m => m.type === this.type).every(m => m.shown);
        if (allHiddenOfThisType) {
            this.dot.classList.remove(`dot-${this.type}`);
        }
    }
}

