import { CodeListing } from "code_listing/code_listing";
import { SuperAnnotation, AnnotationType } from "code_listing/super_annotation";

const ORDERING = ["error", "warning", "info"];

export interface AnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
}

export class Annotation extends SuperAnnotation {
    readonly text: string;

    constructor(id: number, m: AnnotationData, listing: HTMLTableElement, codeListing: CodeListing) {
        super(id, listing, codeListing, m.row + 1, m.type);
        this.type = m.type;
        this.text = m.text;
        this.createHTML();
    }

    protected createAnnotation(): void {
        let annotationRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#annotations-${this.row}`);
        if (annotationRow === null) {
            annotationRow = this.createAnnotationRow();
        }

        this.annotation = document.createElement("div");
        this.annotation.setAttribute("title", this.type[0].toUpperCase() + this.type.substring(1));
        this.annotation.classList.add("annotation", this.type, "machine-annotation");
        this.annotation.appendChild(document.createTextNode(
            this.text.split("\n").filter(s => !s.match("^--*$")).join("\n")
        ));

        const edgeCopyBlocker = document.createElement("div");
        edgeCopyBlocker.setAttribute("class", "copy-blocker");

        let annotationGroup: HTMLDivElement = annotationRow.querySelector(`.annotation-cell .annotation-group-${this.type}`);
        if (annotationGroup == null) {
            this.createAnnotationGroups(annotationRow.querySelector(".annotation-cell"));
            annotationGroup = annotationRow.querySelector(`.annotation-cell .annotation-group-${this.type}`);
        }
        annotationGroup.appendChild(this.annotation);
        annotationGroup.appendChild(edgeCopyBlocker);
    }

    private createAnnotationRow(): HTMLTableRowElement {
        const codeRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#line-${this.row}`);
        const annotationRow: HTMLTableRowElement = this.codeListingHTML.insertRow(codeRow.rowIndex + 1);
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotations-${this.row}`);
        const htmlTableDataCellElement = annotationRow.insertCell();
        htmlTableDataCellElement.setAttribute("class", "rouge-gutter gl");
        htmlTableDataCellElement.appendChild(document.createElement("div"));
        const annotationTDC: HTMLTableDataCellElement = annotationRow.insertCell();
        annotationTDC.setAttribute("class", "annotation-cell");

        this.createAnnotationGroups(annotationTDC);

        return annotationRow;
    }

    private createAnnotationGroups(annotationTDC: HTMLTableDataCellElement): void {
        for (const type of ORDERING) {
            const groupDiv: HTMLDivElement = document.createElement("div");
            groupDiv.setAttribute("class", `annotation-group-${type}`);
            annotationTDC.appendChild(groupDiv);
        }
    }
}

