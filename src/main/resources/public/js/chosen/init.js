let chonsenConfigs = {
  'chosen-select'           : {search_contains: true, group_search: false},
  'chosen-select-max4'       : { max_selected_options : 4, search_contains: true, group_search: false},
  'chosen-select-deselect'  : { allow_single_deselect: true, search_contains: true, group_search: false},
  'chosen-select-deselect-single'  : { allow_single_deselect: true, max_selected_options : 1, search_contains: true, group_search: false},
  'chosen-select-no-single' : { disable_search_threshold: 10, search_contains: true, group_search: false},
  'chosen-select-no-results': { no_results_text: 'Oops, nothing found!', search_contains: true, group_search: false},
  'chosen-select-rtl'       : { rtl: true, search_contains: true, group_search: false},
  'chosen-select-width'     : { width: '95%', search_contains: true, group_search: false}
};

function chosen_init_all(container) {
    if (container) {
        for (let selector in chonsenConfigs) {
            container.find("."+selector).chosen("destroy");
            container.find("."+selector).chosen(chonsenConfigs[selector]);
        }
    } else {
        for (let selector in chonsenConfigs) {
            $("."+selector).chosen("destroy");
            $("."+selector).chosen(chonsenConfigs[selector]);
        }
    }
    
}

function chosen_init(id, className) {
    chosen_init_target($("#"+id), className);
}

function chosen_init_name(name, className) {
    chosen_init_target($("[name="+name+"]"), className);
}

function chosen_init_target(target, className) {
    if (target.length > 1) {
        target.each(function () {
           chosen_init_target($(this), className) ;
        });
    } else {
        target.chosen("destroy");
        if (className === undefined) {
            for (let selector in chonsenConfigs) {
                if (target.hasClass(selector)) {
                    target.chosen(chonsenConfigs[selector]);
                    return;
                }
            }
            target.chosen(chonsenConfigs["chosen-select"]);
        } else {
            target.chosen(chonsenConfigs[className]);
        }
    }
}