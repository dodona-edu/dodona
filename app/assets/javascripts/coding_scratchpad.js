import { InputMode, Papyros, plFromString } from "@dodona/papyros";

function initCodingScratchpad(programmingLanguage, editor = undefined) {
    let papyrosLaunched = false;
    try {
        const pl = plFromString(programmingLanguage);
        const papyros = Papyros.fromElement(
            {
                programmingLanguage: pl,
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
                await Papyros.configureInput(false);
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

    } catch (e) {
        // Unsupported programming language, so do not initialize Papyros
        // Hide button that shows the off-canvas
        $("#papyros-offcanvas-show-btn").addClass("hidden");
        console.log("Error during initialization of Papyros", e);
    }
}

export { initCodingScratchpad };
