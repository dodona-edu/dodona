import { closeBrackets, closeBracketsKeymap } from "@codemirror/autocomplete";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import {
    bracketMatching,
    foldGutter,
    foldKeymap,
    HighlightStyle,
    indentOnInput, LanguageDescription,
    syntaxHighlighting
} from "@codemirror/language";
import { languages } from "@codemirror/language-data";
import {
    drawSelection,
    dropCursor,
    EditorView,
    highlightActiveLine,
    highlightActiveLineGutter,
    highlightSpecialChars,
    keymap,
    lineNumbers
} from "@codemirror/view";
import { tags } from "@lezer/highlight";
import { Extension } from "@codemirror/state";

declare type EditorEventHandler = (event: FocusEvent, view: EditorView) => boolean | void;


// A custom theme for CodeMirror that applies the same CSS as Rouge does,
// meaning we can use our existing themes.
const rougeStyle = HighlightStyle.define([
    { tag: tags.comment, class: "c" },
    { tag: tags.lineComment, class: "c" },
    { tag: tags.blockComment, class: "cm" },
    { tag: tags.docComment, class: "cs" },
    { tag: tags.name, class: "n" },
    { tag: tags.standard(tags.variableName), class: "nb" },
    { tag: tags.standard(tags.propertyName), class: "nb" },
    { tag: tags.special(tags.variableName), class: "nb" },
    { tag: tags.special(tags.propertyName), class: "nb" },
    { tag: tags.function(tags.propertyName), class: "nf" },
    { tag: tags.function(tags.variableName), class: "nf" },
    { tag: tags.variableName, class: "nv" },
    { tag: tags.typeName, class: "kt" },
    { tag: tags.tagName, class: "nt" },
    { tag: tags.propertyName, class: "py" },
    { tag: tags.attributeName, class: "na" },
    { tag: tags.className, class: "nc" },
    { tag: tags.labelName, class: "nl" },
    { tag: tags.namespace, class: "nn" },
    { tag: tags.macroName, class: "n" },
    { tag: tags.literal, class: "l" },
    { tag: tags.string, class: "s" },
    { tag: tags.docString, class: "sd" },
    { tag: tags.character, class: "sc" },
    { tag: tags.attributeValue, class: "g" },
    { tag: tags.number, class: "m" },
    { tag: tags.integer, class: "mi" },
    { tag: tags.float, class: "mf" },
    { tag: tags.bool, class: "l" },
    { tag: tags.regexp, class: "sr" },
    { tag: tags.escape, class: "se" },
    { tag: tags.color, class: "l" },
    { tag: tags.url, class: "l" },
    { tag: tags.keyword, class: "k" },
    { tag: tags.self, class: "k" },
    { tag: tags.null, class: "l" },
    { tag: tags.atom, class: "l" },
    { tag: tags.unit, class: "l" },
    { tag: tags.modifier, class: "g" },
    { tag: tags.operatorKeyword, class: "ow" },
    { tag: tags.controlKeyword, class: "k" },
    { tag: tags.definitionKeyword, class: "kd" },
    { tag: tags.moduleKeyword, class: "kn" },
    { tag: tags.operator, class: "o" },
    { tag: tags.derefOperator, class: "o" },
    { tag: tags.arithmeticOperator, class: "o" },
    { tag: tags.logicOperator, class: "o" },
    { tag: tags.bitwiseOperator, class: "o" },
    { tag: tags.compareOperator, class: "o" },
    { tag: tags.updateOperator, class: "o" },
    { tag: tags.definitionOperator, class: "o" },
    { tag: tags.typeOperator, class: "o" },
    { tag: tags.controlOperator, class: "o" },
    { tag: tags.punctuation, class: "p" },
    { tag: tags.separator, class: "dl" },
    { tag: tags.bracket, class: "p" },
    { tag: tags.angleBracket, class: "p" },
    { tag: tags.squareBracket, class: "p" },
    { tag: tags.paren, class: "p" },
    { tag: tags.brace, class: "p" },
    { tag: tags.content, class: "g" },
    { tag: tags.heading, class: "gh" },
    { tag: tags.heading1, class: "gu" },
    { tag: tags.heading2, class: "gu" },
    { tag: tags.heading3, class: "gu" },
    { tag: tags.heading4, class: "gu" },
    { tag: tags.heading5, class: "gu" },
    { tag: tags.heading6, class: "gu" },
    { tag: tags.contentSeparator, class: "dl" },
    { tag: tags.list, class: "p" },
    { tag: tags.quote, class: "p" },
    { tag: tags.emphasis, class: "ge" },
    { tag: tags.strong, class: "gs" },
    { tag: tags.link, class: "g" },
    { tag: tags.monospace, class: "go" },
    { tag: tags.strikethrough, class: "gst" },
    { tag: tags.inserted, class: "gi" },
    { tag: tags.deleted, class: "gd" },
    { tag: tags.changed, class: "g" },
    { tag: tags.invalid, class: "err" },
    { tag: tags.meta, class: "c" }
]);

// Basic, built-in extensions.
const editorSetup = (() => [
    lineNumbers(),
    highlightActiveLineGutter(),
    highlightSpecialChars(),
    history(),
    foldGutter(),
    drawSelection(),
    dropCursor(),
    indentOnInput(),
    bracketMatching(),
    closeBrackets(),
    highlightActiveLine(),
    keymap.of([
        ...closeBracketsKeymap,
        ...defaultKeymap,
        ...historyKeymap,
        ...foldKeymap,
    ]),
    syntaxHighlighting(rougeStyle, {
        fallback: true
    })
])();


// The "@codemirror/language-data" does not support community languages,
// so we add support for those ourselves.
const additionalLanguages = [
    LanguageDescription.of({
        name: "R",
        alias: ["rlang"],
        extensions: ["r"],
        load() {
            return import("codemirror-lang-r").then(m => m.r());
        }
    }),
    LanguageDescription.of({
        name: "Prolog",
        alias: ["rlang"],
        extensions: ["pl", "pro", "p"],
        load() {
            return import("codemirror-lang-prolog").then(m => m.prolog());
        }
    }),
    LanguageDescription.of({
        name: "C#",
        alias: ["csharp", "cs"],
        extensions: ["cs"],
        load() {
            return import("@replit/codemirror-lang-csharp").then(m => m.csharp());
        }
    }),
];


async function loadProgrammingLanguage(language: string): Promise<Extension | undefined> {
    const potentialLanguages = additionalLanguages.concat(languages);
    const description = LanguageDescription.matchLanguageName(potentialLanguages, language);
    if (description) {
        await description.load();
        return description.support;
    }
    console.warn(`${language} is not supported by our editor, falling back to nothing.`);
}

/**
 * Set up the code editor.
 *
 * @param parent The element to insert the editor into. Existing content will be inserted into the editor.
 * @param programmingLanguage The programming language of the editor. Will attempt to load language support.
 * @param focusHandler A callback that will be called when the editor receives focus.
 */
export async function configureEditor(parent: Element, programmingLanguage: string, focusHandler: EditorEventHandler): Promise<EditorView> {
    const existingCode = parent.textContent;
    // Clear the existing code, as we will put it in CodeMirror.
    parent.textContent = "";
    const eventHandlers = EditorView.domEventHandlers({
        "focus": focusHandler
    });
    const languageSupport = await loadProgrammingLanguage(programmingLanguage);
    const languageExtensions = [];
    if (languageSupport !== undefined) {
        languageExtensions.push(languageSupport);
    }
    return new EditorView({
        doc: existingCode,
        extensions: [
            // Basic editor functionality
            editorSetup,
            // Listen for focus
            eventHandlers,
            // Language support
            ...languageExtensions
        ],
        parent: parent
    });
}


/**
 * Set the content of a code editor.
 *
 * @param editorView The code editor to set the content in.
 * @param code The code to insert.
 */
export function setCode(editorView: EditorView, code: string): void {
    editorView.dispatch(editorView.state.update({
        changes: {
            from: 0,
            to: editorView.state.doc.length,
            insert: code,
        }
    }));
}
