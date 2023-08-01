import fscreen from "fscreen";
import { showInfoModal } from "./modal.js";
import { fetch } from "utilities";

function initPythiaSubmissionShow(submissionCode: string, activityPath: string): void {
    function init(): void {
        initTutorLinks();
        initFileViewers(activityPath);
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
            const group = l.closest(".group") as HTMLElement;
            if (!(group.dataset.statements || group.dataset.stdin)) {
                l.remove();
            }
        });

        document.querySelectorAll(".tutorlink").forEach(l => l.addEventListener("click", e => {
            const exerciseId = (document.querySelector(".feedback-table") as HTMLElement).dataset.exercise_id;
            const group = e.currentTarget.closest(".group");
            const stdin = group.dataset.stdin.slice(0, -1);
            const statements = group.dataset.statements;
            const files = { inline: {}, href: {} };

            group.querySelectorAll(".contains-file").forEach(g => {
                const content = JSON.parse(g.dataset.files);

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

    function initFileViewers(activityPath: string): void {
        document.querySelectorAll("a.file-link").forEach(l => l.addEventListener("click", e => {
            const link = e.currentTarget as HTMLLinkElement;
            const fileName = link.innerText;
            const tc = link.closest(".testcase.contains-file") as HTMLDivElement;
            if (tc === null) {
                return;
            }
            const files = JSON.parse(tc.dataset.files);
            const file = files[fileName];
            if (file.location === "inline") {
                showInlineFile(fileName, file.content);
            } else if (file.location === "href") {
                showRealFile(fileName, activityPath, file.content);
            }
        }));
    }

    function showInlineFile(name: string, content: string): void {
        showInfoModal(name, `<div class='code'>${content}</div>`);
    }

    function showRealFile(name: string, activityPath: string, filePath: string): void {
        const path = activityPath + "/" + filePath;
        const random = Math.floor(Math.random() * 10000 + 1);
        showInfoModal(
            `${name} <a href='${path}' title='Download' download><i class='mdi mdi-download'></i></a>`,
            `<div class='code' id='file-${random}'>Loading...</div>`
        );

        fetch(path, {
            method: "GET"
        }).then(response => {
            if (response.ok) {
                response.text().then(data => {
                    let lines = data.split("\n");
                    const maxLines = 99;
                    if (lines.length > maxLines) {
                        lines = lines.slice(0, maxLines);
                        lines.push("...");
                    }

                    const table = document.createElement("table");
                    table.className = "external-file";
                    for (let i = 0; i < lines.length; i++) {
                        const tr = document.createElement("tr");

                        const number = document.createElement("td");
                        number.className = "line-nr";
                        number.textContent = (i === maxLines) ? "" : (i + 1).toString();
                        tr.appendChild(number);

                        const line = document.createElement("td");
                        line.className = "line";
                        // textContent is safe, html is not executed
                        line.textContent = lines[i];
                        tr.appendChild(line);
                        table.appendChild(tr);
                    }
                    const fileView = document.getElementById(`file-${random}`);
                    fileView.innerHTML = "";
                    fileView.appendChild(table);
                });
            }
        });
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

    function loadTutor(exerciseId: string, studentCode: string, statements: string, stdin: string, inlineFiles: any, hrefFiles: any): void {
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

        const formData = new FormData();
        formData.append("exercise_id", exerciseId);
        formData.append("code", sourceCode);
        formData.append("input", JSON.stringify(stdin.split("\n")));
        formData.append("inlineFiles", JSON.stringify(inlineFiles));
        formData.append("hrefFiles", JSON.stringify(hrefFiles));

        fetch(window.dodona.tutorUrl, {
            method: "POST",
            body: formData,
        })
            .then( response => {
                if (response.ok) {
                    response.json().then(data => createTutor(data));
                } else {
                    const error = document.createElement("div");
                    error.classList.add("alert", "alert-danger", "alert-dismissible", "show", "tutor-error");
                    error.innerHTML = `<button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>${I18n.t("js.tutor-failed")}`;
                    document.querySelector(".feedback-table").before(error);
                    window.scrollTo(0, 0); // scroll to top of page to see error
                }
            });
    }

    function createTutor(codeTrace: string): void {
        showInfoModal(
            "Python Tutor",
            `<div id="tutorcontent"><div class="progress"><div class="progress-bar progress-bar-striped progress-bar-info active" role="progressbar" style="width: 100%">Loading</div></div></div>`,
            { allowFullscreen: true }
        );
        const modal = document.querySelector("#tutor #info-modal");

        modal.addEventListener("shown.bs.modal", () => {
            const content = document.querySelector("#tutorcontent");
            if (content) {
                content.innerHTML = `<iframe id="tutorviz" width="100%" frameBorder="0" src="${window.dodona.sandboxUrl}/tutorviz/tutorviz.html"></iframe>`;
                document.querySelector("#tutorviz").addEventListener("load", () => {
                    window.iFrameResize({ checkOrigin: false, onInit: frame => frame.iFrameResizer.sendMessage(codeTrace), scrolling: "omit" }, "#tutorviz");
                });
            }
        });

        modal.addEventListener("hidden.bs.modal", () => {
            if (fscreen.fullscreenElement) {
                document.querySelector("#tutor .modal-dialog").classList.remove("modal-fullscreen");
                fscreen.exitFullscreen();
            }
        });
    }

    init();
}

export { initPythiaSubmissionShow };
