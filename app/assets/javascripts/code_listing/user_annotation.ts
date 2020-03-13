import { CodeListing } from "code_listing/code_listing";
import { Annotation } from "code_listing/annotation";
import { fetch } from "util.js";

interface UserAnnotationUserData {
    name: string;
}

interface UserAnnotationPermissionData {
    update: boolean;
    destroy: boolean;
}

export interface UserAnnotationData {
    id: number;
    annotation_text: string;
    line_nr: number;
    rendered_markdown: string;
    permission: UserAnnotationPermissionData;
    user: UserAnnotationUserData;
    url: string;
}

export class UserAnnotation extends Annotation {
    annotationData: UserAnnotationData;

    constructor(annotation: UserAnnotationData, listing: HTMLTableElement, codeListing: CodeListing) {
        super(annotation.id, listing, codeListing, annotation.line_nr + 1, "user");
        this.annotationData = annotation;

        this.createHTML();
    }

    async delete(annotationDiv: HTMLDivElement): Promise<void> {
        const response = await fetch(this.annotationData.url, { method: "DELETE" });
        if (response.ok) {
            annotationDiv.remove();
            this.codeListing.removeUserAnnotation(this);
        }
    }

    async update(newText: string, annotationDiv: HTMLDivElement, form: HTMLFormElement): Promise<void> {
        const response = await fetch(this.annotationData.url, {
            headers: { "Content-Type": "application/json" },
            method: "PATCH",
            body: JSON.stringify({ annotation: {
                // eslint-disable-next-line @typescript-eslint/camelcase
                annotation_text: newText
            } })
        });
        if (response.ok) {
            const data: UserAnnotationData = await response.json();
            annotationDiv.remove();
            this.codeListing.removeUserAnnotation(this);
            this.codeListing.addUserAnnotation(data);
        } else {
            const errorList: HTMLUListElement = UserAnnotation.processErrorMessage(await response.json());
            const previousErrorList = form.querySelector(".annotation-submission-error-list");
            previousErrorList?.remove();
            form.querySelector(".annotation-submission-button-container").appendChild(errorList);
        }
    }

    startEdit(button: HTMLSpanElement, annotationDiv: HTMLDivElement): void {
        button.classList.add("hide");
        annotationDiv.querySelector(".annotation-text").replaceWith(this.codeListing.createAnnotationSubmissionDiv(this.id, this));
    }


    cancelEdit(annotationDiv: HTMLDivElement, form: HTMLFormElement): void {
        form.replaceWith(this.createAnnotationTextDisplay());
        const annotationEditPencil: HTMLDivElement = annotationDiv.querySelector("div.annotation-control-button.annotation-edit.hide");
        annotationEditPencil.classList.remove("hide");
    }

    private createAnnotationTextDisplay(): HTMLSpanElement {
        const textSpan: HTMLSpanElement = document.createElement("span");
        textSpan.setAttribute("class", "annotation-text");

        // Markdown render is html safe
        textSpan.innerHTML = this.annotationData.rendered_markdown;
        return textSpan;
    }

    createAnnotation(): void {
        let annotationsRow: HTMLTableRowElement = this.codeListingHTML.querySelector(`#annotations-${this.row}`);
        if (annotationsRow === null) {
            annotationsRow = this.createAnnotationRow();
        }

        this.annotation = document.createElement("div");
        this.annotation.classList.add("annotation");
        this.annotation.innerHTML = `
          <div class="annotation-header">
            <span class="annotation-user">${this.annotationData.user.name}</span>
            ${this.annotationData.permission.update ? `
                  <span class="annotation-control-button annotation-edit">
                    <i class="mdi mdi-pencil"></i>
                  </span>
                ` : ""}
          </div>
          <span class="annotation-text">${this.annotationData.rendered_markdown}</span>
        `;
        annotationsRow.querySelector(".annotation-cell").appendChild(this.annotation);
        if (this.annotationData.permission.update) {
            const editButton: HTMLSpanElement = this.annotation.querySelector(".annotation-control-button.annotation-edit");
            editButton.addEventListener("click", e => {
                e.preventDefault();
                this.startEdit(editButton, this.annotation);
            });
        }
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
