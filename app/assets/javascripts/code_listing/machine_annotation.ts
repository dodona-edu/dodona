import { Annotation, AnnotationType } from "code_listing/annotation";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
}

export class MachineAnnotation extends Annotation {
    constructor(data: MachineAnnotationData) {
        // Filter out lines only containing dashes.
        let text = data.text.split("\n")
            .filter(s => !s.match("^--*$"))
            .join("\n");
        // use the dom engine to encode the text to html
        const node = document.createElement("span");
        node.textContent = text;
        text = node.innerHTML;
        super(data.row + 1, text, data.type);
    }

    protected get class(): string {
        return "machine-annotation";
    }

    protected get meta(): string {
        return this.title;
    }

    protected get title(): string {
        return I18n.t(`js.annotation.type.${this.type}`);
    }
}
