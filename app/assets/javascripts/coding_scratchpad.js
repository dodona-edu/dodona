import { InputMode, Papyros } from "@dodona/papyros";

function initCodingScratchpad(programmingLanguage, editor = undefined) {
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
                    parentElementId: "papyros-editor-wrapper",
                    attributes: new Map([["style", "max-height: 40vh; margin-bottom: 20px"]])
                },
                panel: {
                    parentElementId: "papyros-panel-wrapper"
                },
                output: {
                    parentElementId: "papyros-output-wrapper",
                    attributes: new Map([["style", "max-height: 28vh;"]])
                },
                input: {
                    parentElementId: "papyros-input-wrapper"
                }
            }
        );

        $("#papyros-offcanvas-show-btn").on("click", async function () {
            if (!papyrosLaunched) {
                await papyros.configureInput(false, "http://dodona.localhost:3000/", "inputServiceWorker.js");
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
        const $codeCopyButton = $("#papyros-code-copy-btn");
        if (editor) {
            $codeCopyButton.on("click", function () {
                editor.setValue(papyros.getCode());
            });
        } else {
            $codeCopyButton.addClass("hidden");
        }
    }
}

export { initCodingScratchpad };
