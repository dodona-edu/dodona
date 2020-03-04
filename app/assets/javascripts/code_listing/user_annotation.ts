import { CodeListing } from "code_listing/code_listing";
import { Annotation } from "code_listing/annotation";

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

export class UserAnnotation extends Annotation {
    markdown_text: string;
    permission: UserAnnotationPermissionData;
    user: UserAnnotationUserData;
    annotation_text: string;

    constructor(annotation: UserAnnotationInterface, listing: HTMLTableElement, codeListing: CodeListing) {
        super(annotation.id, listing, codeListing, annotation.line_nr + 1, "user");

        // eslint-disable-next-line @typescript-eslint/camelcase
        this.annotation_text = annotation.annotation_text;
        // eslint-disable-next-line @typescript-eslint/camelcase
        this.markdown_text = annotation.markdown_text;
        this.permission = annotation.permission;
        this.user = annotation.user;

        this.createHTML();
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
                this.codeListing.annotations = this.codeListing.annotations.filter(a => a.id !== this.id);
            });
    }

    handleAnnotationEditCancelButtonClick(clickEvent: MouseEvent): void {
        const clickTarget: HTMLElement = clickEvent.currentTarget as HTMLElement;
        const annotationDiv: HTMLDivElement = clickTarget.closest(".annotation");
        const annotationForm: HTMLFormElement = annotationDiv.querySelector("form.annotation-submission.annotation-edit");
        annotationForm.replaceWith(this.createAnnotationTextDisplay());
        const annotationEditPencil: HTMLDivElement = annotationDiv.querySelector("div.annotation-control-button.annotation-edit.hide");
        annotationEditPencil.classList.remove("hide");
    }

    private createAnnotationTextDisplay(): HTMLSpanElement {
        const textSpan: HTMLSpanElement = document.createElement("span");
        textSpan.setAttribute("class", "annotation-text");

        // Markdown render is html safe
        textSpan.innerHTML = this.markdown_text;
        return textSpan;
    }

    createAnnotation(): void {
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
                editButton.addEventListener("click", e => this.handleEditButtonClick(e));
                header.append(editButton);
            }

            outsideDiv.append(header);
        }

        outsideDiv.appendChild(textSpan);

        let annotationsRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#annotations-${this.row}`);
        if (annotationsRow === null) {
            annotationsRow = this.createAnnotationRow();
        }

        this.annotation = outsideDiv;
        const lastCell = annotationsRow.lastChild;
        lastCell.appendChild(outsideDiv);
    }

    handleAnnotationEditSubmissionButtonClick(clickEvent: MouseEvent): void {
        clickEvent.preventDefault();
        const clickTarget: HTMLButtonElement = clickEvent.currentTarget as HTMLButtonElement;
        const form: HTMLFormElement = clickTarget.closest("form.annotation-submission");
        const annotationContext: HTMLDivElement = form.closest("div.annotation");
        const text: string = (form.querySelector("#submission-textarea") as HTMLTextAreaElement).value;
        const annotationEditPencil: HTMLDivElement = annotationContext.querySelector("div.annotation-control-button.annotation-edit.hide");

        // eslint-disable-next-line @typescript-eslint/camelcase
        this.annotation_text = text;
        this.codeListing.sendAnnotationPatch(this)
            .done((data: UserAnnotationInterface) => {
                annotationContext.remove();
                this.codeListing.annotations = this.codeListing.annotations.filter(f => f === this);
                this.codeListing.annotations.push(new UserAnnotation(data, this.codeListingHTML, this.codeListing));
                annotationEditPencil.classList.remove("hide");
            }).fail(error => {
                const errorList: HTMLUListElement = UserAnnotation.processErrorMessage(error.responseJSON);

                // Remove previous error list
                const previousErrorList = form.querySelector(".annotation-submission-error-list");
                previousErrorList?.remove();

                form.querySelector(".annotation-submission-button-container").appendChild(errorList);
            });
    }

    handleEditButtonClick(clickEvent: MouseEvent): void {
        clickEvent.preventDefault();
        const clickTarget: HTMLDivElement = clickEvent.currentTarget as HTMLDivElement;

        const annotationDiv: HTMLDivElement = clickTarget.closest(".annotation");
        const lineId: string = annotationDiv.dataset.annotationId;
        const annotationText: HTMLSpanElement = annotationDiv.querySelector(".annotation-text");
        const annotationSubmissionDiv: HTMLFormElement = this.codeListing.createAnnotationSubmissionDiv(lineId, this);
        annotationText.replaceWith(annotationSubmissionDiv);
        clickTarget.classList.add("hide");
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
