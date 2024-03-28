import { CodeEditor, InputMode, Papyros, ProgrammingLanguage } from "@dodona/papyros";
import { themeState } from "state/Theme";
import { EditorView } from "@codemirror/view";
import { rougeStyle, setCode } from "editor";
import { syntaxHighlighting } from "@codemirror/language";
import { i18n } from "i18n/i18n";
import { Tab } from "bootstrap";

/** Identifiers used in HTML for relevant elements */
const CODE_EDITOR_PARENT_ID = "scratchpad-editor-wrapper";
const PANEL_PARENT_ID = "scratchpad-panel-wrapper";
const CODE_OUTPUT_PARENT_ID = "scratchpad-output-wrapper";
const CODE_INPUT_PARENT_ID = "scratchpad-input-wrapper";
export const OFFCANVAS_ID = "scratchpad-offcanvas";
const SHOW_OFFCANVAS_BUTTON_ID = "scratchpad-offcanvas-show-btn";
const CODE_COPY_BUTTON_ID = "scratchpad-code-copy-btn";
const CLOSE_BUTTON_ID = "scratchpad-offcanvas-close-btn";
const SUBMIT_TAB_ID = "activity-handin-link";
const CODE_TRACE_PARENT_ID = "scratchpad-trace-wrapper";
const TRACE_TAB_ID = "scratchpad-trace-tab";
const DESCRIPTION_TAB_ID = "scratchpad-description-tab";

let papyros: Papyros | undefined;
let editor: EditorView | undefined;
export async function initPapyros(programmingLanguage: ProgrammingLanguage): Promise<Papyros> {
    if (!papyros) { // Only create Papyros once per session, but only when required
        // Papyros registers a service worker on a specific path
        // We used to do this on a different path
        // So we need to unregister old serviceworkers manually as these won't get overwritten
        navigator.serviceWorker.getRegistrations().then(function (registrations) {
            for (const registration of registrations) {
                if (registration.scope !== document.location.origin + "/") {
                    registration.unregister();
                }
            }
        });

        papyros = new Papyros(
            {
                programmingLanguage: Papyros.toProgrammingLanguage(programmingLanguage),
                standAlone: false,
                locale: i18n.locale(),
                inputMode: InputMode.Interactive,
                channelOptions: {
                    root: "/",
                    serviceWorkerName: "inputServiceWorker.js"
                }
            });

        // Render once new button is added
        papyros.render({
            codeEditorOptions: {
                parentElementId: CODE_EDITOR_PARENT_ID
            },
            statusPanelOptions: {
                parentElementId: PANEL_PARENT_ID
            },
            outputOptions: {
                parentElementId: CODE_OUTPUT_PARENT_ID
            },
            inputOptions: {
                parentElementId: CODE_INPUT_PARENT_ID,
                inputStyling: {
                    // Allows 4 lines of input
                    maxHeight: "10vh"
                }
            },
            traceOptions: {
                parentElementId: CODE_TRACE_PARENT_ID
            },
            darkMode: themeState.theme === "dark"
        });

        await papyros.launch();

        editor ||= window.dodona.editor;
        if (editor) {
            // Shortcut to copy code to editor
            papyros.addButton(
                {
                    id: CODE_COPY_BUTTON_ID,
                    buttonText: i18n.t("js.coding_scratchpad.copy_to_submit"),
                    classNames: "btn-secondary",
                    icon: "<i class=\"mdi mdi-clipboard-arrow-left-outline\"></i>"
                },
                () => {
                    setCode(editor, papyros.getCode());
                    const closeButton = document.getElementById(CLOSE_BUTTON_ID);
                    closeButton.click();
                    // Open submit panel if possible
                    document.getElementById(SUBMIT_TAB_ID)?.click();
                }
            );
        }

        papyros.codeRunner.editor.reconfigure([CodeEditor.STYLE, syntaxHighlighting(rougeStyle, {
            fallback: true
        })]);

        papyros.codeRunner.addEventListener("debug-mode", (event: CustomEvent<boolean>) => {
            const debugMode = event.detail;
            const traceTab = document.getElementById(TRACE_TAB_ID);
            traceTab.classList.toggle("hidden", !debugMode);
            if (debugMode) {
                const tabTrigger = new Tab(traceTab.querySelector("a"));
                tabTrigger.show();
            } else {
                const descriptionTab = document.getElementById(DESCRIPTION_TAB_ID);
                const tabTrigger = new Tab(descriptionTab.querySelector("a"));
                tabTrigger.show();
            }
        });
    }
    return papyros;
}

export function initCodingScratchpad(programmingLanguage: ProgrammingLanguage): void {
    if (Papyros.supportsProgrammingLanguage(programmingLanguage)) {
        const showButton = document.getElementById(SHOW_OFFCANVAS_BUTTON_ID);
        showButton.addEventListener("click", async () => {
            const papyros = await initPapyros(programmingLanguage);
            editor ||= window.dodona.editor;
            if (editor) { // Start with code from the editor, if there is any
                const editorCode = editor.state.doc.toString();
                const currentCode = papyros.getCode();
                if (!currentCode || // Papyros empty
                    // Neither code areas are empty, but they differ
                    (editorCode && currentCode !== editorCode &&
                        // and user chooses to overwrite current code with editor value
                        confirm(i18n.t("js.coding_scratchpad.overwrite_code")))) {
                    papyros.setCode(editorCode);
                }
            }
        });
    }
}
