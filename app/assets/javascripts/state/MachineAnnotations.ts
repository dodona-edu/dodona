import { AnnotationType } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { StateMap } from "state/state_system/StateMap";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
    externalUrl?: string | null;
    rows?: number;
    column?: number;
    columns?: number;
}

class MachineAnnotationState extends State {
    @stateProperty public byLine = new StateMap<number, MachineAnnotationData[]>();
    @stateProperty public byMarkedLine = new StateMap<number, MachineAnnotationData[]>();
    @stateProperty public count = 0;

    public setMachineAnnotations(annotations: MachineAnnotationData[]): void {
        this.count = annotations.length;
        this.byLine.clear();
        this.byMarkedLine.clear();
        for (const annotation of annotations) {
            const markedLength = annotation.rows ?? 1;
            const line = annotation.row ? annotation.row + markedLength : 0;
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
