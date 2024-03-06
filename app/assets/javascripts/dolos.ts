import { LoadingBar } from "components/search/loading_bar";
import { exportLocation, prepareExport } from "export";
import { fetch } from "utilities";

const LOADER_ID = "dolos-loader";
const DOLOS_URL = "https://dolos.ugent.be/api/reports";

export async function startDolos(url: string): Promise<void> {
    const loader = document.getElementById(LOADER_ID) as LoadingBar;
    loader.show();

    const settings = new FormData();
    settings.append("with_info", "true");
    settings.append("only_last_submission", "true");
    settings.append("group_by", "user");
    settings.append("all_students", "false");

    const exportDataUrl = await prepareExport(url, settings);
    const downloadUrl = await exportLocation(exportDataUrl);

    const dolosResponse = await fetch(DOLOS_URL, {
        method: "POST",
        body: JSON.stringify({ url: downloadUrl }),
        headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
        }
    });
    const json = await dolosResponse.json();
    window.open(json.url, "_blank");
    loader.hide();
}
