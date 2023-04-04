import { AnnotationType } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { StateMap } from "state/state_system/StateMap";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
    externalUrl?: string | null;
}

class MachineAnnotationState extends State {
    @stateProperty public annotationsByLine = new StateMap<number, MachineAnnotationData[]>();
    @stateProperty public annotationsCount = 0;

    public setMachineAnnotations(annotations: MachineAnnotationData[]): void {
        this.annotationsCount = annotations.length;
        this.annotationsByLine.clear();
        for (const annotation of annotations) {
            const line = annotation.row + 1 ?? 0;
            if (this.annotationsByLine.has(line)) {
                this.annotationsByLine.get(line)?.push(annotation);
            } else {
                this.annotationsByLine.set(line, [annotation]);
            }
        }
    }
}

export const machineAnnotationState = new MachineAnnotationState();
