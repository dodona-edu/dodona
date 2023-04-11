import "search";
import { searchQuery } from "search";

import "components/search/sort_button.ts";
import "components/search/search_actions.ts";
import "components/search/search_field.ts";
import "components/search/search_token.ts";
import "components/search/filter_button.ts";
import "components/search/dropdown_filter";
import "components/search/filter_tabs";
import "components/search/standalone-dropdown-filter";
import "components/search/loading_bar";

window.dodona.searchQuery = searchQuery;
