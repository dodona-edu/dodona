import { BackendManager, CodeEditor, InputMode, Papyros, ProgrammingLanguage } from "@dodona/papyros";
import { themeState } from "state/Theme";
import { EditorView } from "@codemirror/view";
import { rougeStyle, setCode } from "editor";
import { syntaxHighlighting } from "@codemirror/language";
import { i18n } from "i18n/i18n";
import { BackendEventType } from "@dodona/papyros/dist/BackendEvent";
import { Tab } from "bootstrap";

/** Identifiers used in HTML for relevant elements */
const CODE_EDITOR_PARENT_ID = "scratchpad-editor-wrapper";
const PANEL_PARENT_ID = "scratchpad-panel-wrapper";
const CODE_OUTPUT_PARENT_ID = "scratchpad-output-wrapper";
const CODE_INPUT_PARENT_ID = "scratchpad-input-wrapper";
const OFFCANVAS_ID = "scratchpad-offcanvas";
const SHOW_OFFCANVAS_BUTTON_ID = "scratchpad-offcanvas-show-btn";
const CODE_COPY_BUTTON_ID = "scratchpad-code-copy-btn";
const CLOSE_BUTTON_ID = "scratchpad-offcanvas-close-btn";
const SUBMIT_TAB_ID = "activity-handin-link";
const CODE_TRACE_PARENT_ID = "scratchpad-trace-wrapper";
const TRACE_TAB_ID = "scratchpad-trace-tab";
const DESCRIPTION_TAB_ID = "scratchpad-description-tab";

function initCodingScratchpad(programmingLanguage: ProgrammingLanguage): void {
    if (Papyros.supportsProgrammingLanguage(programmingLanguage)) {
        let papyros: Papyros | undefined = undefined;
        let editor: EditorView | undefined = undefined;
        const closeButton = document.getElementById(CLOSE_BUTTON_ID);
        // To prevent horizontal scrollbar issues, we delay rendering the button
        // until after the page is loaded
        const showButton = document.getElementById(SHOW_OFFCANVAS_BUTTON_ID);
        showButton.classList.add("offcanvas-show-btn");
        showButton.classList.remove("hidden");
        showButton.addEventListener("click", async function () {
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
                            closeButton.click();
                            // Open submit panel if possible
                            document.getElementById(SUBMIT_TAB_ID)?.click();
                        }
                    );
                }
                await papyros.launch();

                papyros.codeRunner.editor.reconfigure([CodeEditor.STYLE, syntaxHighlighting(rougeStyle, {
                    fallback: true
                })]);
            }
        });
        // Ask user to choose after offcanvas is shown
        document.getElementById(OFFCANVAS_ID).addEventListener("shown.bs.offcanvas", () => {
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

        // Hide Trace tab when a new run is started
        BackendManager.subscribe(BackendEventType.Start, () => {
            const traceTab = document.getElementById(TRACE_TAB_ID);
            if (traceTab) {
                traceTab.classList.add("hidden");
                const descriptionTab = document.getElementById(DESCRIPTION_TAB_ID);
                if (descriptionTab) {
                    const tabTrigger = new Tab(descriptionTab.querySelector("a"));
                    tabTrigger.show();
                }
            }
        });

        // Show Trace tab when a new frame is added
        BackendManager.subscribe(BackendEventType.Frame, () => {
            const traceTab = document.getElementById(TRACE_TAB_ID);
            if (traceTab) {
                traceTab.classList.remove("hidden");
                const tabTrigger = new Tab(traceTab.querySelector("a"));
                tabTrigger.show();
            }
        });
    }
}

export { initCodingScratchpad };
