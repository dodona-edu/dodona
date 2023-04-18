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

const MACHINE_ANNOTATIONS: MachineAnnotationData[] = [
    {
        "text": "Undefined variable 'ijzer'",
        "type": "error",
        "row": 3,
        "rows": 1,
        "column": 10,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/error/undefined-variable.html"
    },
    {
        "text": "Undefined variable 'erts'",
        "type": "error",
        "row": 3,
        "rows": 1,
        "column": 18,
        "columns": 4,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/error/undefined-variable.html"
    },
    {
        "text": "Trailing whitespace",
        "type": "info",
        "row": 4,
        "rows": 1,
        "column": 0,
        "columns": 4,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/convention/trailing-whitespace.html"
    },
    {
        "text": "Division by zero",
        "type": "error",
        "row": 5,
        "rows": 1,
        "column": 11,
        "columns": 1,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/error/undefined-variable.html"
    },
    {
        "text": "Assigning the same variable 'dict' to itself",
        "type": "warning",
        "row": 8,
        "rows": 1,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/warning/self-assigning-variable.html"
    },
    {
        "text": "Class name \"dict\" doesn't conform to PascalCase naming style",
        "type": "info",
        "row": 8,
        "rows": 1,
        "column": 0,
        "columns": 4,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/convention/invalid-name.html"
    },
    {
        "text": "Trailing newlines",
        "type": "info",
        "row": 9,
        "rows": 7,
        "column": 0,
        "columns": 0,
        "externalUrl": "https://pylint.pycqa.org/en/latest/messages/convention/trailing-newlines.html"
    }
];

class MachineAnnotationState extends State {
    @stateProperty public byLine = new StateMap<number, MachineAnnotationData[]>();
    @stateProperty public byMarkedLine = new StateMap<number, MachineAnnotationData[]>();
    @stateProperty public count = 0;

    public setMachineAnnotations(annotations: MachineAnnotationData[]): void {
        console.log("setMachineAnnotations", annotations);
        this.count = MACHINE_ANNOTATIONS.length;
        this.byLine.clear();
        this.byMarkedLine.clear();
        for (const annotation of MACHINE_ANNOTATIONS) {
            const markedLength = annotation.rows ?? 1;
            const line = annotation.row + markedLength ?? 0;
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
