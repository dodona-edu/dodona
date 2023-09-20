import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, TemplateResult, CSSResultGroup, unsafeCSS } from "lit";
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
    annotations: Annotation[];

    state = new StateController(this);

    static get styles(): CSSResultGroup {
        // order matters here, the last defined class determines the color if multiple apply
        const machineClasses = [unsafeCSS`info`, unsafeCSS`warning`, unsafeCSS`error`];
        const userClasses = [unsafeCSS`annotation`, unsafeCSS`question`];
        return [
            ...machineClasses.map(x => css`
                .${x} {
                    background-image: var(--d-annotation-${x}-background);
                    background-position: left bottom;
                    background-repeat: repeat-x;
                }
                .${x}-intense {
                    background-image: var(--d-annotation-${x}-background-intense);
                    background-position: left bottom;
                    background-repeat: repeat-x;
                }
            `),
            ...userClasses.map(x => css`
                .${x} { background-color: var(--${x}-color)}
                .${x}-intense {background-color: var(--${x}-intense-color)}
            `),
        ];
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
        return html`<span class="${this.annotationClasses}"><slot>${this.machineAnnotationMarkerSVG}</slot></span>`;
    }
}
