import { CodeListing } from "code_listing/code_listing";

export interface SubmitUserAnnotation {
    annotation_text: string;
    line_nr: number;
}

interface UserAnnotationUserData {
    name: string;
}

interface UserAnnotationPermissionData {
    edit: boolean;
    delete: boolean;
}

export interface UserAnnotationInterface extends SubmitUserAnnotation {
    id: number;
    markdown_text: string;
    permission: UserAnnotationPermissionData;
    user: UserAnnotationUserData;
}

export class UserAnnotation implements UserAnnotationInterface {
    id: number;
    markdown_text: string;
    permission: UserAnnotationPermissionData;
    user: UserAnnotationUserData;
    annotation_text: string;
    line_nr: number;

    private readonly codeListingHTML: HTMLTableElement;
    private readonly codeListing: CodeListing;
    private annotation: HTMLDivElement;

    constructor(annotation: UserAnnotationInterface, listing: HTMLTableElement, codeListing: CodeListing) {
        this.codeListingHTML = listing;
        this.codeListing = codeListing;

        this.id = annotation.id;
        // eslint-disable-next-line @typescript-eslint/camelcase
        this.annotation_text = annotation.annotation_text;
        // eslint-disable-next-line @typescript-eslint/camelcase
        this.line_nr = annotation.line_nr + 1;
        // eslint-disable-next-line @typescript-eslint/camelcase
        this.markdown_text = annotation.markdown_text;
        this.permission = annotation.permission;
        this.user = annotation.user;
    }

    handleDeleteButtonClick(clickEvent: MouseEvent): void {
        clickEvent.preventDefault();
        if (!confirm(I18n.t("js.user_annotation.delete_confirm"))) {
            return;
        }

        const clickTarget: HTMLButtonElement = clickEvent.currentTarget as HTMLButtonElement;
        const annotationDiv: HTMLDivElement = clickTarget.closest(".annotation");
        this.codeListing.sendAnnotationDelete(this.id)
            .done(_ => {
                annotationDiv.remove();
                this.codeListing.userAnnotations = this.codeListing.userAnnotations.filter(a => a.id != this.id);
            });
    }

    handleAnnotationEditCancelButtonClick(clickEvent: MouseEvent): void {
        const clickTarget: HTMLElement = clickEvent.currentTarget as HTMLElement;
        const annotationDiv: HTMLDivElement = clickTarget.closest(".annotation");
        const annotationForm: HTMLFormElement = annotationDiv.querySelector("form.annotation-submission.annotation-edit");
        annotationForm.replaceWith(this.createAnnotationTextDisplay());
        const annotationEditPencil: HTMLDivElement = annotationDiv.querySelector("div.annotation-control-button.annotation-edit.disabled");
        annotationEditPencil.classList.remove("disabled");
    }

    private createAnnotationTextDisplay(): HTMLSpanElement {
        const textSpan: HTMLSpanElement = document.createElement("span");
        textSpan.setAttribute("class", "annotation-text");

        // Markdown render is html safe
        textSpan.innerHTML = this.markdown_text;
        return textSpan;
    }

    createAnnotationDiv(): void {
        const outsideDiv: HTMLDivElement = document.createElement("div");
        outsideDiv.setAttribute("class", "annotation");
        outsideDiv.setAttribute("data-annotation-id", String(this.id));

        const textSpan = this.createAnnotationTextDisplay();

        if (this.user) {
            const header: HTMLDivElement = document.createElement("div");
            header.setAttribute("class", "annotation-header");

            const postingUserName: HTMLSpanElement = document.createElement("span");
            postingUserName.setAttribute("class", "annotation-user");

            const postingUserText: Text = document.createTextNode(this.user.name);
            postingUserName.appendChild(postingUserText);
            header.appendChild(postingUserName);

            if (this.permission.edit) {
                const editButton: HTMLDivElement = document.createElement("div");
                editButton.setAttribute("class", "annotation-control-button annotation-edit");

                const editButtonText: HTMLElement = document.createElement("i");
                editButtonText.setAttribute("class", "mdi mdi-pencil");
                editButton.appendChild(editButtonText);
                editButton.addEventListener("click", this.handleEditButtonClick.bind(this));
                header.append(editButton);
            }

            outsideDiv.append(header);
        }

        outsideDiv.appendChild(textSpan);

        let annotationsRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#annotations-${this.line_nr}`);
        if (annotationsRow === null) {
            annotationsRow = this.createAnnotationRow();
        }

        this.annotation = outsideDiv;
        const lastCell = annotationsRow.lastChild;
        lastCell.appendChild(outsideDiv);
    }

    createAnnotationRow(): HTMLTableRowElement {
        const correspondingLine: HTMLTableRowElement = this.codeListingHTML.querySelector(`#line-${this.line_nr}`);
        const annotationRow = this.codeListingHTML.insertRow(correspondingLine.rowIndex + 1);
        annotationRow.setAttribute("class", "annotation-set");
        annotationRow.setAttribute("id", `annotations-${this.line_nr}`);
        const htmlTableDataCellElement = annotationRow.insertCell();
        htmlTableDataCellElement.setAttribute("class", "rouge-gutter gl");
        const annotationTDC: HTMLTableDataCellElement = annotationRow.insertCell();
        annotationTDC.setAttribute("class", "annotation-cell");
        return annotationRow;
    }

    handleAnnotationEditSubmissionButtonClick(clickEvent: MouseEvent): void {
        clickEvent.preventDefault();
        const clickTarget: HTMLButtonElement = clickEvent.currentTarget as HTMLButtonElement;
        const form: HTMLFormElement = clickTarget.closest("form.annotation-submission");
        const annotationContext: HTMLDivElement = form.closest("div.annotation");
        const text: string = (form.querySelector("#submission-textarea") as HTMLTextAreaElement).value;
        const annotationEditPencil: HTMLDivElement = annotationContext.querySelector("div.annotation-control-button.annotation-edit.disabled");

        // eslint-disable-next-line @typescript-eslint/camelcase
        this.annotation_text = text;
        this.codeListing.sendAnnotationPatch(this)
            .done((data: UserAnnotationInterface) => {
                const annotation = new UserAnnotation(data, this.codeListingHTML, this.codeListing);
                const annotationTextDisplay: HTMLSpanElement = annotation.createAnnotationTextDisplay();
                form.replaceWith(annotationTextDisplay);
                annotationEditPencil.classList.remove("disabled");
            }).fail(error => {
                const errorList: HTMLUListElement = UserAnnotation.processErrorMessage(error.responseJSON);

                // Remove previous error list
                const previousErrorList = form.querySelector(".annotation-submission-error-list");
                if (previousErrorList) {
                    previousErrorList.remove();
                }

                form.querySelector(".annotation-submission-button-container").appendChild(errorList);
            });
    }

    handleEditButtonClick(clickEvent: MouseEvent): void {
        clickEvent.preventDefault();
        const clickTarget: HTMLDivElement = clickEvent.currentTarget as HTMLDivElement;

        if (clickTarget.classList.contains("disabled")) {
            return;
        }

        const annotationDiv: HTMLDivElement = clickTarget.closest(".annotation");
        const lineId: string = annotationDiv.dataset.annotationId;
        const annotationText: HTMLSpanElement = annotationDiv.querySelector(".annotation-text");
        const annotationSubmissionDiv: HTMLFormElement = this.codeListing.createAnnotationSubmissionDiv(lineId, this);
        annotationText.replaceWith(annotationSubmissionDiv);
        clickTarget.classList.add("disabled");
    }

    static processErrorMessage(json: object): HTMLUListElement {
        const htmluListElement: HTMLUListElement = document.createElement("ul");
        htmluListElement.setAttribute("class", "annotation-submission-error-list");
        // eslint-disable-next-line guard-for-in
        for (const key in json) {
            const li: HTMLLIElement = document.createElement("li");
            li.setAttribute("class", "annotation-submission-error");
            const textNode: Text = document.createTextNode(`${I18n.t(`js.user_annotation.fields.${key}`)}: ${json[key]}`);
            li.append(textNode);
            htmluListElement.appendChild(li);
        }
        return htmluListElement;
    }
}
