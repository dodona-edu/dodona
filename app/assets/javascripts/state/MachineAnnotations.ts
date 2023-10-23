import { AnnotationType } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { StateMap } from "state/state_system/StateMap";
import { createStateFromInterface } from "state/state_system/CreateStateFromInterface";
import { submissionState } from "state/Submissions";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
    externalUrl?: string | null;
    rows?: number;
    column?: number;
    columns?: number;
}

export class MachineAnnotation extends createStateFromInterface<MachineAnnotationData>() {
    @stateProperty public accessor isHovered = false;
}

class MachineAnnotationState extends State {
    @stateProperty public accessor byLine = new StateMap<number, MachineAnnotation[]>();
    @stateProperty public accessor byMarkedLine = new StateMap<number, MachineAnnotation[]>();
    @stateProperty public accessor count = 0;

    public setMachineAnnotations(annotations: MachineAnnotationData[]): void {
        this.count = annotations.length;
        this.byLine.clear();
        this.byMarkedLine.clear();
        for (const data of annotations) {
            const annotation = new MachineAnnotation(data);
            const markedLength = annotation.rows ?? 1;
            let line = annotation.row ? annotation.row + markedLength : 1;

            // show annotation on the last line if it is out of range
            if (line > submissionState.codeByLine.length) {
                line = submissionState.codeByLine.length;
            }

            if (this.byLine.has(line)) {
                this.byLine.get(line)?.push(annotation);
            } else {
                this.byLine.set(line, [annotation]);
            }
            for (let i = 1; i <= markedLength; i++) {
                const markedLine = annotation.row + i;
                if (this.byMarkedLine.has(markedLine)) {
                    this.byMarkedLine.get(markedLine)?.push(annotation);
                } else {
                    this.byMarkedLine.set(markedLine, [annotation]);
                }
            }
        }
    }
}

export const machineAnnotationState = new MachineAnnotationState();
