import { Papyros } from "@dodona/papyros";
import { InputMode } from "@dodona/papyros";
import { ProgrammingLanguage } from "@dodona/papyros";

/**
 * Custom interface to not have to add the ace package as dependency
 */
interface Editor {
    setValue(v: string): void;
    getValue(): string;
}

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

function initCodingScratchpad(programmingLanguage: ProgrammingLanguage): void {
    if (Papyros.supportsProgrammingLanguage(programmingLanguage)) {
        let papyros: Papyros | undefined = undefined;
        let editor: Editor | undefined = undefined;
        // To prevent horizontal scrollbar issues, we delay rendering the button
        // until after the page is loaded
        const showButton = document.getElementById(SHOW_OFFCANVAS_BUTTON_ID);
        showButton.classList.add("offcanvas-show-btn");
        showButton.classList.remove("hidden");
        showButton.addEventListener("click", async function () {
            if (!papyros) { // Only create Papyros once per session, but only when required
                papyros = new Papyros(
                    {
                        programmingLanguage: Papyros.toProgrammingLanguage(programmingLanguage),
                        standAlone: false,
                        locale: I18n.locale,
                        inputMode: InputMode.Interactive,
                    });
                editor ||= window.dodona.editor;
                if (editor) {
                    // Shortcut to copy code to ACE editor
                    papyros.addButton(
                        {
                            id: CODE_COPY_BUTTON_ID,
                            buttonText: I18n.t("js.coding_scratchpad.copy_code")
                        },
                        () => {
                            editor.setValue(papyros.getCode());
                            document.getElementById(CLOSE_BUTTON_ID).click();
                            // Open submit panel if possible
                            document.getElementById(SUBMIT_TAB_ID)?.click();
                        }
                    );
                }

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
                        parentElementId: CODE_INPUT_PARENT_ID
                    },
                    darkMode: window.dodona.darkMode
                });
                await papyros.configureInput(location.href, "inputServiceWorker.js");
                await papyros.launch();
            }
        });
        // Ask user to choose after offcanvas is shown
        document.getElementById(OFFCANVAS_ID).addEventListener("shown.bs.offcanvas", () => {
            editor ||= window.dodona.editor;
            if (editor) { // Start with code from the editor, if there is any
                const editorCode = editor.getValue();
                const currentCode = papyros.getCode();
                if (!currentCode || // Papyros empty
                    // Neither code areas are empty, but they differ
                    (editorCode && currentCode !== editorCode &&
                        // and user chooses to overwrite current code with editor value
                        confirm(I18n.t("js.coding_scratchpad.overwrite_code")))) {
                    papyros.setCode(editorCode);
                }
            }
        });
    }
}

export { initCodingScratchpad };
