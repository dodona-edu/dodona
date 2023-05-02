import { LitElement, html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { AnnotationMarker } from "components/annotations/annotation_marker";
import { annotationState } from "state/Annotations";

/**
 * A marker that replaces the selection.
 * The slotted content is styled to look like a user annotation.
 * It is used to mark the selected code while editing an annotation
 * @element d-selection-marker
 */
@customElement("d-selection-marker")
class SelectionMarker extends LitElement {
    render(): TemplateResult {
        return html`<style>
            :host {
                background: ${AnnotationMarker.colors[annotationState.isQuestionMode ? "question" : "annotation"]};
                padding-top: 2px;
                padding-bottom: 2px;
                margin-top: -2px;
                margin-bottom: -2px;
            }
        </style><slot></slot>`;
    }
}
