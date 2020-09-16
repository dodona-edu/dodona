import { Annotation, AnnotationType } from "code_listing/annotation";
import { MachineAnnotation, MachineAnnotationData } from "code_listing/machine_annotation";
import {
    UserAnnotation,
    UserAnnotationData,
    UserAnnotationFormData
} from "code_listing/user_annotation";
import { createUserAnnotation, getAllUserAnnotations } from "code_listing/question_annotation";

const annotationGlobalAdd = "#add_global_annotation";
const annotationsGlobal = "#feedback-table-global-annotations";
const annotationsGlobalGroups = "#feedback-table-global-annotations-list";
const annotationHideAll = "#hide_all_annotations";
const annotationShowAll = "#show_all_annotations";
const annotationShowErrors = "#show_only_errors";
const annotationToggles = "#annotations_toggles";
const annotationFormCancel = ".annotation-cancel-button";
const annotationFormDelete = ".annotation-delete-button";
const annotationFormSubmit = ".annotation-submission-button";
const badge = "#badge_code";

type OrderGroup = "error" | "conversation" | "warning" | "info";

// Map in which annotation group the annotation should appear.
const GROUP_MAPPING: Record<AnnotationType, OrderGroup> = {
    "error": "error",
    "user": "conversation",
    "warning": "warning",
    "info": "info",
    "question": "conversation"
};

// Order the groups. We use the same order as appearance in the mapping.
const GROUP_ORDER: OrderGroup[] = Array.from(new Set(Object.values(GROUP_MAPPING)));

export class CodeListing {
    private readonly annotations: Map<number, Annotation[]>;

    public readonly code: string;
    public readonly codeLines: number;
    public readonly submissionId: number;

    private readonly markingClass: string = "marked";
    private evaluationId: number;

    private readonly badge: HTMLSpanElement;
    private readonly table: HTMLTableElement;

    private readonly globalAnnotations: HTMLDivElement;
    private readonly globalAnnotationGroups: HTMLDivElement;
    private readonly hideAllAnnotations: HTMLButtonElement;
    private readonly showAllAnnotations: HTMLButtonElement;
    private readonly showErrorAnnotations: HTMLButtonElement;
    private readonly annotationToggles: HTMLDivElement;

    private readonly questionMode: boolean;

    constructor(submissionId: number, code: string, codeLines: number, questionMode: boolean = false) {
        this.annotations = new Map<number, Annotation[]>();
        this.code = code;
        this.codeLines = codeLines;
        this.submissionId = submissionId;
        this.questionMode = questionMode;

        this.badge = document.querySelector<HTMLSpanElement>(badge);
        this.table = document.querySelector<HTMLTableElement>("table.code-listing");

        this.hideAllAnnotations = document.querySelector<HTMLButtonElement>(annotationHideAll);
        this.showAllAnnotations = document.querySelector<HTMLButtonElement>(annotationShowAll);
        this.showErrorAnnotations = document.querySelector<HTMLButtonElement>(annotationShowErrors);
        this.annotationToggles = document.querySelector<HTMLDivElement>(annotationToggles);

        this.globalAnnotations = document.querySelector<HTMLDivElement>(annotationsGlobal);
        this.globalAnnotationGroups = document.querySelector<HTMLDivElement>(annotationsGlobalGroups);

        this.initAnnotations();
    }

    setEvaluation(id: number): void {
        this.evaluationId = id;
    }

    // /////////////////////////////////////////////////////////////////////////
    // Highlighting ////////////////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

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

    // /////////////////////////////////////////////////////////////////////////
    // Annotation management ///////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    public addAnnotation(annotation: Annotation): void {
        const line = annotation.global ? 0 : annotation.line;

        if (!this.annotations.has(line)) {
            this.annotations.set(line, []);
        }

        // Add the annotation in the map.
        this.annotations.get(line).push(annotation);

        // Append the HTML component of the annotation to the code table.
        if (annotation.global) {
            this.appendAnnotationToGlobal(annotation);
        } else {
            this.appendAnnotationToTable(annotation);
        }

        this.updateViewState();
    }

    private addMachineAnnotation(data: MachineAnnotationData): void {
        const annotation = new MachineAnnotation(data);
        this.addAnnotation(annotation);
    }

    // noinspection JSUnusedGlobalSymbols used by FeedbackCodeRenderer.
    public addMachineAnnotations(annotations: MachineAnnotationData[]): void {
        annotations.forEach(ma => this.addMachineAnnotation(ma));
    }

    // Unit-testing purposes.
    private addUserAnnotation(data: UserAnnotationData): void {
        const annotation = new UserAnnotation(data,
            (a, cb) => this.createUpdateAnnotationForm(a, cb));
        this.addAnnotation(annotation);
    }

    // Unit-testing purposes.
    public addUserAnnotations(annotations: UserAnnotationData[]): void {
        annotations.forEach(ua => this.addUserAnnotation(ua));
    }

    // noinspection JSUnusedGlobalSymbols used by FeedbackCodeRenderer.
    public async loadUserAnnotations(): Promise<void> {
        return getAllUserAnnotations(this.submissionId,
            (a, cb) => this.createUpdateAnnotationForm(a, cb))
            .then(annotations => {
                annotations.forEach(annotation => this.addAnnotation(annotation));
            });
    }

    public removeAnnotation(annotation: Annotation): void {
        const line = annotation.global ? 0 : annotation.line;

        // Remove the annotation from the map.
        const lineAnnotations = this.annotations.get(line).filter(a => a.__id !== annotation.__id);
        if (lineAnnotations.length === 0) {
            this.annotations.delete(line);

            // Remove the padding from the annotation list.
            if (annotation.global) {
                this.globalAnnotations.classList.remove("has-annotations");
            }
        } else {
            this.annotations.set(line, lineAnnotations);
        }

        this.updateViewState();
    }

    public updateAnnotation(original: Annotation, updated: Annotation): void {
        const origLine = original.global ? 0 : original.line;
        const updLine = updated.global ? 0 : updated.line;

        // Different line -> can simply remove and re-add.
        if (origLine !== updLine) {
            this.removeAnnotation(original);
            this.addAnnotation(updated);
            return;
        }

        // Find the annotation in the map.
        const lineAnnotations = this.annotations.get(origLine);
        lineAnnotations.forEach((annotation, idx) => {
            if (annotation.__id === original.__id) {
                lineAnnotations[idx] = updated;
            }
        });
        this.annotations.set(updLine, lineAnnotations);

        // Replace the HTML component.
        document.querySelector(`#annotation-div-${original.__id}`).replaceWith(updated.html);
    }

    // /////////////////////////////////////////////////////////////////////////
    // DOM operations //////////////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    private appendAnnotationToGlobal(annotation: Annotation): void {
        // Append the annotation.
        this.globalAnnotationGroups
            .querySelector<HTMLDivElement>(`.annotation-group-${GROUP_MAPPING[annotation.type]}`)
            .appendChild(annotation.html);

        // Add the padding to the global annotation list.
        this.globalAnnotations.classList.add("has-annotations");
    }

    private appendAnnotationToTable(annotation: Annotation): void {
        const line = Math.min(annotation.line, this.codeLines);
        const row = this.table.querySelector<HTMLTableRowElement>(`#line-${line}`);

        const cell = row.querySelector<HTMLDivElement>(`#annotation-cell-${line}`);
        if (cell.querySelector(`.annotation-group-${GROUP_MAPPING[annotation.type]}`) === null) {
            // Create the dot.
            const dot = document.createElement("span") as HTMLSpanElement;
            dot.classList.add("dot", "hide");
            dot.id = `dot-${line}`;
            row.querySelector<HTMLTableDataCellElement>(".rouge-gutter").prepend(dot);

            // Create annotation groups.
            GROUP_ORDER.forEach((type: string) => {
                const group = document.createElement("div") as HTMLDivElement;
                group.classList.add(`annotation-group-${type}`);
                cell.appendChild(group);
            });
        }

        // Append the annotation.
        cell.querySelector<HTMLDivElement>(`.annotation-group-${GROUP_MAPPING[annotation.type]}`)
            .appendChild(annotation.html);
    }

    // //////////////////////////////////////////////////////////////////////////
    // Initialisations //////////////////////////////////////////////////////////
    // //////////////////////////////////////////////////////////////////////////

    private initAnnotations(): void {
        // Create global annotation groups.
        GROUP_ORDER.forEach((type: string) => {
            const group = document.createElement("div") as HTMLDivElement;
            group.classList.add(`annotation-group-${type}`);
            this.globalAnnotationGroups.appendChild(group);
        });

        // Create annotation cells.
        for (let i = 1; i <= this.codeLines; ++i) {
            const tableLine = this.table.querySelector<HTMLTableRowElement>(`#line-${i}`);
            tableLine.dataset["line"] = i.toString();
            // Add an annotation container underneath the pre element.
            const lineCodeCell = tableLine.querySelector<HTMLTableDataCellElement>(".rouge-code");
            const annotationContainer = document.createElement("div") as HTMLDivElement;
            annotationContainer.classList.add("annotation-cell");
            annotationContainer.id = `annotation-cell-${i}`;
            lineCodeCell.appendChild(annotationContainer);
        }

        // Toggle buttons.
        this.hideAllAnnotations.addEventListener("click", () => this.hideAnnotations());
        this.showAllAnnotations.addEventListener("click", () => this.showAnnotations());
        this.showErrorAnnotations.addEventListener("click", () => this.hideAnnotations(true));
    }

    // noinspection JSUnusedGlobalSymbols used by FeedbackCodeRenderer.
    public initAnnotateButtons(): void {
        // Global annotations.
        const globalButton = document.querySelector(annotationGlobalAdd);
        globalButton.addEventListener("click", () => this.handleAnnotateGlobal());

        const type = this.questionMode ? "user_question" : "user_annotation";
        const title = I18n.t(`js.${type}.send`);

        // Inline annotations.
        const codeLines = this.table.querySelectorAll(".lineno");
        codeLines.forEach((codeLine: HTMLTableRowElement) => {
            const annotationButton = document.createElement("button") as HTMLButtonElement;
            annotationButton.classList.add("btn", "btn-primary", "annotation-button");
            annotationButton.addEventListener("click", () => this.handleAnnotateLine(codeLine));
            annotationButton.title = title;

            const annotationButtonIcon = document.createElement("i") as HTMLElement;
            const clazz = this.questionMode ? "mdi-comment-question-outline" : "mdi-comment-plus-outline";
            annotationButtonIcon.classList.add("mdi", clazz, "mdi-18");
            annotationButton.appendChild(annotationButtonIcon);

            codeLine.querySelector(".rouge-gutter").prepend(annotationButton);
        });
    }

    // /////////////////////////////////////////////////////////////////////////
    // Show and hide annotations ///////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    public hideAnnotations(keepImportant = false): void {
        this.annotations.forEach((annotations, _line) => {
            // Do not hide global annotations.
            if (_line === 0) {
                return;
            }
            const line = Math.min(_line, this.codeLines);

            // Find the dot for this line.
            const dot = this.table.querySelector<HTMLSpanElement>(`#dot-${line}`);

            // Determine the colours of the dot for this line.
            const colours = annotations
                .filter(annotation => !annotation.important || !keepImportant)
                .map(annotation => `dot-${annotation.type}`);

            // Configure the dot.
            if (colours.length > 0) {
                // Remove previous colours.
                dot.classList.remove("hide", ...GROUP_ORDER.map(type => `dot-${type}`));

                // Add new colours.
                dot.classList.add(...colours);

                // Help text.
                const count = annotations.length;
                if (count === 1) {
                    dot.title = I18n.t("js.annotation.hidden.single");
                } else {
                    dot.title = I18n.t("js.annotation.hidden.plural", { count: count });
                }
            } else {
                // Hide the dot.
                dot.classList.add("hide");
            }
        });

        this.annotations.forEach(annotations => annotations.forEach(annotation => {
            if (annotation.global || (keepImportant && annotation.important)) {
                annotation.show();
            } else {
                annotation.hide();
            }
        }));
    }

    public showAnnotations(): void {
        this.annotations.forEach(annotations => {
            annotations.forEach(annotation => annotation.show());
        });

        // Hide all dots.
        this.table.querySelectorAll<HTMLSpanElement>(".dot").forEach(dot => {
            dot.classList.add("hide");
        });
    }

    // /////////////////////////////////////////////////////////////////////////
    // Creating and modifying user annotations /////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    private createAnnotationForm(id: string,
        annotation: Annotation | null,
        onSubmit: (f: HTMLFormElement) => Promise<void>,
        onCancel: (f: HTMLFormElement) => void): HTMLFormElement {
        const form = document.createElement("form") as HTMLFormElement;
        const type = this.questionMode ? "user_question" : "user_annotation";

        form.classList.add("annotation-submission");
        form.id = id;
        form.innerHTML = `
          <textarea autofocus class="form-control annotation-submission-input" rows="3"></textarea>
          <span class='help-block'>${I18n.t("js.user_annotation.help")}</span>
          <div class="annotation-submission-button-container">
            ${annotation && annotation.removable ? `
                  <button class="btn-text annotation-control-button annotation-delete-button" type="button">
                    ${I18n.t("js.user_annotation.delete")}
                  </button>
                ` : ""}
            <button class="btn-text annotation-control-button annotation-cancel-button" type="button">
              ${I18n.t("js.user_annotation.cancel")}
            </button>
            <button class="btn btn-text btn-primary annotation-control-button annotation-submission-button" type="button">
                ${(annotation !== null ? I18n.t(`js.${type}.update`) : I18n.t(`js.${type}.send`))}
            </button>
          </div>
        `;

        const cancelButton = form.querySelector<HTMLButtonElement>(annotationFormCancel);
        const deleteButton = form.querySelector<HTMLButtonElement>(annotationFormDelete);
        const sendButton = form.querySelector<HTMLButtonElement>(annotationFormSubmit);
        const inputField = form.querySelector<HTMLTextAreaElement>("textarea");

        if (annotation !== null) {
            inputField.rows = annotation.rawText.split("\n").length + 1;
            inputField.textContent = annotation.rawText;
        }

        // Cancellation handler.
        cancelButton.addEventListener("click", () => onCancel(form));

        // Deletion handler.
        if (deleteButton !== null) {
            deleteButton.addEventListener("click", async () => {
                const type = this.questionMode ? "user_question" : "user_annotation";
                const confirmText = I18n.t(`js.${type}.delete_confirm`);
                if (confirm(confirmText)) {
                    annotation.remove().then(() => this.removeAnnotation(annotation));
                }
            });
        }

        // Submission handler.
        sendButton.addEventListener("click", async () => {
            if (sendButton.getAttribute("disabled") !== "1") {
                sendButton.setAttribute("disabled", "1");
                await onSubmit(form);
                sendButton.removeAttribute("disabled");
                // Ask MathJax to search for math in the annotations
                if (window.MathJax === undefined) {
                    console.error("MathJax is not initialized");
                } else {
                    window.MathJax.typeset();
                }
            }
        });

        inputField.addEventListener("keydown", e => {
            if (e.code === "Enter" && e.shiftKey) {
                // Send using Shift-Enter.
                e.preventDefault();
                sendButton.click();
                return false;
            } else if (e.code === "Escape") {
                // Cancel using ESC.
                e.preventDefault();
                cancelButton.click();
                return false;
            }
        });

        return form;
    }

    private createNewAnnotationForm(line: number | null): HTMLFormElement {
        const onSubmit = async (form: HTMLFormElement): Promise<void> => {
            const inputField = form.querySelector<HTMLTextAreaElement>("textarea");
            inputField.classList.remove("validation-error");

            const annotationData: UserAnnotationFormData = {
                "annotation_text": inputField.value,
                "line_nr": (line === null ? null : line - 1),
                "evaluation_id": this.evaluationId || undefined
            };

            try {
                const annotation = await createUserAnnotation(annotationData, this.submissionId,
                    (a, cb) => this.createUpdateAnnotationForm(a, cb));
                this.addAnnotation(annotation);
                form.remove();
            } catch (err) {
                inputField.classList.add("validation-error");
            }
        };

        return this.createAnnotationForm(`annotation-submission-new-${line || 0}`,
            null, onSubmit, form => form.remove());
    }

    private createUpdateAnnotationForm(annotation: UserAnnotation,
        callback: CallableFunction): HTMLFormElement {
        const onSubmit = async (form: HTMLFormElement): Promise<void> => {
            const inputField = form.querySelector<HTMLTextAreaElement>("textarea");

            const annotationData: UserAnnotationFormData = {
                "annotation_text": inputField.value,
                "line_nr": (annotation.line === null ? null : annotation.line - 1),
                "evaluation_id": annotation.evaluationId || undefined
            };

            try {
                const updated = await annotation.update(annotationData);
                this.updateAnnotation(annotation, updated);
            } catch (err) {
                inputField.classList.add("validation-error");
            }
        };

        const formId = `annotation-submission-update-${annotation.id}`;
        return this.createAnnotationForm(formId, annotation, onSubmit, () => callback());
    }

    private handleAnnotateGlobal(): void {
        // Attempt to find an existing form and reuse that.
        const formId = "#annotation-submission-0";
        let form = this.globalAnnotations.querySelector<HTMLFormElement>(formId);
        if (form === null) {
            form = this.createNewAnnotationForm(null);

            // Inject the form into the div.
            this.globalAnnotations.prepend(form);
        }

        // Focus the input field. We must wait till the next frame, because we can only give the
        // focus after the element is added to the dom.
        const input = form.querySelector<HTMLTextAreaElement>(".annotation-submission-input");
        window.requestAnimationFrame(() => input.focus());
    }

    private handleAnnotateLine(row: HTMLTableRowElement): void {
        const lineNo = parseInt(row.dataset["line"]);

        // Attempt to find an existing form and reuse that.
        let form = row.querySelector<HTMLFormElement>(`#annotation-submission-new-${lineNo}`);
        if (form === null) {
            form = this.createNewAnnotationForm(lineNo);
            // Inject the form into the table.
            const cell = row.querySelector<HTMLTableDataCellElement>(`#annotation-cell-${lineNo}`);
            cell.prepend(form);
        }

        // Focus the input field. We must wait till the next frame, because we can only give the
        // focus after the element is added to the dom.
        const input = form.querySelector<HTMLTextAreaElement>(".annotation-submission-input");
        window.requestAnimationFrame(() => input.focus());
    }

    // /////////////////////////////////////////////////////////////////////////
    // Update view /////////////////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    private get annotationCount(): number {
        return Array.from(this.annotations.values())
            .map(ann => ann.length)
            .reduce((acc, nw) => acc + nw, 0);
    }

    /**
     * Updates the badge count and button visibility state.
     */
    private updateViewState(): void {
        const amount = this.annotationCount;
        if (amount > 0) {
            // Set the badge count.
            this.badge.innerText = amount.toString();

            // Find the important annotations.
            const importantAnnotationCount = Array.from(this.annotations.values())
                .map(annotations => annotations.filter(an => an.important).length)
                .reduce((acc, nw) => acc + nw);
            if (importantAnnotationCount === 0 || importantAnnotationCount === amount) {
                this.showErrorAnnotations.classList.add("hide");
            } else {
                this.showErrorAnnotations.classList.remove("hide");
            }

            // Show the annotation toggles.
            this.annotationToggles.classList.remove("hide");

            // Ask MathJax to search for math in the annotations
            if (window.MathJax === undefined) {
                console.error("MathJax is not initialized");
            } else {
                window.MathJax.typeset();
            }
        } else {
            // No annotations have been added (yet).
            this.badge.innerText = "";

            // Hide the annotation toggles.
            this.annotationToggles.classList.add("hide");
        }
    }
}
