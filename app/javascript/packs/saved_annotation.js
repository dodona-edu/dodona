import "components/saved_annotations/saved_annotation_title_input";
import "components/saved_annotations/new_saved_annotation";
import "components/search/sort_button";
import "components/saved_annotations/new_saved_annotation_link";
import { initNewSavedAnnotationButtons } from "components/saved_annotations/new_saved_annotation";
import { search } from "search";

dodona.initNewSavedAnnotationButtons = initNewSavedAnnotationButtons;
dodona.initSortButtons = () => search.autoSearch = true;
