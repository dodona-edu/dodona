import { LoadingBar } from "components/search/loading_bar";
import { exportData, prepareExport } from "export";
import { fetch } from "utilities";
import { html, render } from "lit";
import { i18n } from "i18n/i18n";

const LOADER_ID = "dolos-loader";
const DOLOS_URL = "/dolos_reports";

export function initDolosBtn(btnID: string, url: string): void {
    const btn = document.getElementById(btnID) as HTMLLinkElement;
    btn.addEventListener("click", () => startDolos(btn, url));
}

export async function startDolos(btn: HTMLLinkElement, url: string): Promise<void> {
    console.log("Starting Dolos report generation", btn.id);
    const loader = document.getElementById(LOADER_ID) as LoadingBar;
    loader.show();
    btn.classList.add("disabled");

    const settings = new FormData();
    settings.append("with_info", "true");
    settings.append("only_last_submission", "true");
    settings.append("group_by", "user");

    const exportDataUrl = await prepareExport(url, settings);
    const download = await exportData(exportDataUrl);

    const dolosResponse = await fetch(DOLOS_URL, {
        method: "POST",
        body: JSON.stringify({ export_id: download.id }),
        headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
        }
    });

    if (!dolosResponse.ok) {
        alert("An error occurred while creating the plagiarism report.");
        loader.hide();
        return;
    }

    const json = await dolosResponse.json();
    const dolosUrl = json.html_url;
    window.open(dolosUrl, "_blank");
    loader.hide();

    const newBtn = html`
        <a id="${btn.id}" class="btn btn-outline with-icon" href="${dolosUrl}" target="_blank">
            <i class="mdi mdi-graph-outline mdi-18"></i> ${i18n.t("js.dolos.view_report")}
        </a>
    `;
    render(newBtn, btn.parentElement, { renderBefore: btn });
    btn.remove();
}
