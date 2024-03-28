import {
    initSeriesReorder,
    initCourseMembers,
    initCourseForm,
    initCourseNew,
    initCourseShow,
    loadUsers,
} from "course.ts";

import {
    RefreshingQuestionTable,
    toggleQuestionNavDot
} from "question_table.ts";
import { setDocumentTitle } from "utilities.ts";

window.dodona.initSeriesReorder = initSeriesReorder;
window.dodona.initCourseForm = initCourseForm;
window.dodona.initCourseNew = initCourseNew;
window.dodona.initCourseShow = initCourseShow;
window.dodona.initCourseMembers = initCourseMembers;
window.dodona.loadUsers = loadUsers;

window.dodona.questionTable = RefreshingQuestionTable;
window.dodona.setDocumentTitle = setDocumentTitle;
window.dodona.toggleQuestionNavDot = toggleQuestionNavDot;
