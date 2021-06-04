import {
    initSeriesReorder,
    initCourseMembers,
    initCourseForm,
    initCourseNew,
    initCourseShow,
    initCoursesListing,
    loadUsers,
} from "course.js";

import {
    RefreshingQuestionTable,
    toggleQuestionNavDot
} from "question_table.ts";
import { setDocumentTitle } from "util.js";

window.dodona.initSeriesReorder = initSeriesReorder;
window.dodona.initCourseForm = initCourseForm;
window.dodona.initCourseNew = initCourseNew;
window.dodona.initCourseShow = initCourseShow;
window.dodona.initCourseMembers = initCourseMembers;
window.dodona.initCoursesListing = initCoursesListing;
window.dodona.loadUsers = loadUsers;

window.dodona.questionTable = RefreshingQuestionTable;
window.dodona.setDocumentTitle = setDocumentTitle;
window.dodona.toggleQuestionNavDot = toggleQuestionNavDot;
