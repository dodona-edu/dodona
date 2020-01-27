type MessageType = "error" | "warning" | "info";
const ORDERING = ["error", "warning", "info"];
interface MessageData {
    type: MessageType;
    text: string;
    row: number;
}

class Message {
    readonly id: number;
    readonly type: MessageType;
    readonly text: string;
    readonly line: number;

    private shown = true;

    private readonly codeListing: HTMLTableElement;
    private annotation: HTMLDivElement;

    constructor(id: number, m: MessageData, listing: HTMLTableElement) {
        this.id = id;
        this.type = m.type;
        this.text = m.text;
        this.line = m.row + 1; // Linter counts from 0, rouge counts from 1
        this.codeListing = listing;

        this.createAnnotation();
    }

    hide(): void {
        this.annotation.classList.add("hide");
        this.addDot();
        this.shown = false;
    }

    show(): void {
        this.annotation.classList.remove("hide");
        this.removeDot();
        this.shown = true;
    }

    private createAnnotation(): void {
        let annotationsRow: HTMLTableRowElement = this.codeListing.querySelector(`#annotations-${this.line}`);
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
        const codeRow: HTMLTableRowElement = this.codeListing.querySelector(`#line-${this.line}`);
        const annotationRow: HTMLTableRowElement = this.codeListing.insertRow(codeRow.rowIndex + 1);
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

    private addDot(): void {
        const codeLine = this.codeListing.querySelector(`tr#line-${this.line}`);
        const codeGutter = codeLine.querySelector(".rouge-gutter.gl");
        const dotChild = codeGutter.querySelectorAll(`.dot-${this.type}`);
        if (dotChild.length == 0) {
            const dot: HTMLSpanElement = document.createElement("span");
            dot.setAttribute("class", `dot dot-${this.type}`);
            codeGutter.prepend(dot);
        }
    }

    private removeDot(): void {
        const tableRow: HTMLTableRowElement = this.codeListing.querySelector(`tr#line-${this.line}`);
        const lineNumberElement: HTMLTableDataCellElement = tableRow.querySelector(".rouge-gutter.gl");
        const dotChildren = lineNumberElement.querySelectorAll(`.dot.dot-${this.type}`);
        dotChildren.forEach(removal => {
            removal.remove();
        });
    }
}

export class CodeListing {
    private readonly table: HTMLTableElement;
    private readonly messages: Message[];

    private readonly markingClass: string = "marked";

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

    addAnnotations(messages: MessageData[]): void {
        messages.forEach(m => this.addAnnotation(m));

        // TODO: clean up
        const hideExtraButton = document.querySelector("#hide_extra_annotations");
        if (hideExtraButton && hideExtraButton.classList.contains("active")) {
            this.checkForErrorAndCompress();
        }
    }

    addAnnotation(message: MessageData): void {
        this.messages.push(new Message(this.messages.length, message, this.table));
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
}
