import { Message, MessageData } from "code_listing/message";

export class CodeListing {
    private readonly table: HTMLTableElement;
    readonly messages: Message[];

    private _code: string;

    private readonly markingClass: string = "marked";

    private hideAllButton: HTMLButtonElement;
    private showOnlyErrorButton: HTMLButtonElement;
    private showAllButton: HTMLButtonElement;
    private messagesWereHidden: HTMLSpanElement;
    private diffSwitchPrefix: HTMLSpanElement;

    constructor(feedbackTableSelector = "table.code-listing") {
        this.table = document.querySelector(feedbackTableSelector) as HTMLTableElement;
        this.messages = [];

        if (this.table === null) {
            console.error("The code listing could not be found");
        }

        this.table.addEventListener("copy", function (e) {
            e.clipboardData.setData("text/plain", window.dodona.codeListing.getSelectededCode());
            e.preventDefault();
        });

        this.initAnnotationToggleButtons();
    }

    private initAnnotationToggleButtons(): void {
        this.hideAllButton = document.querySelector("#hide_all_annotations");
        this.showOnlyErrorButton = document.querySelector("#show_only_errors");
        this.showAllButton = document.querySelector("#show_all_annotations");
        this.messagesWereHidden = document.querySelector("#messages-were-hidden");
        this.diffSwitchPrefix = document.querySelector("#diff-switch-prefix");

        const showAllListener = (): void => {
            this.showAllAnnotations();
            this.messagesWereHidden?.remove();
        };

        this.showAllButton.addEventListener("click", showAllListener.bind(this));
        this.hideAllButton.addEventListener("click", this.hideAllAnnotations.bind(this));

        this.showOnlyErrorButton.addEventListener("click", this.compressMessages.bind(this));

        this.messagesWereHidden.addEventListener("click", () => this.showAllButton.click());
    }

    addAnnotations(messages: MessageData[]): void {
        messages.forEach(m => this.addAnnotation(m));
    }

    addAnnotation(message: MessageData): void {
        this.messages.push(new Message(this.messages.length, message, this.table, this));

        this.showAllButton.classList.remove("hide");
        this.hideAllButton.classList.remove("hide");
        this.diffSwitchPrefix.classList.remove("hide");

        if (message.type === "error") {
            this.showOnlyErrorButton.classList.remove("hide");
            this.messagesWereHidden.classList.remove("hide");
        }

        const nonErrorMEssageCount = this.createHiddenMessage(this.messages.filter(m => m.type !== "error").length);
        this.messagesWereHidden.innerHTML = "";
        this.messagesWereHidden.appendChild(nonErrorMEssageCount);
    }

    compressMessages(): void {
        this.showAllAnnotations();

        const errors = this.messages.filter(m => m.type === "error");
        if (errors.length !== 0) {
            const others = this.messages.filter(m => m.type !== "error");
            others.forEach(m => m.hide());
            errors.forEach(m => m.show());
            this.showOnlyErrorButton.classList.add("active");
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

    set code(codeString: string) {
        this._code = codeString;
    }

    get code(): string {
        return this._code;
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

    public getMessagesForLine(lineNr: number): Message[] {
        return this.messages.filter(a => a.line === lineNr);
    }

    public createHiddenMessage(count: number): HTMLAnchorElement {
        const link = document.createElement("a");

        let data = String(count);
        // Runtime for Jest does not have the i18n defined
        if (Object.prototype.hasOwnProperty.call(window, "I18n")) {
            data = I18n.t(`js.message.were_hidden.${count > 1 ? "plural" : "single"}`).replace(/{(\d)}/g, String(count));
        }
        const linkText = document.createTextNode(data);
        link.appendChild(linkText);
        return link;
    }
}
