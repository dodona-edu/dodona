import { InputMode, Papyros, ProgrammingLanguage } from "@dodona/papyros";

/**
 * Custom interface to not have to add the ace package as dependency
 */
interface Editor {
    setValue(v: string): void;
    getValue(): string;
}

const CODE_EDITOR_PARENT_ID = "scratchpad-editor-wrapper";
const PANEL_PARENT_ID = "scratchpad-panel-wrapper";
const CODE_OUTPUT_PARENT_ID = "scratchpad-output-wrapper";
const CODE_INPUT_PARENT_ID = "scratchpad-input-wrapper";
const SHOW_OFFCANVAS_BUTTON_ID = "scratchpad-offcanvas-show-btn";
const CODE_COPY_BUTTON_ID = "scratchpad-code-copy-btn";

function initCodingScratchpad(programmingLanguage: ProgrammingLanguage): void {
    if (Papyros.supportsProgrammingLanguage(programmingLanguage)) {
        let papyros: Papyros | undefined = undefined;

        document.getElementById(SHOW_OFFCANVAS_BUTTON_ID).addEventListener("click", async function () {
            const editor: Editor | undefined = window.dodona.editor;
            if (!papyros) { // Only create Papyros once per session, but only when required
                papyros = new Papyros(
                    {
                        programmingLanguage: Papyros.toProgrammingLanguage(programmingLanguage),
                        standAlone: false,
                        locale: I18n.locale,
                        inputMode: InputMode.Interactive,
                    });
                // Shortcut to copy code to clipboard
                papyros.addButton(
                    {
                        id: CODE_COPY_BUTTON_ID,
                        buttonText: I18n.t("js.coding_scratchpad.copy_code"),
                        extraClasses: "copy-code-button"
                    },
                    () => navigator.clipboard.writeText(papyros.getCode())
                );
                // Render once new button is added
                papyros.render({
                    code: {
                        parentElementId: CODE_EDITOR_PARENT_ID,
                        attributes: new Map([["style", "max-height: 40vh; margin-bottom: 20px"]])
                    },
                    panel: {
                        parentElementId: PANEL_PARENT_ID
                    },
                    output: {
                        parentElementId: CODE_OUTPUT_PARENT_ID,
                        attributes: new Map([["style", "max-height: 28vh;"]])
                    },
                    input: {
                        parentElementId: CODE_INPUT_PARENT_ID
                    }
                }
                );
                await papyros.configureInput(false, location.origin, "inputServiceWorker.js");
                await papyros.launch();
            }
            if (editor) { // Start with code from the editor, if there is any
                const initialCode = editor.getValue();
                if (initialCode) {
                    papyros.setCode(initialCode);
                }
            }
        });
    }
}

export { initCodingScratchpad };
