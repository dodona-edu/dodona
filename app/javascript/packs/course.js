import {
    initSeriesReorder,
    initCourseMembers,
    initCourseForm,
    initCourseNew,
    initCourseShow,
    loadUsers,
} from "course.js";

import {
    timerWithoutUser
} from "code_listing/auto_reload.ts";

window.dodona.initSeriesReorder = initSeriesReorder;
window.dodona.initCourseForm = initCourseForm;
window.dodona.initCourseNew = initCourseNew;
window.dodona.initCourseShow = initCourseShow;
window.dodona.initCourseMembers = initCourseMembers;
window.dodona.loadUsers = loadUsers;

window.dodona.questionsAutoReload = timerWithoutUser;
