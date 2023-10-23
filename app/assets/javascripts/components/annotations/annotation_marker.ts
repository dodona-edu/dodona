import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, TemplateResult, CSSResultGroup } from "lit";
import {
    Annotation,
    compareAnnotationOrders,
    isUserAnnotation
} from "state/Annotations";
import { MachineAnnotation } from "state/MachineAnnotations";
import { StateController } from "state/state_system/StateController";
/**
 * A marker that styles the slotted content based on the relevant annotations.
 * It applies a background color to user annotations and a wavy underline to machine annotations.
 *
 * @prop {AnnotationData[]} annotations The annotations to use for styling.
 *
 * @element d-annotation-marker
 */
@customElement("d-annotation-marker")
export class AnnotationMarker extends LitElement {
    @property({ type: Array })
    accessor annotations: Annotation[];
    @property({ type: Boolean, attribute: "full-width" })
    accessor fullWidth = false;

    state = new StateController(this);

    static get styles(): CSSResultGroup {
        // order matters here, the last defined class determines the color if multiple apply
        return css`
            .info, .warning, .error,
            .info-intense, .warning-intense, .error-intense {
                background-position: left bottom;
                background-repeat: repeat-x;
            }
            .info { background-image: var(--d-annotation-info-background) }
            .warning { background-image: var(--d-annotation-warning-background) }
            .error { background-image: var(--d-annotation-error-background) }
            .info-intense { background-image: var(--d-annotation-info-background-intense) }
            .warning-intense { background-image: var(--d-annotation-warning-background-intense) }
            .error-intense { background-image: var(--d-annotation-error-background-intense) }
            .annotation { background-color: var(--annotation-color) }
            .question { background-color: var(--question-color) }
            .annotation-intense { background-color: var(--annotation-intense-color) }
            .question-intense { background-color: var(--question-intense-color) }
            `;
    }

    static getClass(annotation: Annotation): string {
        return annotation.isHovered ? `${annotation.type}-intense` : annotation.type;
    }

    static colors = {
        "error": "var(--d-annotation-error, red)",
        "warning": "var(--d-annotation-warning, yellow)",
        "info": "var(--d-annotation-info, blue)",
        "annotation": "var(--annotation-color, green)",
        "question": "var(--question-color, orange)",
        "annotation-intense": "var(--annotation-intense-color, green)",
        "question-intense": "var(--question-intense-color, orange)",
    };

    /**
     * Returns the annotations sorted in order of importance.
     * Hovered annotations are prioritized over non-hovered annotations.
     * Otherwise the default order is used, defined in `compareAnnotationOrders`.
     *
     * Goal is to always show the style of the most important annotation.
     */
    get sortedAnnotations(): Annotation[] {
        return this.annotations.sort( (a, b) => {
            if (a.isHovered && !b.isHovered) {
                return -1;
            }

            if (b.isHovered && !a.isHovered) {
                return 1;
            }

            return compareAnnotationOrders(a, b);
        });
    }

    get machineAnnotationMarkerSVG(): TemplateResult | undefined {
        const firstMachineAnnotation = this.sortedAnnotations.find(a => !isUserAnnotation(a)) as MachineAnnotation | undefined;
        const size = firstMachineAnnotation?.isHovered ? 20 : 14;
        return firstMachineAnnotation && html`<svg style="position: absolute; top: ${16 - size/2}px; left: -${size/2}px" width="${size}" height="${size}" viewBox="0 0 24 24">
            <path fill="${AnnotationMarker.colors[firstMachineAnnotation.type]}" d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6l-6 6l1.41 1.41Z"/>
        </svg>`;
    }

    get annotationClasses(): string {
        return this.annotations.map(a => AnnotationMarker.getClass(a)).join(" ");
    }

    render(): TemplateResult {
        return html`<span class="${this.annotationClasses} ${this.fullWidth ? "full-width" : ""}"><slot>${this.machineAnnotationMarkerSVG}</slot></span>`;
    }
}
