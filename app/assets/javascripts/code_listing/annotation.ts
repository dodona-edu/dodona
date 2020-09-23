export type AnnotationType = "error" | "info" | "user" | "warning" | "question";
export type QuestionState = "unanswered" | "answered" | "in_progress";

export abstract class Annotation {
    private static idCounter = 0;

    protected __html: HTMLDivElement | null;

    public readonly __id;
    public readonly line: number | null;
    public readonly text: string;
    public readonly type: AnnotationType;

    protected constructor(line: number | null, text: string, type: AnnotationType) {
        this.__html = null;
        this.__id = Annotation.idCounter++;
        this.line = line;
        this.text = text;
        this.type = type;
    }

    protected get body(): HTMLSpanElement {
        const body = document.createElement("span") as HTMLSpanElement;
        body.classList.add("annotation-text");
        body.innerHTML = this.text;
        return body;
    }

    protected get class(): string | null {
        return null;
    }

    protected edit(): void {
        // Do nothing.
    }

    public get global(): boolean {
        return this.line === null;
    }

    public hide(): void {
        this.__html.classList.add("hide");
    }

    private get header(): HTMLDivElement {
        const header = document.createElement("div") as HTMLDivElement;
        header.classList.add("annotation-header");

        // Metadata.
        const meta = document.createElement("span") as HTMLSpanElement;
        meta.classList.add("annotation-meta");
        meta.textContent = this.meta;
        header.appendChild(meta);

        if (!this.visible) {
            const icon = document.createElement("i");
            icon.classList.add("mdi", "mdi-eye-off", "mdi-18", "annotation-visibility");
            icon.title = I18n.t("js.user_annotation.not_released");
            meta.appendChild(icon);
        }

        // Update button.
        if (this.modifiable) {
            const link = document.createElement("a");
            link.addEventListener("click", () => this.edit());
            link.classList.add("btn", "btn-icon", "annotation-control-button", "annotation-edit");
            link.title = this.editTitle;

            const icon = document.createElement("i");
            icon.classList.add("mdi", "mdi-pencil");
            link.appendChild(icon);

            header.appendChild(link);
        }

        if (this.transitionable("answered")) {
            const link = document.createElement("a");
            link.addEventListener("click", () => this.transition("answered"));
            link.classList.add("btn", "btn-icon", "question-control-button", "question-resolve");
            link.title = I18n.t("js.user_question.resolve");

            const icon = document.createElement("i");
            icon.classList.add("mdi", "mdi-check");
            link.appendChild(icon);

            header.appendChild(link);
        }

        if (this.transitionable("in_progress")) {
            const link = document.createElement("a");
            link.addEventListener("click", () => this.transition("in_progress"));
            link.classList.add("btn", "btn-icon", "question-control-button", "question-in_progress");
            link.title = I18n.t("js.user_question.in_progress");

            const icon = document.createElement("i");
            icon.classList.add("mdi", "mdi-comment-processing-outline");
            link.appendChild(icon);

            header.appendChild(link);
        }

        if (this.transitionable("unanswered")) {
            const link = document.createElement("a");
            link.addEventListener("click", () => this.transition("unanswered"));
            link.classList.add("btn", "btn-icon", "question-control-button", "question-unresolve");
            link.title = I18n.t("js.user_question.unresolve");

            const icon = document.createElement("i");
            icon.classList.add("mdi", "mdi-restart");
            link.appendChild(icon);

            header.appendChild(link);
        }

        return header;
    }

    get html(): HTMLDivElement {
        if (this.__html === null) {
            // Generate a new element.
            this.__html = document.createElement("div") as HTMLDivElement;
            this.__html.classList.add("annotation", this.type);
            if (this.class !== null) {
                this.__html.classList.add(this.class);
            }
            this.__html.id = `annotation-div-${this.__id}`;
            this.__html.title = this.title;

            // Body.
            this.__html.appendChild(this.header);
            this.__html.appendChild(this.body);
            // Ask MathJax to search for math in the annotations
            if (window.MathJax === undefined) {
                console.error("MathJax is not initialized");
            } else {
                window.MathJax.typeset();
            }
        }

        return this.__html;
    }

    get important(): boolean {
        return this.type === "error" || this.type === "user" || this.type == "question";
    }

    protected abstract get meta(): string;

    public get modifiable(): boolean {
        return false;
    }

    public transitionable(to: QuestionState): boolean {
        return false;
    }

    public get rawText(): string {
        return this.text;
    }

    public get removable(): boolean {
        return false;
    }

    public get visible(): boolean {
        return true;
    }

    public async remove(): Promise<void> {
        this.__html.remove();
    }

    public show(): void {
        this.__html.classList.remove("hide");
    }

    protected abstract get title(): string;

    protected get editTitle(): string {
        return "";
    }

    public async update(data): Promise<Annotation> {
        // Do nothing.
        return data;
    }

    protected async transition(to: QuestionState): Promise<void> {
        // Do nothing.
    }
}
