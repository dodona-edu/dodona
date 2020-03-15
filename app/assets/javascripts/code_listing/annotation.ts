import { CodeListing } from "code_listing/code_listing";
export type AnnotationType = "user" | "error" | "warning" | "info";


export abstract class Annotation {
    readonly id: number;
    protected shown: boolean = true;

    annotation: HTMLDivElement;
    protected dot: HTMLSpanElement;

    protected readonly codeListingHTML: HTMLTableElement;
    protected readonly codeListing: CodeListing;

    row: number;
    type: AnnotationType;

    protected constructor(id: number, codeListingHTML: HTMLTableElement, codeListing: CodeListing, row: number, type: AnnotationType) {
        this.id = id;
        this.codeListingHTML = codeListingHTML;
        this.codeListing = codeListing;
        this.row = row;
        this.type = type;
    }

    protected createHTML(): void {
        this.createAnnotation();
        this.createDot();
        // Shown by default, makes sure dots are correctly handled for user annotations.
        this.show();
    }

    hide(): void {
        this.annotation.classList.add("hide");
        this.shown = false;
        this.updateDot();
    }

    show(): void {
        this.annotation.classList.remove("hide");
        this.shown = true;
        this.updateDot();
    }

    protected abstract createAnnotation(): void;

    protected createDot(): void {
        const codeGutter = this.codeListingHTML.querySelector(`tr#line-${this.row} .rouge-gutter.gl`);
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

    private updateDot(): void {
        const anyHiddenOfThisType = this.codeListing.getAnnotationsForLine(this.row).filter(m => m.type === this.type).some(m => !m.shown);
        if (anyHiddenOfThisType) {
            this.dot.classList.add(`dot-${this.type}`);
        } else {
            this.dot.classList.remove(`dot-${this.type}`);
        }
    }

    protected createAnnotationRow(): HTMLTableRowElement {
        const correspondingLine: HTMLTableRowElement = this.codeListingHTML.querySelector(`#line-${this.row}`);
        const annotationRow = this.codeListingHTML.insertRow(correspondingLine.rowIndex + 1);
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotations-${this.row}`);
        const htmlTableDataCellElement = annotationRow.insertCell();
        htmlTableDataCellElement.setAttribute("class", "rouge-gutter gl");
        const annotationTDC: HTMLTableDataCellElement = annotationRow.insertCell();
        annotationTDC.setAttribute("class", "annotation-cell");
        return annotationRow;
    }
}
