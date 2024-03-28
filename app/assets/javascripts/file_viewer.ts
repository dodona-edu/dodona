import { showInfoModal } from "./modal";
import { fetch } from "utilities";
import { html } from "lit";

function showInlineFile(name: string, content: string): void {
    showInfoModal(name, html`<div class='code'>${content}</div>`);
}

function showRealFile(name: string, activityPath: string, filePath: string): void {
    const path = activityPath + "/" + filePath;
    const random = Math.floor(Math.random() * 10000 + 1);
    showInfoModal(
        html`${name} <a href='${path}' title='Download' download><i class='mdi mdi-download'></i></a>`,
        html`<div class='code' id='file-${random}'>Loading...</div>`
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
export function initFileViewers(activityPath: string): void {
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
