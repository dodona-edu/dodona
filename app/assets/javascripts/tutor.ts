import fscreen from "fscreen";
import { showInfoModal } from "modal";
import { html } from "lit";
import { TraceGenerator } from "@dodona/pyodide-trace-library";
import { initPapyros, OFFCANVAS_ID } from "coding_scratchpad";
import { InputMode, ProgrammingLanguage } from "@dodona/papyros";
import { BatchInputHandler } from "@dodona/papyros/dist/input/BatchInputHandler";
import { Offcanvas } from "bootstrap";
const DEBUG_BUTTON_ID = "__papyros-debug-code-btn";

export function initTutor(submissionCode: string): void {
    function init(): void {
        initTutorLinks();
    }

    function initTutorLinks(): void {
        const links = document.querySelectorAll(".tutorlink");

        links.forEach(l => {
            const tutorLink = l as HTMLLinkElement;
            if (!(tutorLink.dataset.statements || tutorLink.dataset.stdin)) {
                l.remove();
            }
        });

        links.forEach(l => l.addEventListener("click", e => {
            const exerciseId = (document.querySelector(".feedback-table") as HTMLElement).dataset.exercise_id;
            const tutorLink = e.currentTarget as HTMLLinkElement;
            const group = tutorLink.closest(".group");
            const stdin = tutorLink.dataset.stdin;
            const statements = tutorLink.dataset.statements;
            const files = { inline: {}, href: {} };

            group.querySelectorAll(".contains-file").forEach(g => {
                const content = JSON.parse((g as HTMLElement).dataset.files);

                Object.values(content).forEach(value => {
                    files[value["location"]][value["name"]] = value["content"];
                });
            });

            loadTutor(
                exerciseId,
                submissionCode,
                statements,
                stdin,
                files.inline,
                files.href
            );
        }));
    }

    async function loadTutor(exerciseId: string, studentCode: string, statements: string, stdin: string, inlineFiles: Record<string, string>, hrefFiles: Record<string, string>): Promise<void> {
        const papyros = await initPapyros(ProgrammingLanguage.Python);

        papyros.setCode(studentCode);
        papyros.codeRunner.inputManager.setInputMode(InputMode.Batch);
        (papyros.codeRunner.inputManager.inputHandler as BatchInputHandler).batchEditor.setText(stdin);
        papyros.codeRunner.editor.testCode = statements;

        // make full url from path
        const hrefFilesFull = Object.keys(hrefFiles).reduce((result, key) => {
            result[key] = `${location.protocol}//${location.hostname}${location.port ? `:${location.port}` : ""}/nl/exercises/${exerciseId}/${hrefFiles[key]}`;
            return result;
        }, {});

        await papyros.codeRunner.provideFiles(inlineFiles, hrefFilesFull);

        new Offcanvas(document.getElementById(OFFCANVAS_ID)).show();
        document.getElementById(DEBUG_BUTTON_ID).click();
    }

    init();
}
