import fscreen from "fscreen";
import { showInfoModal } from "modal";
import { html } from "lit";
import { TraceGenerator } from "@dodona/pyodide-trace-library";

export function initTutor(submissionCode: string): void {
    const generator = new TraceGenerator();
    const generatorReady = generator.setup();
    function init(): void {
        initTutorLinks();
        if (document.querySelectorAll(".tutormodal").length == 1) {
            initFullScreen();
        } else {
            const tutorModal = Array.from(document.querySelectorAll(".tutormodal")).pop();
            if (tutorModal) {
                tutorModal.remove();
            }
        }
    }

    function initTutorLinks(): void {
        document.querySelectorAll(".tutorlink").forEach(l => {
            const tutorLink = l as HTMLLinkElement;
            if (!(tutorLink.dataset.statements || tutorLink.dataset.stdin)) {
                l.remove();
            }
        });

        document.querySelectorAll(".tutorlink").forEach(l => l.addEventListener("click", e => {
            const exerciseId = (document.querySelector(".feedback-table") as HTMLElement).dataset.exercise_id;
            const tutorLink = e.currentTarget as HTMLLinkElement;
            const group = tutorLink.closest(".group");
            const stdin = tutorLink.dataset.stdin.slice(0, -1);
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

    function initFullScreen(): void {
        fscreen.addEventListener("fullscreenchange", resizeFullScreen);

        document.querySelector("#tutor #fullscreen-button").addEventListener("click", () => {
            const tutor = document.querySelector("#tutor");
            if (fscreen.fullscreenElement) {
                document.querySelector("#tutor .modal-dialog").classList.remove("modal-fullscreen");
                fscreen.exitFullscreen();
            } else {
                document.querySelector("#tutor .modal-dialog").classList.add("modal-fullscreen");
                fscreen.requestFullscreen(tutor);
            }
        });
    }

    function resizeFullScreen(): void {
        const tutor = document.querySelector("#tutor");
        const tutorviz = document.querySelector("#tutorviz") as HTMLElement;
        if (!fscreen.fullscreenElement) {
            tutor.classList.remove("fullscreen");
            tutorviz.style.height = tutorviz.dataset.standardheight;
        } else {
            tutorviz.dataset.standardheight = `${tutorviz.clientHeight}px`;
            tutor.classList.add("fullscreen");
            tutorviz.style.height = "100%";
        }
    }

    function loadTutor(exerciseId: string, studentCode: string, statements: string, stdin: string, inlineFiles: Record<string, string>, hrefFiles: Record<string, string>): void {
        const lines = studentCode.split("\n");
        // find and remove main
        let i = 0;
        let remove = false;
        const sourceArray = [];
        while (i < lines.length) {
            if (remove && !lines[i].match(/^\s+.*/g)) {
                remove = false;
            }
            if (lines[i].match(/if\s+__name__\s*==\s*(['"])__main__\s*\1:\s*/g)) {
                remove = true;
            }
            if (!remove) {
                sourceArray.push(lines[i]);
            }
            i += 1;
        }
        sourceArray.push(statements);
        const sourceCode = sourceArray.join("\n");

        // make full url from path
        const hrefFilesFull = Object.keys(hrefFiles).reduce((result, key) => {
            result[key] = `${location.protocol}//${location.hostname}${location.port ? `:${location.port}` : ""}/nl/exercises/${exerciseId}/${hrefFiles[key]}`;
            return result;
        }, {});

        showInfoModal("Python Tutor", html`<div id="tutorcontent"></div>`, { allowFullscreen: true });

        const content = document.querySelector("#tutorcontent");
        if (content) {
            content.innerHTML = `<div class="dodona-progress dodona-progress-indeterminate" style="visibility: visible">
            <div class="progressbar bar bar1" style="width: 0%;"></div>
            <div class="bufferbar bar bar2" style="width: 100%;"></div>
            <div class="auxbar bar bar3" style="width: 0%;"></div>
        </div>`;
        }

        generatorReady.then(() => {
            generator.generateTrace(sourceCode, stdin, inlineFiles, hrefFilesFull).then((result: string) => createTutor(result));
        });
    }

    function createTutor(codeTrace: string): void {
        const modal = document.querySelector("#tutor #info-modal");

        const content = document.querySelector("#tutorcontent");
        if (content) {
            content.innerHTML = `<iframe id="tutorviz" width="100%" frameBorder="0" src="${window.dodona.sandboxUrl}/tutorviz/tutorviz.html"></iframe>`;
            document.querySelector("#tutorviz").addEventListener("load", () => {
                window.iFrameResize({ checkOrigin: false, onInit: frame => frame.iFrameResizer.sendMessage(JSON.parse(codeTrace)), scrolling: "omit" }, "#tutorviz");
            });
        }

        modal.addEventListener("hidden.bs.modal", () => {
            if (fscreen.fullscreenElement) {
                document.querySelector("#tutor .modal-dialog").classList.remove("modal-fullscreen");
                fscreen.exitFullscreen();
            }
        });
    }

    init();
}
