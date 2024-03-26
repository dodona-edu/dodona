import { LoadingBar } from "components/search/loading_bar";
import { exportData, prepareExport } from "export";
import { fetch } from "utilities";

const LOADER_ID = "dolos-loader";
const DOLOS_URL = "/dolos_reports";

export async function startDolos(url: string): Promise<void> {
    const loader = document.getElementById(LOADER_ID) as LoadingBar;
    loader.show();

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
    window.open(json.html_url, "_blank");
    loader.hide();
}
