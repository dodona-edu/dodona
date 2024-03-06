import { LoadingBar } from "components/search/loading_bar";
import { exportLocation, prepareExport } from "export";

const LOADER_ID = "dolos-loader";
const DOLOS_URL = "https://dolos.ugent.be/api/reports";

export async function startDolos(url: string): Promise<void> {
    const loader = document.getElementById(LOADER_ID) as LoadingBar;
    loader.show();
    const exportDataUrl = await prepareExport(url, new FormData());
    const downloadUrl = await exportLocation(exportDataUrl);

    const zip = await fetch(downloadUrl);
    const blob = await zip.blob();
    const filename = zip.headers.get("Content-Disposition").split("filename=")[1];
    const file = new File([blob], filename, { type: "application/zip" });

    const formData = new FormData();
    formData.append("dataset[zipfile]", file);
    formData.append("dataset[name]", filename);

    const dolosResponse = await fetch(DOLOS_URL, {
        method: "POST",
        body: formData,
        headers: {
            "Accept": "application/json"
        }
    });
    window.open(await dolosUrl(dolosResponse), "_blank");
    loader.hide();
}

async function dolosUrl(dolosResponse: Response): Promise<string> {
    const json = await dolosResponse.json();
    if (json.status !== "finished") {
        await new Promise(resolve => setTimeout(resolve, 1000));
        return await dolosUrl(dolosResponse);
    }
    return json.url;
}
