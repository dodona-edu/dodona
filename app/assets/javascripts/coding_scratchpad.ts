import { InputMode, Papyros, ProgrammingLanguage } from "@dodona/papyros";

/**
 * Custom interface to not have to add the ace package as dependency
 */
interface Editor {
    setValue(v: string): void;
    getValue(): string;
}

const CODE_EDITOR_PARENT_ID = "papyros-editor-wrapper";
const PANEL_PARENT_ID = "papyros-panel-wrapper";
const CODE_OUTPUT_PARENT_ID = "papyros-output-wrapper";
const CODE_INPUT_PARENT_ID = "papyros-input-wrapper";
const SHOW_OFFCANVAS_BUTTON_ID = "papyros-offcanvas-show-btn";
const CODE_COPY_BUTTON_ID = "papyros-code-copy-btn";

function initCodingScratchpad(programmingLanguage: ProgrammingLanguage, editor?: Editor): void {
    if (Papyros.supportsProgrammingLanguage(programmingLanguage)) {
        let papyrosLaunched = false;
        const papyros = Papyros.fromElement(
            {
                programmingLanguage: Papyros.toProgrammingLanguage(programmingLanguage),
                standAlone: false,
                locale: I18n.locale,
                inputMode: InputMode.Interactive,
            }, {
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

        document.getElementById(SHOW_OFFCANVAS_BUTTON_ID).addEventListener("click", async function () {
            if (!papyrosLaunched) {
                await papyros.configureInput(false, location.origin, "inputServiceWorker.js");
                await papyros.launch();
                papyrosLaunched = true;
            }
            if (!editor) {
                return;
            }
            const initialCode = editor.getValue();
            if (initialCode) {
                papyros.setCode(initialCode);
            }
        });
        const codeCopyButton = document.getElementById(CODE_COPY_BUTTON_ID);
        if (editor) {
            codeCopyButton.addEventListener("click", function () {
                editor.setValue(papyros.getCode());
            });
        } else {
            codeCopyButton.classList.add("hidden");
        }
    }
}

export { initCodingScratchpad };
