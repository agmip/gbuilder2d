
<!DOCTYPE html>
<html>
    <head>
        <#include "../header.ftl">
        <#include "../chosen.ftl">
        <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/handsontable-pro@latest/dist/handsontable.full.min.css">
        <link rel="stylesheet" type="text/css" href="/stylesheets/toggle/bootstrap-toggle.min.css" />
        <link rel="stylesheet" type="text/css" href="/plugins/jsonViewer/jquery.json-viewer.css" />
        <script>
            const preferColors = ["#33DBFF", "#FF5733", "#33FF57", "#BD33FF", "#802B1A", "#3383FF", "#FFAF33", "#3ADDD6"];
            let wbObj;
//            let spsContainer;
            let spreadsheet;
            let refSpreadsheet;
            let curSheetName;
            let templates = {};
            let curFileName;
            let dirName;
            let isChanged;
            let isViewUpdated;
            let isDebugViewUpdated;
//            let workbook;
            let workbooks = {};
            let fileTypes = {};
            let fileUrls = {};
            let userVarMap = {};
            let fileColors = {};
            let virColCnt = {};
            let lastHeaderRow = {};
            let primaryVarExisted = {EXNAME: false, SOIL_ID: false, WST_ID: false};
            const eventDateMapping = {
                def : {
                    "planting" : "pdate",
                    "irrigation" : "idate",
                    "fertilizer" : "fedate",
                    "tillage" : "tdate",
                    "organic_material" : "omdat",
                    "harvest" : "hadat",
                    "inorg_mulch" : "mladat",
                    "Inorg_mul_rem" : "mlrdat",
                    "chemicals" : "cdate",
                    "observation" : "date",
                    "flood_level" : "idate",
                    "other" : "evdate"
                },
                getEventDateVarName : function (eventType) {
                    if (this.def[eventType]) {
                        return this.def[eventType];
                    } else {
                        return "evdate";
                    }
                }
            };
            let icasaVarMap = {
                "management" : {
                    <#list icasaMgnVarMap?values?sort_by("code_display")?sort_by("set_group_order") as var>
                    "${var.code_display}" : {
                        code_display : "${var.code_display?js_string}",
                        description : '${var.description?js_string}',
                        unit_or_type : "${var.unit_or_type?js_string}",
                        dataset : "${var.dataset?js_string}",
                        subset : "${var.subset?js_string}",
                        group : "${var.group?js_string}",
                        <#if var.subgroup??>subgroup : "${var.subgroup}",</#if>
                        order : ${var.set_group_order},
                        agmip_data_entry : "${var.agmip_data_entry}",
                        category : "${var.dataset} / ${var.subset} / ${var.group}"
                    }<#sep>,</#sep>
                    </#list>
                },
                "observation" : {
                    <#list icasaObvVarMap?values?sort_by("code_display")?sort_by("set_group_order") as var>
                    "${var.code_display}" : {
                        code_display : "${var.code_display?js_string}",
                        description : "${var.description?js_string}",
                        unit_or_type : "${var.unit_or_type?js_string}",
                        dataset : "${var.dataset?js_string}",
                        subset : "${var.subset?js_string}",
                        group : "${var.group?js_string}",
                        <#if var['sub-group']??>subgroup : "${var['sub-group']}",</#if>
                        order : ${var.set_group_order},
                        agmip_data_entry : "${var.agmip_data_entry}",
                        category : "${var.dataset} / ${var.subset} / ${var.group}"
                    }<#sep>,</#sep>
                    </#list>
                },
                "allDefs" : null,
                "getAllDefs" : function () {
                    if (!this.allDefs) {
                        this.allDefs = {};
                        for (let i in this.management) {
                            this.allDefs[i] = this.management[i];
                        }
                        for (let i in this.observation) {
                            if (this.allDefs[i]) {
                                console.log("[warning] repeated ICASA definition detected! " + this.observation[i].code_display);
                            }
                            this.allDefs[i] = this.observation[i];
                        }
                    }
                    return this.allDefs;
                },
                "groupList" : null,
                "getGroupList" : function() {
                    if (!this.groupList) {
                        this.groupList = {};
                        for (let varName in this.management) {
                            if (!this.groupList[this.management[varName].order]) {
                                this.groupList[this.management[varName].order] = this.management[varName];
                            }
                        }
                        for (let varName in this.observation) {
                            if (!this.groupList[this.observation[varName].order]) {
                                this.groupList[this.observation[varName].order] = this.observation[varName];
                            }
                        }
                    }
                    return this.groupList;
                },
                "getPrimaryGroup" : function(varName) {
                    if (this.management[varName]) {
                        return this.management;
                    } else if (this.observation[varName]) {
                        return this.observation;
                    } else {
                        return null;
                    }
                },
                "isDefined" : function(varName) {
                    return !!this.getPrimaryGroup(varName);
                },
                "getDefinition" : function(varName) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        return group[varName];
                    } else {
                        return null;
                    }
                    
                },
                "getUnit" : function(varName) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        return group[varName].unit_or_type;
                    } else {
                        return null;
                    }
                },
                "getDesc" : function(varName) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        return group[varName].description;
                    } else {
                        return null;
                    }
                },
                "getDataset" : function(varName, isLower) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        if (isLower) {
                            return group[varName].dataset.toLowerCase();
                        } else {
                            return group[varName].dataset;
                        }
                    } else {
                        return null;
                    }
                },
                "getSubset" : function(varName, isLower) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        if (isLower) {
                            return group[varName].subset.toLowerCase();
                        } else {
                            return group[varName].subset;
                        }
                    } else {
                        return null;
                    }
                },
                "getGroup" : function(varName, isLower) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        if (isLower) {
                            return group[varName].group.toLowerCase();
                        } else {
                            return group[varName].group;
                        }
                    } else {
                        return null;
                    }
                },
                "getSubGroup" : function(varName, isLower) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        if (isLower) {
                            return group[varName].subgroup.toLowerCase();
                        } else {
                            return group[varName].subgroup;
                        }
                    } else {
                        return null;
                    }
                },
                "getOrder" : function(varName) {
                    let group = this.getPrimaryGroup(varName);
                    if (group) {
                        return group[varName].order;
                    } else {
                        return -1;
                    }
                },
                "getMappingOrder" : function(mapping) {
                    if (mapping.order) {
                        return mapping.order;
                    }
                    let icasa = mapping.icasa;
                    if (!icasa) {
                        icasa = mapping.column_header;
                    }
                    return this.getOrder(icasa);
                },
                "icasaDataCatDef" : null,
                "getIcasaDataCatDefMapping" : function(mapping) {
                    return this.getIcasaDataCatDef(this.getMappingOrder(mapping));
                },
                "getIcasaDataCatDef" : function(order) {
                    if (!this.icasaDataCatDef) {
                        this.initIcasaDataCatDef();
//                        console.log(this.icasaDataCatDef);
                    }
                    if (!order || !this.icasaDataCatDef[order]) {
                        return {rank: -1, category: "unknown", order: order};
                    }
                    return this.icasaDataCatDef[order];
                },
                "initIcasaDataCatDef" : function() {
                    this.icasaDataCatDef = {};
                    let relations = {};
                    let lastCat;
                    let parentCat;
                    let trtCat;// = this.getCategory(this.management["TRTNO"]);
                    let fieldCat;
//                    let metaCat = this.getCategory(this.management["EXNAME"]);
                    let soilProfileCat; // = this.getCategory(this.management["SOIL_NAME"]);
                    let defs = this.getAllDefs();
                    // Put adjusted/preload required categories processing before other categories.
                    let adjDefs = ["TRTNO", "FL_LAT", "SOIL_NAME", "SL_SOURCE"];
                    let preProcessOrders = [];
                    for (let i in adjDefs) {
                        let varName = adjDefs[i];
                        let order = defs[varName].order;
                        let curCat = this.getCategory(defs[varName]);
                        this.icasaDataCatDef[order] = curCat;
                        let category = curCat.category;
                        if (!relations[category]) {
                            relations[category] = [];
                        }
                        relations[category].push(order);
                        preProcessOrders.push(order);
                        if (varName === "TRTNO") {
                            trtCat = curCat;
                            trtCat.child = [];
                        } else if (varName === "SOIL_NAME") {
                            soilProfileCat = curCat;
                        } else if (varName === "FL_LAT") {
                            fieldCat = curCat;
                        }
                    }
                    for (let varName in defs) {
                        let order = defs[varName].order;
                        let curCat;
                        if (preProcessOrders.includes(order)) {
                            preProcessOrders.splice(preProcessOrders.indexOf(order), 1);
                            curCat = this.icasaDataCatDef[order];
                        } else if (this.icasaDataCatDef[order]) {
                            continue;
                        } else {
                            curCat = this.getCategory(defs[varName]);
                            this.icasaDataCatDef[order] = curCat;

                            let category = curCat.category;
                            if (!relations[category]) {
                                relations[category] = [];
                            } else {
                                if (this.icasaDataCatDef[relations[category][0]].parent) {
                                    curCat.parent = this.icasaDataCatDef[relations[category][0]].parent;
                                }
                                if (this.icasaDataCatDef[relations[category][0]].child) {
                                    curCat.child = this.icasaDataCatDef[relations[category][0]].child;
                                }
                            }
                            relations[category].push(order);
                        }
//                        else if (curCat.rank === 1) {
//                            metaCat = curCat;
//                        }
                        if (!parentCat) {
                            parentCat = curCat;
                        } else if (curCat.rank === 4 && curCat.order > 4000) {
                            parentCat = fieldCat;
                        } else if (curCat.rank === 6 && curCat.order < 3000) {
                            // Special handling for soil analysis category, and mark it to be child of soil profile meta (4041, 4042)
                            parentCat = soilProfileCat;
                        } else if (curCat.rank - lastCat.rank === 1) {
                            parentCat = lastCat;
                        }
                        if (curCat.rank - parentCat.rank === 1) {
                            this.buildRelation(relations, curCat, parentCat);
                        } else {
                            if (curCat.rank === 3) {
                                trtCat.child.push(curCat.order);
                                if (!curCat.parent) {
                                    curCat.parent = [trtCat.order];
                                }
                            }
//                            else if (curCat.rank === 0) {
//                                let parArr = [];
//                                curCat.child = relations[metaCat.category];
//                                for (let i in curCat.child) {
//                                    if (!this.icasaDataCatDef[curCat.child[i]].parent) {
//                                        this.icasaDataCatDef[curCat.child[i]].parent = parArr;
//                                    } else {
//                                        parArr = this.icasaDataCatDef[curCat.child[i]].parent;
//                                    }
//                                }
//                                parArr.push(curCat.order);
//                            }
                        }
                        lastCat = curCat;
                    }
                    console.log("relations: ");
                    console.log(relations);
                },
                "buildRelation" : function(relations, curCat, parentCat) {
                    if (!parentCat.child) {
                        parentCat.child = [];
                    }
                    if (!curCat.parent) {
                        curCat.parent = [];
                    }
                    for (let i in relations[parentCat.category]) {
                        let parCode = relations[parentCat.category][i];
                        if (!this.icasaDataCatDef[parCode].child) {
                            this.icasaDataCatDef[parCode].child = parentCat.child;
                        }
                        if (!curCat.parent.includes(parCode)) {
                            curCat.parent.push(parCode);
                        }
                    }
                    for (let i in relations[curCat.category]) {
                        let chdCode = relations[curCat.category][i];
                        if (!this.icasaDataCatDef[chdCode].parent) {
                            this.icasaDataCatDef[chdCode].parent = curCat.parent;
                        }
                        if (!parentCat.child.includes(chdCode)) {
                            parentCat.child.push(chdCode);
                        }
                    }
                },
                "getCategory" : function(mapping) {
                    let icasa = mapping.icasa;
                    if (!icasa) {
                        icasa = mapping.column_header;
                    }
                    if (!icasa) {
                        icasa = mapping.code_display;
                    }
                    let order = this.getOrder(icasa);
                    let dataset = this.getDataset(icasa, true);
                    let subset = this.getSubset(icasa, true);
                    let group = this.getGroup(icasa, true);
                    let subgroup = this.getSubGroup(icasa, true);
                    if (order < 0) {
                        return {rank: -1, category: "unknown"};
                    } else if (order > 8000 && order < 9000) {
                        return {rank: 3, category: dataset, order: order};
                    } else if (order < 2000) {
                        return {rank: 3, category: subset, order: order};
                    } else if (order < 3000) {
                        if (order === 2011) {
                            return {rank: 2, category: group, order: order};
                        } else if (order === 2041) {
                            return {rank: 6, category: group, order: order};
                        } else if (order === 2042) {
                            return {rank: 7, category: subgroup, order: order};
                        } else if (order > 2500) {
                            return {rank: 3, category: subset, order: order};
                        } else {
                            if (subgroup) {
                                return {rank: 4, category: subgroup, order: order};
                            } else {
                                return {rank: 3, category: group, order: order};
                            }
                        }
                    } else if (order < 4000) {
                        return {rank: 3, category: subset, order: order};
                    } else if (order < 5000) {
                        if (order === 4051) {
                            return {rank: 6, category: group, order: order};
                        } else if (order === 4052) {
                            return {rank: 7, category: subgroup, order: order};
                        } else if (order > 4040) {
                            return {rank: 5, category: group, order: order};
                        } else {
                            return {rank: 4, category: subset, order: order};
                        }
                    } else if (order < 6000) {
                        if (order === 5052) {
                            return {rank: 6, category: group, order: order};
                        } if (order > 5040) {
                            return {rank: 5, category: subset, order: order};
                        } else {
                            return {rank: 4, category: subset, order: order};
                        }
                    } else if (order < 8000) {
                        return {rank: 3, category: group, order: order};
                    } else if (order < 10000) {
                        return {rank: 3, category: subset, order: order};
                    } else {
                        return {rank: -1, category: "unknown", order: order};
                    }
                },
                "icasaCode" : {
                    <#list icasaMgnCodeMap?keys as key>
                    ${key}:{
                    <#list icasaMgnCodeMap[key]?keys as code>
                        ${code?js_string} : "${icasaMgnCodeMap[key][code]?js_string}"<#sep>,</#sep>
                    </#list>
                    },
                    </#list>
                    "crid" : {
                    <#list culMetaList as culMeta>
                        "${culMeta.crop_code!}" : "${culMeta.common_name?js_string!?js_string}"<#sep>,</#sep>
                    </#list>
                    }
                },
                "getCodeMap" : function(icasa, defRet) {
                    if (!icasa) {
                        return defRet;
                    }
                    icasa = icasa.toLowerCase();
                    if (this.icasaCode[icasa]) {
                        return this.icasaCode[icasa];
                    } else {
                        return defRet;
                    }
                },
                "isCodeDefExisted" : function (icasa) {
                    if (!icasa) {
                        return false;
                    }
                    icasa = icasa.toLowerCase();
                    return !!this.icasaCode[icasa];
                }
            };

            function getFileName(fileFullName) {
                if (!fileFullName) {
                    return fileFullName;
                }
                let lastDot = fileFullName.lastIndexOf(".");
                if (lastDot < 0) {
                    return fileFullName;
                } else {
                    return fileFullName.substring(0, lastDot);
                }
            }
            
            function readSpreadSheet(target, sc2Files) {
                let files = target.files;
                let colors = [];
                virColCnt = {};
                lastHeaderRow = {};
                for (let i = 0; i < files.length; i++) {
                    if (i < preferColors.length) {
                        colors.push(preferColors[i]);
                    } else {
                        let color = '#'+(0x1000000+(Math.random())*0xffffff).toString(16).substr(1,6);
                        while (colors.includes(color)) {
                            color = '#'+(0x1000000+(Math.random())*0xffffff).toString(16).substr(1,6);
                        }
                        colors.push(color);
                    }
                    virColCnt[files[i].name] = {};
                    lastHeaderRow[files[i].name] = {};
                }
                primaryVarExisted = {EXNAME: false, SOIL_ID: false, WST_ID: false};
                let idx = 0;
                userVarMap = {};
                workbooks = {};
                fileTypes = {};
                fileUrls = {};
                templates = {};
                fileColors = {};
                curFileName = null;
                curSheetName = null;
                wbObj = null;
                isChanged = false;
                isViewUpdated = false;
                isDebugViewUpdated = false;
                let reader = new FileReader();
//                reader.onloadend = function(e) {
//                    let data = e.target.result;
//                    console.time();
//                    
//                    workbook = new ExcelJS.Workbook();
//                    workbooks[fileName] = workbook;
//                    workbook.xlsx.load.then(function(workbook) {
//                        console.timeEnd();
//                        if (idx < files.length) {
//                            f = files[idx];
//                            idx++;
//                            loadingDialog.find(".loading-msg").html(' Loading ' + fileName + ' (' + idx + '/' + files.length + ') ...');
//                            reader.readAsArrayBuffer(f);
//                        } else {
//                            loadingDialog.modal('hide');
//                            if (sc2Files.files && sc2Files.files.length > 0) {
//                                readSC2Json(sc2Files);
//                            } else {
//                                showSheetDefDialog(processData);
//                            }
//                        }
//                    });
//                };
                reader.onloadend = function(e) {
                    let data = e.target.result;
//                    data = new Uint8Array(data);
//                    console.time();
                    if (fileName.toLowerCase().endsWith(".csv")) {
                        data = data.replace(/\t/gi, "    ");
                    }
                    workbook = XLSX.read(data, {type: 'binary', dateNF: "yyyy-MM-dd"});
                    workbooks[fileName] = workbook;
//                    workbook = XLSX.read(data, {type: 'array'});
//                    console.timeEnd();
                    
                    if (idx < files.length) {
                        f = files[idx];
                        fileName = f.name;
                        fileTypes[fileName] = f.type;
                        fileUrls[fileName] = "";
                        fileColors[fileName] = colors.shift();
                        idx++;
                        loadingDialog.find(".loading-msg").html(' Loading ' + fileName + ' (' + idx + '/' + files.length + ') ...');
                        reader.readAsBinaryString(f);
//                        reader.readAsArrayBuffer(f);
                    } else {
                        loadingDialog.modal('hide');
                        $(".mapping_gengeral_info").val("");
                        $("#file_url_inputs").html("");
                        if (sc2Files.files && sc2Files.files.length > 0) {
                            readSC2Json(sc2Files);
                        } else {
                            showSheetDefDialog(processData);
                        }
                    }
                };
                
                // Start to read the first file
                let f = files[idx];
                idx++;
                let fileName = f.name;
                fileTypes[fileName] = f.type;
                fileUrls[fileName] = "";
                fileColors[fileName] = "";
                let loadingDialog = bootbox.dialog({
                    message: '<h4><span class="glyphicon glyphicon-refresh spinning"></span><span class="loading-msg"> Loading ' + fileName + ' (1/' + files.length + ') ...</span></h4></br><p><mark>MS Excel File (> 1 MB)</mark> might experice longer loading time...</p>',
//                    centerVertical: true,
                    closeButton: false
                });
                loadingDialog.on("shown.bs.modal", function() {
//                    reader.readAsArrayBuffer(f);
                    reader.readAsBinaryString(f);
                });
            }
            
            function processData(ret, editFlg) {
                if (ret) {
                    if (editFlg) {
                        templates = ret;
                    } else {
                        for (let fileName in ret) {
                            for (let sheetName in ret[fileName]) {
                                if (fileName !== ret[fileName][sheetName].file_def) {
                                    fileUrls[fileName] = fileUrls[ret[fileName][sheetName].file_def];
                                    delete fileUrls[ret[fileName][sheetName].file_def];
                                }
                                break;
                            }
                            if (!templates[fileName]) {
                                templates[fileName] = ret[fileName];
                            } else {
                                for (let sheetName in ret[fileName]) {
                                    let preSheetName = ret[fileName][sheetName].sheet_def;
                                    if (preSheetName) {
                                        if (templates[fileName][preSheetName]) {
                                            updateSheetName(fileName, preSheetName, sheetName);
                                        }
                                    } else if (!templates[fileName][sheetName]) {
                                        templates[fileName][sheetName] = ret[fileName][sheetName];
                                    }
                                }
                            }
                        }
                    }
                }
                if (workbooks) {
                    $("#sheet_csv_content").html(to_csv(workbooks));
//                        $("#sheet_json_content").html(to_json(workbooks));
                }

                if (!curFileName || !curSheetName) {
                    wbObj = {};
                }
                for (let fileName in templates) {
                    for (let sheetName in templates[fileName]) {
                        if (!virColCnt[fileName][sheetName]) {
                            virColCnt[fileName][sheetName] = 0;
                        }
                    }
                }
//                for (let name in workbooks) {
//                    if (workbooks[name]) {
//                        wbObj[name] = to_object(workbooks[name], name);
//                    }
//                }
                wbObj = to_objects(workbooks);
                for (let fileName in templates) {
                    for (let sheetName in templates[fileName]) {
                        let sheetDef = templates[fileName][sheetName];
                        if (sheetDef.references) {
                            for (let fromKeyIdxs in sheetDef.references) {
                                for (let toKey in sheetDef.references[fromKeyIdxs]) {
                                    sheetDef.references[fromKeyIdxs][toKey].keys = getKeyArr(sheetDef.references[fromKeyIdxs][toKey].keys, templates[sheetDef.references[fromKeyIdxs][toKey].file][sheetDef.references[fromKeyIdxs][toKey].sheet].mappings);
                                }
                            }
                        }
                        if (sheetDef.data_start_row && wbObj[fileName] && wbObj[fileName][sheetName]) {
                            sheetDef.single_flg = isSingleRecordTable(wbObj[fileName][sheetName].data, sheetDef);
                        }
                    }
                }

                for (let fileName in fileUrls) {
                    let fileUrlDiv = $("#template_file_url_input").find("div").first().clone();
                    $("#file_url_inputs").append(fileUrlDiv);
                    fileUrlDiv.find("label").text("URL for " + fileName);
                    fileUrlDiv.find("input").val(fileUrls[fileName]).on("change", function() {
                        fileUrls[fileName] = $(this).val();
                    });
                }

                $('#sheet_tab_list').empty();
                for (let fileName in templates) {
                    $('#sheet_tab_list').append('<li class="dropdown-header"><strong>' + fileName + '</strong></li>');
                    for (let sheetName in templates[fileName]) {
                        let cntUndefined = countUndefinedColumns(templates[fileName][sheetName]);
                        if (cntUndefined > 0) {
                            $('#sheet_tab_list').append('<li><a data-toggle="tab" href="#spreadshet_tab" id="' + fileName + '__' + sheetName + '" onclick="setSpreadsheet(this);">' + sheetName + '&nbsp;&nbsp;<span class="label label-danger label-as-badge">' + cntUndefined + '</span></a></li>');
                        } else {
                            $('#sheet_tab_list').append('<li><a data-toggle="tab" href="#spreadshet_tab" id="' + fileName + '__' + sheetName + '" onclick="setSpreadsheet(this);">' + sheetName + '&nbsp;&nbsp;<span class="label label-danger label-as-badge invisible">' + cntUndefined + '</span></a></li>');
                        }
                    }
                    $('#sheet_tab_list').append('<li class="divider"></li>');
                }

                if (curFileName && curSheetName && templates[curFileName] && templates[curFileName][curSheetName]) {
//                    initSpreadsheet(curFileName, curSheetName);
                    let linkId = curFileName + "__" + curSheetName;
                    $('#sheet_tab_list').find("[id='" + linkId +"']").click();
                } else {
                    $('#sheet_tab_list').find("a").first().click();
                }
            }
            
            function updateSheetName(fileName, preSheetName, sheetName) {
                templates[fileName][sheetName] = templates[fileName][preSheetName];
                templates[fileName][sheetName].sheet_name = sheetName;
                delete templates[fileName][preSheetName];
                for (let i in templates) {
                    for (let j in templates[i]) {
                        if (templates[i][j].references) {
                            updateSheetReference(templates[i][j].references, fileName, preSheetName, sheetName);
                        }
                    }
                }
            }
            
            function updateSheetReference(references, fileName, preSheetName, sheetName) {
                for (let fromKeyIdx in references) {
                    for (let refToKey in references[fromKeyIdx]) {
                        if (refToKey.includes("[" + fileName + "][" + preSheetName + "]:")) {
                            let newRefToKey = refToKey.replace("][" + preSheetName + "]:", "][" + sheetName + "]:");
                            references[fromKeyIdx][newRefToKey] = references[fromKeyIdx][refToKey];
                            delete references[fromKeyIdx][refToKey];
                            refToKey = newRefToKey;
                        }
                        if (references[fromKeyIdx][refToKey].sheet === preSheetName) {
                            references[fromKeyIdx][refToKey].sheet = sheetName;
                        }
                    }
                }
            }
            
            function countUndefinedColumns(sheetDef) {
                let ret = 0;
                if (!sheetDef.data_start_row) {
                    ret = 1;
                } else {
                    let mappings = sheetDef.mappings;
                    for (let i in mappings) {
                        let classNames = getColStatusClass(i, mappings);
                        if (classNames.includes("warning") || classNames.includes("danger")) {
                            ret++;
                        }
                    }
                }
                return ret;
            }
            
            function to_json(workbooks) {
                return JSON.stringify(to_objects(workbooks), 2, 2);
            }
            
//            function sheet_to_json(sheet, includeEmpty) {
//                let roa = [];
//                if (!includeEmpty) {
//                    includeEmpty = true;
//                }
//                sheet.eachRow({ includeEmpty: includeEmpty }, function(row, rowNumber) {
//                    let tmp = [];
//                    row.eachCell({ includeEmpty: includeEmpty }, function(cell, colNumber) {
//                       tmp.push(cell.text) ;
//                    });
//                    roa.push(tmp);
//                });
//                return roa;
//            }
            function to_objects(workbooks) {
                let ret = {};
                for (let fileName in workbooks) {
                    if (workbooks[fileName]) {
                        ret[fileName] = to_object(workbooks[fileName], fileName);
                    }
                }
                // update reference
                for (let fileName in templates) {
                    for (let sheetName in templates[fileName]) {
                        let sheetDef = templates[fileName][sheetName];
                        sheetDef.references = {};
                        let refConfig = sheetDef.references_org;
                        let references = sheetDef.references;
                        for (let j in refConfig) {
                            let refDef = refConfig[j];
                            let fromKeyIdxs = getKeyIdxArr(refDef.from.keys, sheetDef.mappings);
                            let toKeyIdxs = getKeyIdxArr(refDef.to.keys, templates[refDef.to.file][refDef.to.sheet].mappings);
                            let toKey = getRefDefKey(refDef.to, toKeyIdxs);
                            if (!references[fromKeyIdxs]) {
                                references[fromKeyIdxs] = {};
                            }
                            references[fromKeyIdxs][toKey] = {
                                file: refDef.to.file,
                                sheet: refDef.to.sheet,
                                keys: toKeyIdxs //getKeyArr(toKeyIdxs, mappings)
                            };
                        }
                        delete sheetDef.references_org;
                    }
                }
//                workbook.SheetNames.forEach(function(sheetName) {
//                    if (templates[fileName][sheetName]) {
//                        shiftRefToKeyIdx(templates[fileName][sheetName]);
//                    }
//                });
                return ret;
            }
            
            function to_object(workbook, fileName) {
                let result = {};
                for (let sheetName in templates[fileName]) {
                    if (!workbook.Sheets[sheetName]) {
                        delete templates[fileName][sheetName];
                    }
                }
                workbook.SheetNames.forEach(function(sheetName) {
//                workbook.worksheets.forEach(function(sheet) {
//                    let sheetName = sheet.name;
                    if (!templates[fileName] || !templates[fileName][sheetName]) {
                        return;
                    }
                    // Only reload current sheet when editting row definition
                    if ((curFileName && curFileName !== fileName) || 
                            (curSheetName && sheetName !== curSheetName)) {
                        result[sheetName] = wbObj[fileName][sheetName];
                        if (isChanged) {
                            return;
                        }
                    }
                    let roa;
                    let sheetDef = templates[fileName][sheetName];
                    let headers;
                    if (wbObj[fileName] && wbObj[fileName][sheetName]) {
                        result[sheetName] = wbObj[fileName][sheetName];
                        roa = result[sheetName].data;
                        headers = result[sheetName].header;
                    }
                    // Do re-read data when 1, no data loaded; 2, load SC2 file with virtual column but not the case of change row define
                    if (!roa || (virColCnt[fileName][sheetName] && !isChanged)) {
                        roa = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], {header:1, raw: false, dateNF: "yyyy-MM-dd"});
                        for (let i = roa.length; i >= 0; i--) {
                            if (roa[i] && roa[i].length > 0) {
                                roa.splice(i + 1, roa.length - i);
                                break;
                            }
                        }
//                        let roa = sheet_to_json(sheet);
                        
                        result[sheetName] = {};
                        result[sheetName].data = roa;
                    }
                    if (sheetDef.header_row !== lastHeaderRow[fileName][sheetName] || !headers || headers.length === 0) {
                        // store sheet data
                        if (sheetDef.header_row) {
                            headers = roa[sheetDef.header_row - 1];
                            lastHeaderRow[fileName][sheetName] = sheetDef.header_row;
                            for (let i = 0; i < headers.length; i++) {
                                if (!headers[i]) {
                                    headers[i] = "";
                                }
                            }
                        } else {
                            headers = [];
                        }
                        result[sheetName].header = headers;
                    }
                    
                    if (roa.length && roa.length > 0) {
                        // init template structure
                        if (!sheetDef.mappings || sheetDef.mappings.length === 0 || isChanged) {
                            if (!sheetDef.mappings) {
                                sheetDef.mappings = [];
                            }
                            if (!sheetDef.references) {
                                sheetDef.references = {};
                            }
                            for (let i = 0; i < headers.length; i++) {
                                let headerDef = sheetDef.mappings[i];
                                if (!headerDef) {
                                    headerDef = {
                                        column_header : "",
                                        column_index : i + 1,
                                        column_index_org : i + 1
                                    };
                                    if (!sheetDef.mappings[i]) {
                                        sheetDef.mappings[i] = headerDef;
                                    }
                                }
                                if (!headerDef.column_index_org) {
                                    updateRawData(roa, sheetDef, headerDef);
                                    continue;
                                }
                                if (headers[i]) {
                                    headerDef.column_header = headers[i].trim();
                                }
                                if (!headerDef.unit || headerDef.unit_error || !headerDef.icasa) {
                                    if (sheetDef.unit_row) {
                                        headerDef.unit = roa[sheetDef.unit_row - 1][i];
                                    } else {
                                        delete headerDef.unit;
                                    }
                                }
                                if (!headerDef.description && sheetDef.desc_row) {
                                    headerDef.description = roa[sheetDef.desc_row - 1][i];
                                }
                                if (!headerDef.icasa) {
                                    let headerName = String(headerDef.column_header).toUpperCase();
                                    if (icasaVarMap.getDefinition(headerName)) {
                                        headerDef.icasa = headerName;
                                    } else if (icasaVarMap.getDefinition(headerDef.column_header)) {
                                        headerDef.icasa = headerDef.column_header;
                                    }
                                }
                                if (headerDef.icasa && primaryVarExisted[headerDef.icasa] !== undefined) {
                                    primaryVarExisted[headerDef.icasa] = true;
                                }
                                let icasa_unit = icasaVarMap.getUnit(headerDef.icasa);
                                if (!headerDef.icasa) {
                                    continue;
                                } else if (!headerDef.unit) {
                                    headerDef.unit_error = true;
                                } else if (icasa_unit && headerDef.unit !== icasa_unit) {
                                    $.get("/data/unit/convert?value_from=2&unit_to=" + encodeURIComponent(icasa_unit) + "&unit_from="+ encodeURIComponent(headerDef.unit),
                                        function (jsonStr) {
                                            let ret = JSON.parse(jsonStr);
                                            if (ret.status !== "0") {
//                                                headerDef.unit = icasa_unit; // TODO this should change to give warning message
                                                headerDef.unit_error = true;
                                            }
                                        }
                                    );
                                } else if (!icasa_unit) {
                                    $.get("/data/unit/lookup?unit=" + encodeURIComponent(headerDef.unit),
                                        function (jsonStr) {
                                            let unitInfo = JSON.parse(jsonStr);
                                            if (unitInfo.message === "undefined unit expression" && isNumericUnit(headerDef.unit)) {
                                                headerDef.unit_error = true;
                                            }
                                        }
                                    );
                                }
                            }
                            for (let i in roa) {
                                while (sheetDef.mappings.length < roa[i].length) {
                                    sheetDef.mappings.push({column_index : sheetDef.mappings.length + 1, column_index_org : sheetDef.mappings.length + 1});
                                }
                            }
                        } else {
                            // check if header is matched with given spreadsheet
                            let tmpMappings = [];
                            let orgColIdxMap = {};
                            let matchedMap = {};
                            let isFullyMatched = true;
                            for (let i = 0; i < headers.length; i++) {
                                // use index to locate the mapping by default
                                let headerDef = sheetDef.mappings[i];
                                // if header is not matched, the search other mappings
                                if (!headerDef || matchedMap[i] || !headerDef.column_index_org || headerDef.column_header !== headers[i]) {
                                    for (let j in sheetDef.mappings) {
                                        if (!matchedMap[j] && sheetDef.mappings[j].column_index_org && sheetDef.mappings[j].column_header === headers[i]) {
                                            headerDef = sheetDef.mappings[j];
                                            headerDef.column_index = i + 1;
                                            orgColIdxMap[headerDef.column_index_org] = i + 1;
                                            headerDef.column_index_org = i + 1;
                                            matchedMap[j] = true;
                                            isFullyMatched = false;
                                            break;
                                        }
                                    }
                                } else {
                                    headerDef.column_index = i + 1;
                                    orgColIdxMap[headerDef.column_index_org] = i + 1;
                                    headerDef.column_index_org = i + 1;
                                    matchedMap[i] = true;
                                }
                                // if not find matched mapping, then use the mapping by index or create new if unavalible
                                if (!headerDef || !headerDef.column_index_org) {
                                    headerDef = {
                                        column_header : "",
                                        column_index : i + 1,
                                        column_index_org : i + 1,
                                        ignored_flg : true
                                    };
                                    if (headers[i]) {
                                        headerDef.column_header = headers[i].trim();
                                    }
                                    orgColIdxMap[i + 1] = i + 1;
                                    isFullyMatched = false;
                                } else if (headerDef.column_header !== headers[i]) {
                                    // temporarily match by index
                                    headerDef = {index_matched : true};
                                }
                                tmpMappings[i] = headerDef;
                            }

                            // match by index
                            for (let i in tmpMappings) {
                                i = Number(i);
                                if (tmpMappings[i].index_matched) {
                                    if (!matchedMap[i]) {
                                        tmpMappings[i] = sheetDef.mappings[i];
                                        if (headers[i]) {
                                            tmpMappings[i].column_header = headers[i].trim();
                                        }
                                        tmpMappings[i].column_index = i + 1;
                                        orgColIdxMap[tmpMappings[i].column_index_org] = tmpMappings[i].column_index;
                                        tmpMappings[i].column_index_org = tmpMappings[i].column_index;
                                        matchedMap[i] = true;
                                    } else {
                                        tmpMappings[i] = {
                                            column_header : "",
                                            column_index : i + 1,
                                            column_index_org : i + 1,
                                            ignored_flg : true
                                        };
                                        if (headers[i]) {
                                            tmpMappings[i].column_header = headers[i].trim();
                                        }
                                        if (!orgColIdxMap[i + 1]) {
                                            orgColIdxMap[i + 1] = i + 1;
                                        }
                                        isFullyMatched = false;
                                    }
                                }
                            }

                            // Add virtual column from definition
                            for (let i in sheetDef.mappings) {
                                i = Number(i);
                                if (!sheetDef.mappings[i].column_index_org) {
                                    // update index for virtual columns
                                    if (!isFullyMatched && sheetDef.mappings[i].virtual_val_keys) {
                                        for (let j = sheetDef.mappings[i].virtual_val_keys.length - 1; j > - 1; j--) {
                                            let orgRefIdx = orgColIdxMap[sheetDef.mappings[i].virtual_val_keys[j]];
                                            if (orgRefIdx) {
                                                orgColIdxMap
                                                sheetDef.mappings[i].virtual_val_keys[j] = orgColIdxMap[sheetDef.mappings[i].virtual_val_keys[j]];
                                            } else {
                                                sheetDef.mappings[i].virtual_val_keys.splice(j, 1);
                                            }
                                        }
                                        if (sheetDef.mappings[i].virtual_val_keys.length === 0) {
                                            continue;
                                        }
                                    }
                                    if (i < tmpMappings.length) {
                                        tmpMappings.splice(i, 0, sheetDef.mappings[i]);
                                        sheetDef.mappings[i].column_index = i + 1;
                                        for (let j = i + 1; j < tmpMappings.length; j ++) {
                                            tmpMappings[j].column_index++;
                                        }
                                    } else {
                                        tmpMappings.push(sheetDef.mappings[i]);
                                        sheetDef.mappings[i].column_index = tmpMappings.length;
                                    }
                                } else {
                                    
                                }
                            }

                            sheetDef.mappings = tmpMappings;
                            for (let i in sheetDef.mappings) {
                                let mapping = sheetDef.mappings[i];
                                if (!mapping.column_index_org) {
//                                    shiftRefFromKeyIdx(sheetDef, i);
                                    shiftRawData(roa, i);
                                }
                            }
                            for (let i in sheetDef.mappings) {
                                let mapping = sheetDef.mappings[i];
                                if (!mapping.column_index_org) {
                                    updateRawData(roa, sheetDef, mapping);
                                }
                            }
                            if (sheetDef.header_row) {
                                headers = roa[sheetDef.header_row - 1];
                            } else {
                                headers = [];
                            }
                            result[sheetName].header = headers;
                            
                            // fill missing column definition with ignored flag
                            let vrColCnt = 0;
                            for (let i = 0; i < headers.length; i++) {
                                let headerDef = sheetDef.mappings[i];
                                if(!headerDef) {
                                    headerDef = {
                                        column_header : "",
                                        column_index : i + 1,
                                        column_index_org : i + 1 - vrColCnt,
                                        ignored_flg : true
                                    }
                                    sheetDef.mappings[i] = headerDef;
                                    if (headers[i]) {
                                        headerDef.column_header = headers[i].trim();
                                    }
                                    // Load existing template definition
                                    if (sheetDef.unit_row) {
                                        headerDef.unit = roa[sheetDef.unit_row - 1][i];
                                    }
                                    if (sheetDef.desc_row) {
                                        headerDef.description = roa[sheetDef.desc_row - 1][i];
                                    }
                                    let headerName = String(headerDef.column_header).toUpperCase();
                                    if (icasaVarMap.getDefinition(headerName)) {
                                        headerDef.icasa = headerName;
                                    } else if (icasaVarMap.getDefinition(headerDef.column_header)) {
                                        headerDef.icasa = headerDef.column_header;
                                    }
                                } else {
                                    if (!headerDef.column_index_org) {
                                        vrColCnt++;
                                    }
                                    if (sheetDef.mappings[i].column_header !== headers[i]) {
                                        sheetDef.mappings[i].column_header = headers[i].trim();
                                        // TODO deal with sc2 mappings is not fully matched with given spreadsheet columns
                                    }
                                }
                                if (headerDef.icasa) {
                                    let icasa_unit = icasaVarMap.getUnit(headerDef.icasa);
                                    if (!headerDef.unit) {
                                        headerDef.unit_error = true;
                                    } else if (icasa_unit && headerDef.unit !== icasa_unit) {
                                        $.get("/data/unit/convert?value_from=1&unit_to=" + encodeURIComponent(icasa_unit) + "&unit_from="+ encodeURIComponent(headerDef.unit),
                                            function (jsonStr) {
                                                let ret = JSON.parse(jsonStr);
                                                if (ret.status !== "0") {
//                                                    headerDef.unit = icasa_unit; // TODO this should change to give warning message
                                                    headerDef.unit_error = true;
                                                } else {
                                                    delete headerDef.unit_error;
                                                }
                                            }
                                        );
                                    } else if (!icasa_unit) {
                                        $.get("/data/unit/lookup?unit=" + encodeURIComponent(headerDef.unit),
                                            function (jsonStr) {
                                                let unitInfo = JSON.parse(jsonStr);
                                                if (unitInfo.message === "undefined unit expression" && isNumericUnit(headerDef.unit)) {
                                                    headerDef.unit_error = true;
                                                } else {
                                                    delete headerDef.unit_error;
                                                }
                                            }
                                        );
                                    } else {
                                         delete headerDef.unit_error;
                                    }
                                }
                            }
                            if (!isFullyMatched) {
                                sheetDef.unfully_matched_flg = true;
                            }
                        }
                    }
                });
                return result;
            }
            
            function to_csv(workbooks) {
                let result = [];
                for (let name in workbooks) {
                    result.push("File: " + name);
                    result.push("");
                    let workbook = workbooks[name];
                    workbook.SheetNames.forEach(function(sheetName) {
                        let csv = XLSX.utils.sheet_to_csv(workbook.Sheets[sheetName], {raw: false, dateNF: "yyyy-MM-dd"});
                        if(csv.length){
                            result.push("SHEET: " + sheetName);
                            result.push("");
                            result.push(csv);
                        }
                    });
                }
                return result.join("\n");
            }
            
            function setSpreadsheet(target) {
//                $("#sheet_name_selected").text(" <" + target.id + ">");
                let tmp = target.id.split("__");
                curFileName = tmp[0];
                curSheetName = tmp[1];
                $("#sheet_name_selected").text(" <" + curSheetName + ">");
            }

            function getColumnDef(mapping) {
                if (mapping.unit === "date") {
                    return {type: 'date', readOnly: true};
                } else if (mapping.unit === "text" || mapping.unit === "code") {
                    return {type: 'text', readOnly: true};
                } else if (mapping.unit !== ""){
                    return {type: 'numeric', readOnly: true};
                } else {
                    return {type: 'text', readOnly: true};
                }
            }
            
            function initSpreadsheet(fileName, sheetName, spsContainer) {
                if (!spsContainer) {
                    spsContainer = document.querySelector('#sheet_spreadsheet_content');
                }
//                let minRows = 10;
                let data = wbObj[fileName][sheetName].data;
                let sheetDef = templates[fileName][sheetName];
//               let mappings = getMappings(fileName, sheetName);
                let mappings = sheetDef.mappings;
                let columns = [];
//                if (data.length < minRows) {
//                    data = JSON.parse(JSON.stringify(data)); // TODO set raw data as read only for a temprory solution
//                }
                for (let i in mappings) {
                    columns.push(getColumnDef(mappings[i]));
                }
                for (let i in data) {
                    while (columns.length < data[i].length) {
                        columns.push({type: 'text', readOnly: true});
                    }
                }

                let spsOptions = {
                    licenseKey: 'non-commercial-and-evaluation',
                    data: data,
                    columns: columns,
                    stretchH: 'all',
                    width: '100%',
                    autoWrapRow: true,
                    height: $(window).height() - $("body").height() + $("#sheet_spreadsheet_content").height(),
//                    minRows: minRows,
                    maxRows: 365 * 30,
                    manualRowResize: true,
                    manualColumnResize: true,
                    rowHeaders: function (row) {
                        let txt;
                        let idx = row + 1;
                        if (!$('#tableViewSwitch').prop("checked")) {
                            txt = sheetDef.data_start_row + row;
                        } else if (row === sheetDef.header_row - 1) {
                            txt = "<span data-toggle='tooltip' title='Header (Varible Code Name)'><Strong>Var</Strong> " + idx + "</span>";
                        } else if (row === sheetDef.unit_row - 1) {
                            txt = "<span data-toggle='tooltip' title='Unit Expression'><Strong>Unit</Strong> " + idx + "</span>";
                        } else if (row === sheetDef.desc_row - 1) {
                            txt = "<span data-toggle='tooltip' title='Description/Definition'><Strong>Desc</Strong> " + idx + "</span>";
                        } else if (!sheetDef.data_start_row) {
                            txt = idx;
                        } else if (row < sheetDef.data_start_row - 1) {
                            txt = "<span data-toggle='tooltip' title='Comment/Ignored raw'><em>C</em> " + idx + "</span>";;
                        } else {
//                            txt = row - sheetDef.data_start_row + 2;
                            txt = idx;
                        }
                        return txt;
                    },
                    colHeaders: function (col) {
                        let checkBox = '<input type="checkbox" name="' + fileName + "_" + sheetName + '_' + col + '"';
                        if (mappings[col] && mappings[col].ignored_flg) {
                            checkBox += 'onchange=toggleIgnoreColumn(' + col + ');> ';
                        } else {
                            checkBox += 'checked onchange=toggleIgnoreColumn(' + col + ');> ';
                        }
                        let title = getColHeaderComp(mappings, col, fileName + "_" + sheetName + '_' + col + "_label").prop('outerHTML');
                        return "<h4>" + checkBox + title + "</h4>";
                    },
//                    headerTooltips: true,
//                    afterChange: function(changes, src) {
//                        if(changes){
//                            
//                        }
//                    },
                    manualRowMove: false,
                    manualColumnMove: false,
                    filters: true,
                    dropdownMenu: true,
                    contextMenu: {
                        items: {
                            "define_column":{
                                name: '<span class="glyphicon glyphicon-edit"></span> Define Column',
                                disabled: function () {
                                    // disable the option when the multiple columns were selected
                                    let range = this.getSelectedLast();
                                    let selection = this.getSelected();
                                    return range[1] !== range[3] || selection.length !== 1;
                                },
                                callback: function(key, selection, clickEvent) {
                                    setTimeout(function() {
                                        let colIdx = selection[0].start.col;
//                                        data.column_header = spreadsheet.getColHeader(data.colIdx);
                                        let colDef = mappings[colIdx];
                                        let itemData = JSON.parse(JSON.stringify(colDef));
                                        showColDefineDialog(itemData);
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            },
                            "ignore_column":{
                                name: '<span class="glyphicon glyphicon-ban-circle"></span> Ignore Column',
                                hidden: function () { // `hidden` can be a boolean or a function
                                    // Hide the option when it is ignored
                                    let selection = this.getSelected();
                                    for (let i in selection) {
                                        let start = Math.min(selection[i][1], selection[i][3]);
                                        let end = Math.max(selection[i][1], selection[i][3]);
                                        for (let j = start; j <= end; j++) {
                                            if ($("[name='" + fileName + "_" + sheetName + "_" + j + "']").last().prop("checked")) {
                                                return false;
                                            }
                                        }
                                    }
                                    return true;
                                },
                                callback: function(key, selection, clickEvent) {
                                    setTimeout(function() {
                                        for (let i in selection) {
                                            for (let j = selection[i].start.col; j <= selection[i].end.col; j++) {
                                                let cb = $("[name='" + fileName + "_" + sheetName + "_" + j + "']").last();
                                                cb.prop("checked", false).trigger("change");
                                            }
                                        }
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            },
                            "include_column":{
                                name: '<span class="glyphicon glyphicon-ok-circle"></span> Include Column',
                                hidden: function () { // `hidden` can be a boolean or a function
                                    // Hide the option when it is ignored
                                    let selection = this.getSelected();
                                    for (let i in selection) {
                                        let start = Math.min(selection[i][1], selection[i][3]);
                                        let end = Math.max(selection[i][1], selection[i][3]);
                                        for (let j = start; j <= end; j++) {
                                            if (!$("[name='" + fileName + "_" + sheetName + "_" + j + "']").last().prop("checked")) {
                                                return false;
                                            }
                                        }
                                    }
                                    return true;
                                },
                                callback: function(key, selection, clickEvent) {
                                    setTimeout(function() {
                                        for (let i in selection) {
                                            for (let j = selection[i].start.col; j <= selection[i].end.col; j++) {
                                                let cb = $("[name='" + fileName + "_" + sheetName + "_" + j + "']").last();
                                                cb.prop("checked", true).trigger("change");
                                            }
                                        }
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            },
                            "new_column":{
                                name: '<span class="glyphicon glyphicon-plus-sign"></span> Add Column',
//                                hidden: function () { // `hidden` can be a boolean or a function
//                                    // Hide the option when the first column was clicked
////                                    return this.getSelectedLast()[1] == 0; // `this` === hot3
//                                    return true;
//                                },
                                callback: function(key, selection, clickEvent) {
                                    setTimeout(function() {
                                        let itemData = {
                                            column_index_prev : selection[0].start.col
                                        };
                                        showColDefineDialog(itemData);
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            },
                            "remove_column":{
                                name: '<span class="glyphicon glyphicon-minus-sign"></span> Remove Column',
                                hidden: function () { // `hidden` can be a boolean or a function
                                    let selection = this.getSelected();
                                    for (let i in selection) {
                                        let start = Math.min(selection[i][1], selection[i][3]);
                                        let end = Math.max(selection[i][1], selection[i][3]);
                                        for (let j = start; j <= end; j++) {
                                            if (!mappings[j].column_index_org) {
                                                return false;
                                            }
                                        }
                                    }
                                    return true;
                                },
                                callback: function(key, selection, clickEvent) {
                                    setTimeout(function() {
                                        let columns = spreadsheet.getSettings().columns;
                                        selection.sort(function (s1, s2) {
                                            return s2.start.col - s1.start.col;
                                        });
                                        for (let i in selection) {
                                            let first = Math.min(selection[i].start.col, selection[i].end.col);
                                            let last = Math.max(selection[i].start.col, selection[i].end.col);
                                            for (let j = last; j >= first; j--) {
                                                if (!mappings[j].column_index_org) {
                                                    // remove mapping
                                                    for (let k = j + 1; k < mappings.length; k++) {
                                                        mappings[k].column_index--;
                                                    }
                                                    mappings.splice(j, 1);
                                                    // Shift references index
                                                    shiftRefFromKeyIdx(sheetDef, j, -1);
                                                    // remove data
                                                    for (let k in data) {
                                                        data[k].splice(j, 1);
                                                    }
                                                    // remove column def
                                                    columns.splice(j, 1);
                                                    // reduce virtual column count
                                                    virColCnt[fileName][sheetName]--;
                                                }
                                            }
                                        }
                                        spreadsheet.updateSettings({
                                            columns : columns
                                        });
//                                        console.log(virColCnt);
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            },
                            "edit_row":{
                                name: '<span class="glyphicon glyphicon-edit"></span> Edit Row Definition',
                                callback: function(key, selection, clickEvent) {
                                    setTimeout(function() {
                                        showSheetDefDialog(processData, null, true);
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            },
                            "apply_same_unit" : {
                                name : '<span class="glyphicon glyphicon-check"></span> Apply ICASA Unit',
                                hidden: function () { // `hidden` can be a boolean or a function
                                    // Hide the option when it is ignored
                                    let selection = this.getSelected();
                                    for (let i in selection) {
                                        let start = Math.min(selection[i][1], selection[i][3]);
                                        let end = Math.max(selection[i][1], selection[i][3]);
                                        for (let j = start; j <= end; j++) {
                                            if (mappings[j].unit_error) {
                                                return false;
                                            }
                                        }
                                    }
                                    return true;
                                },
                                callback : function(key, selection, clickEvent) {
                                    setTimeout(function() {
//                                        let mappings = templates[fileName][sheetName].mappings;
                                        for (let i in selection) {
                                            for (let j = selection[i].start.col; j <= selection[i].end.col; j++) {
                                                if (mappings[j].unit_error) {
                                                    let icasaUnit = icasaVarMap.getUnit(mappings[j].icasa);
                                                    if (icasaUnit) {
                                                        mappings[j].unit = icasaUnit;
                                                        delete mappings[j].unit_error;
                                                        if (!mappings[j].description) {
                                                            mappings[j].description = icasaVarMap.getDesc(mappings[j].icasa);
                                                        }
                                                        let newHeader = getColHeaderComp(mappings, j);
                                                        let header = $("[name='" + fileName + "_" + sheetName + "_" + j + "_label']").last();
                                                        header.attr("class", newHeader.attr("class"));
                                                        header.html(newHeader.html());
                                                        isChanged = true;
                                                        isViewUpdated = false;
                                                        isDebugViewUpdated = false;
                                                    }
                                                }
                                            }
                                        }
                                    }, 0); // Fire alert after menu close (with timeout)
                                }
                            }
//                            "sep2": '---------',
//                            "row_above": {},
//                            "row_below": {},
//                            "remove_row": {},
//                            "sep1": '---------',
//                            "undo": {},
//                            "redo": {},
//                            "cut": {},
//                            "copy": {},
//                            "clear":{
//                                name : "clear",
//                                callback: function(key, selection, clickEvent) { // Callback for specific option
//                                    setTimeout(function() {
//                                        alertBox('Hello world!'); // Fire alert after menu close (with timeout)
//                                    }, 0);
//                                }}
                        }
                    }
                };
                if (!$('#tableViewSwitch').prop("checked")) {
                    spsOptions.data = getSheetDataContent(spsOptions.data, sheetDef);
//                    spsOptions.rowHeaders = true;
                }
                if (spreadsheet) {
                    spreadsheet.destroy();
                }
                spreadsheet = new Handsontable(spsContainer, spsOptions);
                if ($('#tableViewSwitch').prop("checked")) {
                    spreadsheet.updateSettings({
                        cells: function(row, col, prop) {
                            let cell = spreadsheet.getCell(row,col);
                            if (!cell) {
                                return;
                            }
                            if (row === sheetDef.header_row - 1) {
    //                            cell.style.color = "white";
    //                            cell.style.fontWeight = "bold";
                                cell.style.fontStyle = "italic";
                                cell.style.backgroundColor = "lightgrey";
                                return {readOnly : true};
                            } else if (row === sheetDef.unit_row - 1) {
    //                            cell.style.color = "white";
    //                            cell.style.textDecoration = "underline";
                                cell.style.fontStyle = "italic";
                                cell.style.backgroundColor = "lightgrey";
                                return {readOnly : true};
                            } else if (row === sheetDef.desc_row - 1) {
    //                            cell.style.color = "white";
                                cell.style.fontStyle = "italic";
                                cell.style.backgroundColor = "lightgrey";
                                return {readOnly : true};
                            } else if (row < sheetDef.data_start_row - 1) {
    //                            cell.style.color = "white";
                                cell.style.backgroundColor = "lightgrey";
                                return {readOnly : true};
                            }
                        },
                    });
                }
                $('.table_switch_cb').bootstrapToggle('enable');
                if (!sheetDef.data_start_row) {
                    $('#tableViewSwitch').bootstrapToggle('disable');
                }
            }

            function getColHeaderComp(mappings, col,  name) {
                let mapping = mappings[col];
                let title = $("<span></span>");
                if (!name) {
                    name = curFileName + "_" + curSheetName + "_" + col + "_label";
                }
                title.attr("name", name);

                let refMark = "";
                if (mapping && mapping.reference_flg) {
                    refMark = "<span class='glyphicon glyphicon-flag'></span> ";
                }
//                let colIdx = " <span class='badge'>" + (col + 1) + "</span>";
                let colIdx = col + 1;
                
                let text;
                let classes = getColStatusClass(col, mappings);
                let tooltip;
                if (mapping && mapping.ignored_flg) {
                    text = refMark + "[" + colIdx + "] " + mapping.column_header;
                } else if (!mapping || (!mapping.column_header && !mapping.icasa)) {
                    text = refMark + colIdx;
//                } else if (!mapping.icasa) {
//                    text = refMark + mapping.column_header + "[" + colIdx + "]";
                } else if (mapping.icasa) {
                    let varDef = icasaVarMap.getDefinition(mapping.icasa);
                    text = refMark + "[" + colIdx + "] ";
                    if (mapping.column_header && mapping.icasa.toLowerCase() !== mapping.column_header.toLowerCase()) {
                       text += "<em>" +  mapping.column_header + "->" + mapping.icasa + "</em> ";
                    } else if (mapping.column_header) {
                        text += mapping.column_header;
                    } else {
                        text += "<em>" +  mapping.icasa + "</em> ";
                    }
                    if (varDef) {
                        tooltip = "<" + mapping.icasa + "> " + varDef.description + " [" + varDef.unit_or_type + "]";
                        if (!mapping.unit) {
                            text += "<br/><em>?->" + varDef.unit_or_type + "</em>"
                        } else if (mapping.unit.toLowerCase() !== varDef.unit_or_type.toLowerCase()) {
                            text += "<br/><em>" + mapping.unit + "->" + varDef.unit_or_type + "</em>"
                        } else {
//                            text += " [" + varDef.unit_or_type + "]'>";
                        }

                    } else {
                        tooltip ="<" + mapping.icasa + "> " + mapping.description + " [" + mapping.unit + "]";
                    }
                } else if (mapping.reference_flg) {
                    text = refMark + "[" + colIdx + "] " + mapping.column_header;
                } else {
                    text = refMark + "[" + colIdx + "] " + mapping.column_header;
                }
                title.prop("class", classes);
                if (tooltip) {
                    title.attr("data-toggle", "tooltip");
                    title.prop("title", tooltip);
                }
                title.html(text);
                return title;
            }

            function toggleIgnoreColumn(colIdx) {
                let key = curFileName + "_" + curSheetName + "_" + colIdx;
                let headerCB = $("[name='" + key + "']").last();
                let header = $("[name='" + key + "_label']").last();
                let mapping = templates[curFileName][curSheetName].mappings[colIdx];
                if (headerCB.prop("checked")) {
                    delete mapping.ignored_flg;
//                    header.html("class", getColStatusClass(colIdx));
                } else {
                    mapping.ignored_flg = true;
//                    header.attr("class", "label label-default");
                }
                let newHeader = getColHeaderComp(templates[curFileName][curSheetName].mappings, colIdx);
                header.attr("class", newHeader.attr("class"));
                header.html(newHeader.html());
                isChanged = true;
                isViewUpdated = false;
                isDebugViewUpdated = false;
            }
            
            function getColStatusClass(col, mappings) {
                if (!mappings) {
                    mappings = templates[curFileName][curSheetName].mappings;
                }
                if (mappings[col]) {
                     if (mappings[col].ignored_flg) {
                        return "label label-default";
                    } else if (mappings[col].unit_error) {
                        return "label label-danger";
                    } else if (!mappings[col].column_index_org) {
                        return "label label-primary";
                    } else if (mappings[col].icasa) {
                        if (icasaVarMap.getDefinition(mappings[col].icasa)) {
                            return "label label-success";
                        } else {
                            return "label label-info";
                        }
                    } if (mappings[col].reference_flg) {
                        return "label label-info";
                    }
                }
                return "label label-warning";
            }
            
            function convertUnit() {
                // TODO
            }
            
            function openExpDataFile() {
                showLoadFileDialog();
            }
            
            function openExpDataFolderFile() {
                alertBox("Functionality under construction...");
            }
            
            function saveExpDataFile() {
                alertBox("Functionality under construction...");
            }
            
            function saveAcebFile() {
                alertBox("Functionality under construction...");
            }

            function saveAgMIPZip() {
                // check if mappings are completed
                for (let fileName in templates) {
                    for (let sheetName in templates[fileName]) {
                        let cntUndefined = countUndefinedColumns(templates[fileName][sheetName]);
                        if (cntUndefined > 0) {
                            alertBox("There are undefined/error mappings left here...", function () {
                                $('#sheet_tab_list').find("a").each(function () {
                                    if ($(this).attr('id') === fileName + '__' + sheetName) {
                                        $(this).click();
                                        return false;
                                    }
                                 });
                            });
                            return;
                        }
                    }
                }
                let loadingDialog = bootbox.dialog({
                    message: '<h4><span class="glyphicon glyphicon-refresh spinning"></span><span class="loading-msg"> Preparing files...</span></h4>',
//                    centerVertical: true,
                    closeButton: false
                });
                loadingDialog.on("shown.bs.modal", function() {
                    // check the relationship among tables and determine the data structure
                    let rootTables = {};
                    let toRefs = [];
                    for (let fileName in templates) {
                        for (let sheetName in templates[fileName]) {
                            if (!rootTables[fileName]) {
                                rootTables[fileName] = {};
                            }
                            rootTables[fileName][sheetName] = true;
                            if (Object.keys(templates[fileName][sheetName].references).length > 0) {
                                toRefs.push(templates[fileName][sheetName].references);
                            }
                        }
                    }
                    // mark all the tables which has been related as non-root tables
                    for (let i in toRefs) {
                        for (let fromKeyIdx in toRefs[i]) {
                            for (let toKeyIdx in toRefs[i][fromKeyIdx]) {
                                let refDef = toRefs[i][fromKeyIdx][toKeyIdx];
                                let tableCat = getTableCategory(templates[refDef.file][refDef.sheet].mappings);
                                if ((tableCat.order < 4000 || tableCat.order > 4051) &&
                                    (tableCat.order < 5000 || tableCat.order > 5051)) {
                                    // If reference target is not soil/weather meta/profile table, then mark it as non-root table
                                    rootTables[refDef.file][refDef.sheet] = false;
                                }
                            }
                        }
                    }
                    // loop the root tables to create csv file for each related group of tables
                    let zip = new JSZip();
                    let fileMap = {};
                    for (let fileName in rootTables) {
                        for (let sheetName in rootTables[fileName]) {
                            if (rootTables[fileName][sheetName] && templates[fileName][sheetName]) {
                                let csvData = createCsvSheet(fileName, sheetName);
                                let cnt = 1;
                                let csvFileName = sheetName;
                                while (fileMap[csvFileName]) {
                                    csvFileName = sheetName + "_" + cnt;
                                }
                                fileMap[csvFileName] = true;
                                zip.file(csvFileName + ".csv", csvData);
                            }
                        }
                    }
                    zip.generateAsync({type:"blob"}).then(function(content) {
                        loadingDialog.modal('hide');
                        saveAs(content, "AgMIP_Input.zip");
                    });
                });
            }
            
            function createCsvSheet(fileName, sheetName) {
                let wb = XLSX.utils.book_new();
                let ws = XLSX.utils.aoa_to_sheet(createCsvSheetArr(fileName, sheetName) );
                XLSX.utils.book_append_sheet(wb, ws, sheetName.substring(0, 31));
                return XLSX.write(wb, {bookType:"csv", type: 'string'});
            }

            function createCsvSheetArr(fileName, sheetName, parentIdxInfo) {
                let agmipData = JSON.parse(JSON.stringify(wbObj[fileName][sheetName].data));
                let sheetDef = templates[fileName][sheetName];
                agmipData = getSheetDataContent(agmipData, sheetDef);
                if (wbObj[fileName][sheetName].headers) {
                    agmipData.unshift(JSON.parse(JSON.stringify(wbObj[fileName][sheetName].headers)));
                } else {
                    agmipData.unshift([""]);
                }
                
                let headerRow = agmipData.length;
                agmipData.unshift(["!", sheetName]);
                agmipData.unshift(["!", fileName]);
                headerRow = agmipData.length - headerRow;
                if (isArrayData(sheetDef.mappings)) {
                    agmipData[headerRow].unshift("%");
                } else {
                    agmipData[headerRow].unshift("#");
                }
                if (parentIdxInfo) {
                    if (parentIdxInfo.refDef.keys.length === 0) {
                        // create sub data table for meta case
                        if (agmipData.length > headerRow + 1) {
                            let curIdx = headerRow + 1;
                            // create spot for indexing
                            for (let j = curIdx; j < agmipData.length; j++) {
                                agmipData[j].unshift("!");
                            }
                            for (let idx in parentIdxInfo.indexing) {
                                if (agmipData[curIdx][0] !== "!") {
                                    // duplicate it self for meta table reference
                                    let curLength = agmipData.length;
                                    for (let j = curIdx; j < curLength; j++, curIdx++) {
                                        agmipData.push(JSON.parse(JSON.stringify(agmipData[j])));
                                    }
                                }
                                // fill indexing for each source record
                                for (let j = curIdx; j < agmipData.length; j++) {
                                    agmipData[j][0] = idx;
                                }
                            }
                        }
                    } else {
                        // create sub data table for regular case
                        agmipDataCache = agmipData.splice(headerRow + 1);
                        for (let i in agmipDataCache) {
                            agmipDataCache[i].unshift("!");
                        }
                        let metaNum = Object.keys(parentIdxInfo.indexing).length;
                        for (let idx in parentIdxInfo.indexing) {
                            for (let i in agmipDataCache) {
                                let found = true;
                                for (let toKey in parentIdxInfo.indexing[idx]) {
                                    if (agmipDataCache[i][toKey] != parentIdxInfo.indexing[idx][toKey]) {
                                        found = false;
                                        break;
                                    }
                                }
                                if (found) {
                                    agmipDataCache[i][0] = idx;
                                    agmipData.push(JSON.parse(JSON.stringify(agmipDataCache[i])));
                                }
                            }
                        }
                    }
                } else {
                    // create primary table index
                    for (let j in agmipData) {
                        j = Number(j);
                        if ( j <= headerRow) {
                            continue;
                        }
                        agmipData[j].unshift(j - headerRow);
                    }
                }

                if (agmipData.length > headerRow + 1) {
                    let evtInputConfig = {};
                    for (let i = sheetDef.mappings.length - 1; i > -1; i--) {
                        let mapping = sheetDef.mappings[i];
                        if (!mapping) {
                            continue;
                        }
                        if (mapping.icasa) {
                            if (mapping.icasa.toUpperCase() === "MGMT_EVENT") {
                                evtInputConfig.mgmt_event_index = i + 1;
                            } else if (mapping.icasa.toUpperCase() === "EVDATE") {
                                evtInputConfig.evdate_index = i + 1;
                            }
                        }
                        if (mapping.ignored_flg) {
                            if (mapping.icasa) {
                                agmipData[headerRow][mapping.column_index] = "!" + mapping.icasa;
                            } else if (mapping.column_header) {
                                agmipData[headerRow][mapping.column_index] = "!" + mapping.column_header;
                            } else {
                                agmipData[headerRow][mapping.column_index] = "!" + agmipData[headerRow][mapping.column_index];
                            }
                        } else if (mapping.icasa) {
                            agmipData[headerRow][mapping.column_index] = mapping.icasa;
                            let icasaUnit = icasaVarMap.getUnit(mapping.icasa);
                            if (mapping.unit) {
                                // Code/unit/value convertion
                                if (mapping.unit === "date") {
                                    if (mapping.format) {
                                        if (mapping.format === "yyyyDDD") {
                                            for (let j in agmipData) {
                                                if (j > headerRow) {
                                                    agmipData[j][mapping.column_index] = dateUtil.toYYYYMMDDStr(agmipData[j][mapping.column_index]);
                                                }
                                            }
                                        } else {
                                            // TODO support customized date format
                                        }
                                    }
                                } else if (mapping.unit === "code") {
                                    if (mapping.code_mappings) {
                                        for (let j in agmipData) {
                                            if (j > headerRow && mapping.code_mappings[agmipData[j][mapping.column_index]]) {
                                                agmipData[j][mapping.column_index] = mapping.code_mappings[agmipData[j][mapping.column_index]];
                                            }
                                        }
                                    }
                                } else if (isNumericUnit(mapping.unit) && mapping.unit !== icasaUnit) {
                                    $.ajax({
                                        url:"/data/unit/convert?value_from=1&unit_to=" + encodeURIComponent(icasaUnit) + "&unit_from="+ encodeURIComponent(mapping.unit),
                                        async:false
                                    }).done(function (jsonStr) {
                                        let ret = JSON.parse(jsonStr);
                                        if (ret.status === "0") {
                                            for (let j in agmipData) {
                                                if (j > headerRow && agmipData[j][mapping.column_index] && !Number.isNaN(agmipData[j][mapping.column_index])) {
                                                    agmipData[j][mapping.column_index] *= Number(ret.value_to);
                                                }
                                            }
                                        }
                                    });
                                }
                                // Fill missing data if repeated flag is on
                                if (mapping.formula === "fill_with_previous") {
                                    let nullVal = mapping.null_val;
                                    let lastCell = nullVal;
                                    for (let j in agmipData) {
                                        if (j > headerRow) {
                                            if (lastCell === nullVal) {
                                                lastCell = agmipData[j][mapping.column_index];
                                            } else if (nullVal && agmipData[j][mapping.column_index] === nullVal || agmipData[j][mapping.column_index] === null || agmipData[j][mapping.column_index].trim() === "") {
                                                agmipData[j][mapping.column_index] = lastCell;
                                            } else {
                                                lastCell = agmipData[j][mapping.column_index];
                                            }
                                        }
                                    }
                                }

                            }
                        } else {
                            agmipData[headerRow][mapping.column_index] = mapping.column_header;
                        }
                    }
                    // Adjust event input into AgMIP format
                    if (evtInputConfig.evdate_index !== undefined && evtInputConfig.mgmt_event_index) {
                        let agmipDataTmp = [];
                        
                        for (let j in agmipData) {
                            if (j < headerRow) {
                                agmipDataTmp.push(agmipData[j])
                            } else if (j > headerRow) {
                                let eventInput = [
                                    agmipData[j][0],
                                    "event", 
                                    agmipData[j][evtInputConfig.mgmt_event_index], 
                                    "",
                                    agmipData[j][evtInputConfig.evdate_index]
                                ];
                                eventInput[3] = eventDateMapping.getEventDateVarName(eventInput[2]);
                                agmipDataTmp.push(["#", eventInput[3]]);
                                agmipDataTmp.push(eventInput);
                                for (let i = 0; i < sheetDef.mappings.length; i++) {
                                    let skipFlg = false;
                                    for (let key in evtInputConfig) {
                                        if (i + 1 === evtInputConfig[key]) {
                                            skipFlg = true;
                                            break;
                                        }
                                    }
                                    if (skipFlg) {
                                        continue;
                                    }
                                    eventInput.push(sheetDef.mappings[i].icasa);
                                    eventInput.push(agmipData[j][sheetDef.mappings[i].column_index]);
                                }
                            }
                        }                        
                        agmipData = agmipDataTmp;
                    }
                }
                
                let refDefs = templates[fileName][sheetName].references;
                let subDatas = [];
                for (let fromKeyIdx in refDefs) {
                    for (let toKeyIdx in refDefs[fromKeyIdx]) {
                        let refDef = refDefs[fromKeyIdx][toKeyIdx];
                        let tableCat = getTableCategory(templates[refDef.file][refDef.sheet].mappings);
                        if ((tableCat.order > 4000 && tableCat.order < 4052) ||
                            (tableCat.order > 5000 && tableCat.order < 5052)) {
                            // If it is soil/weather meta/profile table, then skip as sub table.
                            continue;
                        }
                        
                        let idxInfo = {refDef : refDef, indexing : {}};
                        let data = wbObj[fileName][sheetName].data;
                        let fromKeyIdxs = JSON.parse("[" + fromKeyIdx + "]");
                        if (fromKeyIdxs.length === 0) {
                            for (let i in agmipData) {
                                if (i > headerRow) {
                                    idxInfo.indexing[agmipData[i][0]] = {};
                                }
                            }
                        } else {
                            for (let j in fromKeyIdxs) {
                                let mapping = sheetDef.mappings[fromKeyIdxs[j] - 1];
                                let idx;
                                for (let k in refDef.keys) {
                                    if (refDef.keys[k].icasa === mapping.icasa || refDef.keys[k].column_header === mapping.icasa ||
                                        refDef.keys[k].icasa === mapping.column_header || refDef.keys[k].column_header === mapping.column_header) {
                                        idx = refDef.keys[k].column_index;
                                    }
                                }
                                if (!idx) {
                                    if (refDef.keys[j]) {
                                        idx = refDef.keys[j].column_index;
                                    } else {
                                        console.log("[warning] borken reference detected")
                                        continue;
                                    }
                                }
                                for (let i in agmipData) {
                                    if (i <= headerRow) {
                                        continue;
                                    }
                                    if (!idxInfo.indexing[agmipData[i][0]]) {
                                        idxInfo.indexing[agmipData[i][0]] = {};
                                    } else {
                                        // TODO
                                    }
                                    idxInfo.indexing[agmipData[i][0]][idx] = agmipData[i][fromKeyIdxs[j]];
                                }
                            }
                        }
                        subDatas.push(createCsvSheetArr(refDef.file, refDef.sheet, idxInfo));
                    }
                }
                for (let i in subDatas) {
                    agmipData = agmipData.concat(subDatas[i]);
                }
                            
                return agmipData;
            }
            
            function isNumericUnit(unit) {
                return !["text", "code", "date", "number"].includes(unit);
            }
            
            function openTemplateFile() {
                if (Object.keys(workbooks).length === 0) {
                    alertBox("Please load spreadsheet file first, then apply SC2 file for it.");
                } else {
                    $('<input type="file" accept=".sc2.json,.json,.sc2" onchange="readSC2Json(this);" multiple>').click();
                }
            }

            function readSC2Json(target) {
                // reset part of the flags for the case of only loading template
                isChanged = false;
                isViewUpdated = false;
                isDebugViewUpdated = false;
                fileUrls = {};

                let files = target.files;
                let idx = 0;
                let f = files[idx];
                idx++;
                let reader = new FileReader();
                let sc2Objs = [];
                $(".mapping_gengeral_info").val("");
                $("#file_url_inputs").html("");
                reader.onloadend = function (evt) {
                    if (evt.target.readyState === FileReader.DONE) { // DONE == 2
                        let jsonStr = evt.target.result;
//                        readSoilData(jsonStr);
                        
                        sc2Objs.push(JSON.parse(jsonStr));
                        if (idx < files.length) {
                            f = files[idx];
                            idx++;
                            reader.readAsText(f);
                        } else {
                            let sc2Obj = sc2Objs[0];
                            let fileNames = [];
                            if (sc2Obj.agmip_translation_mappings && sc2Obj.agmip_translation_mappings.files) {
                                for (let i in sc2Obj.agmip_translation_mappings.files) {
                                    let fileMeta = sc2Obj.agmip_translation_mappings.files[i].file.file_metadata;
                                    if (fileMeta && getMetaFileName(fileMeta)) {
                                        fileNames.push(getMetaFileName(fileMeta));
                                    }
                                }
                            }
                            for (let i = 1; i < sc2Objs.length; i++) {
                                for (let key in sc2Objs[i]) {
                                    if (sc2Obj[key]) {
                                        if (key === "agmip_translation_mappings") {
                                            for (let key2 in sc2Objs[i][key]) {
                                                if (key2 === "files") {
                                                    for (let j in sc2Objs[i][key].files) {
                                                        let fileObj = sc2Objs[i][key].files[j];
                                                        if (!fileObj.file.file_metadata) {
                                                            fileObj.file.file_metadata = {};
                                                        }
                                                        if (!getMetaFileName(fileObj.file.file_metadata)) {
                                                            saveMetaFileName(fileObj.file.file_metadata, "N/A");
                                                        }
                                                        let cnt = 1;
                                                        let fileName = getMetaFileName(fileObj.file.file_metadata);
                                                        while (fileNames.includes(fileName)) {
                                                            fileName = getMetaFileName(fileObj.file.file_metadata) + "_" + cnt;
                                                            cnt++;
                                                        }
                                                        fileObj.file.file_metadata.file_name = fileName;
                                                        sc2Obj[key].files.push(fileObj);
                                                    }
                                                } else if (key2 === "relations") {
                                                    for (let j in sc2Objs[i][key].relations) {
                                                        sc2Obj[key].relations.push(sc2Objs[i][key].relations[j]);
                                                    }
                                                } else {
                                                    sc2Obj[key][key2] = sc2Objs[i][key][key2];
                                                }
                                            }
                                        } else if (typeof sc2Obj[key] !== "object") {
                                            copyObject(sc2Objs[i][key], sc2Obj[key]);
                                        } else {
                                            sc2Obj[key] = sc2Objs[i][key];
                                        }
                                    } else {
                                        sc2Obj[key] = sc2Objs[i][key];
                                    }
                                }
                            }
                            if (sc2Obj.mapping_info) {
                                for (let key in sc2Obj.mapping_info) {
                                    $("[name='" + key + "']").val(sc2Obj.mapping_info[key]);
                                }
                            }
                            for (let i in sc2Obj.agmip_translation_mappings.files) {
                                let fileMeta = sc2Obj.agmip_translation_mappings.files[i].file.file_metadata;
                                let url = getMetaFileUrl(fileMeta);
                                if (url || url === "") {
                                    fileUrls[getMetaFileName(fileMeta)] = url;
                                }
                            }
                            showSheetDefDialog(loadSC2Obj, null, false, sc2Obj);
                        }
                    }
                };

                reader.readAsText(f);
            }
            
            function copyObject(from, to) {
                if (!from || !to) {
                    return;
                }
                for (let key in from) {
                    if (to[key] && typeof to[key] !== "object") {
                        copyObject(from[key], to[key]);
                    } else {
                        to[key] = from[key];
                    }
                }
            }
            
            function loadSC2Obj (sc2Obj, fileMap) {
                if (sc2Obj.agmip_translation_mappings) {
                    let files = sc2Obj.agmip_translation_mappings.files;
                    let relations = sc2Obj.agmip_translation_mappings.relations;
                    if (!files || files.length === 0) {
                        alertBox("No AgMIP mapping information detected, please try another file!");
                        return;
                    }
                    if (!relations) {
                        relations = [];
                    }
                    // Locate the correct file for reading mappings
                    let fileConfigs = [];
                    if (curFileName) { // TODO couble be removed, need test
                        // If spreadsheet is already loaded, then only pick up the config for the loaded file
                        for (let fileName in wbObj) {
                            for (let i in files) {
                                let fileConfig = files[i];
                                if (fileConfig.file && fileConfig.file.file_metadata
                                        && (fileName === getMetaFileName(fileConfig.file.file_metadata)
                                            || getFileName(fileName) === getFileName(getMetaFileName(fileConfig.file.file_metadata))
                                        )) {
                                    fileConfigs.push(fileConfig);
                                }
                            }
                        }
                        // If not found matched config
                        if (fileConfigs.length === 0) {
                            // TODO then use default first records to apply
                            if (files.length === Object.keys(wbObj).length) {
                                fileConfigs = files;
                            } else {
                                // TODO give warning?
                            }

                        }
                    } else {
                        // Load all the configs
                        fileConfigs = files;
                    }

                    // pre-scan and create file mapping
                    if (fileMap) {
                        templates = {};
                        let newFileConfigs = {};
                        for (let fileName in fileMap) {
                            for (let sheetName in fileMap[fileName]) {
                                let fileDef = fileMap[fileName][sheetName].file_def;
                                let sheetDef = fileMap[fileName][sheetName].sheet_def;
                                // init file block
                                if (!newFileConfigs[fileName]) {
                                    newFileConfigs[fileName] = {file : {
                                        file_metadata : {
                                            file_name : fileName,
                                            "content-type" : fileTypes[fileName]
                                        },
                                        sheets: []
                                    }};
                                    saveMetaFileName(newFileConfigs[fileName].file.file_metadata, fileName, fileUrls[fileName]);
                                }
                                // update sheet mapping
                                let found = false;
                                for (let i in fileConfigs) {
                                    let fileConfig = fileConfigs[i];
                                    if (fileDef === getMetaFileName(fileConfig.file.file_metadata)) {
                                        if (!fileConfig.file.sheets) {
                                            fileConfig.file.sheets = [];
                                        }

                                        for (let j in fileConfig.file.sheets) {
                                            if (sheetDef === fileConfig.file.sheets[j].sheet_name) {
                                                let tmp = JSON.parse(JSON.stringify(fileConfig.file.sheets[j]));
                                                tmp.sheet_name = sheetName;
                                                newFileConfigs[fileName].file.sheets.push(tmp);
                                                found = true;
                                                break;
                                            }
                                        }
                                        if (found) {
                                            break;
                                        }
                                    }
                                }
                                if (!found) {
                                    let tmp = JSON.parse(JSON.stringify(fileMap[fileName][sheetName]));
                                    delete tmp.file_name;
                                    delete tmp.file_def;
                                    delete tmp.sheet_def;
                                    tmp.mappings = [];
                                    newFileConfigs[fileName].file.sheets.push(tmp);
                                }
                                // update reference
                                if (fileDef !== fileName || sheetDef !== sheetName) {
                                    for (let i in relations) {
                                        let relation = relations[i];
                                        if (relation.from.file === fileDef && relation.from.sheet === sheetDef) {
                                            relation.from.file = fileName;
                                            relation.from.sheet = sheetName;
                                        }
                                        if (relation.to.file === fileDef && relation.to.sheet === sheetDef) {
                                            relation.to.file = fileName;
                                            relation.to.sheet = sheetName;
                                        }
                                    }
                                }
                            }
                        }
                        // remove invalid references
                        for (let i = relations.length - 1; i > -1; i--) {
                            let relation = relations[i];
                            if (!relation) {
                                continue;
                            }
                            let foundFrom = false;
                            let foundTo = false;
                            for (let fileName in fileMap) {
                                for (let sheetName in fileMap[fileName]) {
                                    if (!foundFrom && relation.from.file === fileName && relation.from.sheet === sheetName) {
                                        foundFrom = true;
                                    }
                                    if (!foundTo && relation.to.file === fileName && relation.to.sheet === sheetName) {
                                        foundTo = true;
                                    }
                                    if (foundFrom && foundTo) {
                                        break;
                                    }
                                }
                                if (foundFrom && foundTo) {
                                    break;
                                }
                            }
                            if (!foundFrom || !foundTo) {
                                relations.splice(i, 1);
                            }
                        }
                        fileConfigs = newFileConfigs;
                    }

                    let refConfigs = {};
                    for (let i in relations) {
                        let fromFile = relations[i].from.file;
                        let fromSheet = relations[i].from.sheet;
                        if (!refConfigs[fromFile]) {
                            refConfigs[fromFile] = {};
                        }
                        if (!refConfigs[fromFile][fromSheet]) {
                            refConfigs[fromFile][fromSheet] = [];
                        }
                       refConfigs[fromFile][fromSheet].push(relations[i]);
                    }
                    
                    for (let i in fileConfigs) {
                        let fileConfig = fileConfigs[i];
                        if (!fileConfig.file.sheets) {
                            fileConfig.file.sheets = [];
                        }
                        let fileName = getMetaFileName(fileConfig.file.file_metadata);
                        // setup mappings
                        templates[fileName] = {};
                        for (let i in fileConfig.file.sheets) {
                            let sheetName = fileConfig.file.sheets[i].sheet_name;
                            // If load SC2 separatedly and have excluding sheets, then skip the mapping for those sheets
                            if (curFileName && !wbObj[fileName][sheetName]) {
                                continue;
                            }
                            templates[fileName][sheetName] = Object.assign({}, fileConfig.file.sheets[i]);
//                                    if (!templates[fileName][sheetName].header_row) {
//                                        templates[fileName][sheetName].header_row = 1;
//                                    }
//                                    if (!templates[fileName][sheetName].data_start_row) {
//                                        templates[fileName][sheetName].data_start_row = templates[fileName][sheetName].header_row + 1;
//                                    }
                            let sc2Mappings = fileConfig.file.sheets[i].mappings;
                            templates[fileName][sheetName].mappings = [];
                            templates[fileName][sheetName].references = {};
                            if (!virColCnt[fileName]) {
                                virColCnt[fileName] = {};
                            }
                            if (!virColCnt[fileName][sheetName]) {
                                virColCnt[fileName][sheetName] = 0;
                            }
                            if (lastHeaderRow[fileName]) {
                                lastHeaderRow[fileName] = {};
                            }
                            if (templates[fileName][sheetName].header_row) {
                                lastHeaderRow[fileName][sheetName] = templates[fileName][sheetName].header_row;
                            } else {
                                lastHeaderRow[fileName][sheetName] = 1;
                            }
                            let mappings = templates[fileName][sheetName].mappings;
                            sc2Mappings.sort(function (m1, m2) {
                                let idx1 = m1.column_index;
                                if (!idx1) {
                                    idx1 = m1.column_index_vr;
                                }
                                if (!idx1) {
                                    idx1 = -1;
                                }
                                let idx2 = m1.column_index;
                                if (!idx2) {
                                    idx2 = m1.column_index_vr;
                                }
                                if (!idx2) {
                                    idx2 = -1;
                                }
                                return idx1 - idx2;
                            });
                            // TODO need more test case for this logic
                            let vrColCnt = 0;
                            for (let j in sc2Mappings) {
                                j = Number(j);
                                if (sc2Mappings[j].column_index_vr) {
                                    vrColCnt++;
                                    sc2Mappings[j].column_index = sc2Mappings[j].column_index_vr;
                                    delete sc2Mappings[j].column_index_vr;
                                } else if (sc2Mappings[j].column_index) {
                                    sc2Mappings[j].column_index_org = sc2Mappings[j].column_index;
                                    sc2Mappings[j].column_index = sc2Mappings[j].column_index + vrColCnt;
                                } else {
                                    vrColCnt++;
                                    if (j === 0) {
                                        sc2Mappings[j].column_index = 1;
                                    } else {
                                        sc2Mappings[j].column_index = sc2Mappings[j - 1].column_index + 1;
                                    }
                                }

                                let colIdx = Number(sc2Mappings[j].column_index);
                                for (let k = mappings.length; k < colIdx - 1; k++) {
                                    if (!mappings[k]) {
                                        mappings.push({
                                            column_index : k + 1,
                                            column_index_org : k + 1,
                                            ignored_flg : true
                                        });
                                    }
                                }
                                mappings[colIdx - 1] = sc2Mappings[j];

//                                        mappings[sc2Mappings[j].column_index - 1] = sc2Mappings[j];
                                if (sc2Mappings[j].icasa && primaryVarExisted[sc2Mappings[j].icasa] !== undefined) {
                                    primaryVarExisted[sc2Mappings[j].icasa] = true;
                                }
                                if (sc2Mappings[j].formula_info) {
                                    for (let key in sc2Mappings[j].formula_info) {
                                        sc2Mappings[j][key] = sc2Mappings[j].formula_info[key];
                                    }
                                    delete sc2Mappings[j].formula_info;
                                }
                                if (sc2Mappings[j].value) {
                                    sc2Mappings[j].virtual_val_fixed = sc2Mappings[j].value;
                                    delete sc2Mappings[j].value;
                                }
                            }
                            if (vrColCnt > 0) {
                                virColCnt[fileName][sheetName] = vrColCnt;
                            }
                        }
                    }
                    
                    // setup references
                    for (let fileName in templates) {
                        for (let sheetName in templates[fileName]) {
                            let refConfig;
                            if (refConfigs[fileName]) {
                                if (!sheetName) {
                                    refConfig = refConfigs[fileName][""];
                                    if (!refConfig) {
                                        refConfig = refConfigs[fileName]["sheet1"];
                                    }
                                } else {
                                    refConfig = refConfigs[fileName][sheetName];
                                }
                            }
                            if (!refConfig) {
                                refConfig = [];
                            }
                            let references = templates[fileName][sheetName].references;
                            templates[fileName][sheetName].references_org = refConfig;
                            for (let j in refConfig) {
                                let refDef = refConfig[j];
                                let fromKeyIdxs = getKeyIdxArr(refDef.from.keys);
                                let toKeyIdxs = getKeyIdxArr(refDef.to.keys);
                                let toKey = getRefDefKey(refDef.to, toKeyIdxs);
                                if (!references[fromKeyIdxs]) {
                                    references[fromKeyIdxs] = {};
                                }
                                references[fromKeyIdxs][toKey] = {
                                    file: refDef.to.file,
                                    sheet: refDef.to.sheet,
                                    keys: toKeyIdxs //getKeyArr(toKeyIdxs, mappings)
                                };
                            }
                        }
                                
                    }
                } else {
                    alertBox("No AgMIP mapping information detected, please try another file!");
                    return;
                }
                processData();
            }
            
            function getMetaFileName(fileMeta) {
                if (fileMeta.file_name_local) {
                    return fileMeta.file_name_local;
                } else {
                    return fileMeta.file_name;
                }
            }
            
            function getMetaFileUrl(fileMeta) {
                if (fileMeta.file_url) {
                    return fileMeta.file_url;
//                } else if (fileMeta.file_name_local && fileMeta.file_name_local !== fileMeta.file_name) {
//                    return fileMeta.file_name;
                } else {
                    return "";
                }
            }
            
            function saveMetaFileName(fileMeta, fileName, fileUrl) {
//                fileMeta.file_name_local = fileName;
                fileMeta.file_name = fileName;
                if (fileUrl) {
                    fileMeta.file_url = fileUrl;
                }
            }
            
            function getSheetDataContent(rawData, sheetDef) {
                if (sheetDef.data_start_row) {
                    if (sheetDef.data_end_row) {
                        rawData = rawData.slice(sheetDef.data_start_row - 1, sheetDef.data_end_row);
                    } else {
                        rawData = rawData.slice(sheetDef.data_start_row - 1);
                    }
                }
                return rawData;
            }

            function isSingleRecordTable(data, sheetDef) {
                if (sheetDef.data_end_row) {
                    return sheetDef.data_end_row === sheetDef.data_start_row;
                } else {
                    return data.length === sheetDef.data_start_row;
                }
            }
            
            function saveTemplateFile() {
                if (!curFileName) {
                    alertBox("Please load spreadsheet file first, then edit and save SC2 file for it.");
                } else {
                    let text = toSC2Json();
                    let ext = "-sc2.json";
                    let blob = new Blob([text], {type: "text/plain;charset=utf-8"});
                    saveAs(blob, getFileName(curFileName) + ext);
                    isChanged = false;
                }
            }
            
            function toSC2Json(compressFlg) {
                if (compressFlg) {
                    return JSON.stringify(toSC2Obj());
                } else {
                    return JSON.stringify(toSC2Obj(), 2, 2);
                }
            }
            
            function toSC2Obj() {
                let sc2Obj = {
                    mapping_info : {
//                        mapping_author : "data factory (http://dssat2d-plot.herokuapp.com/demo/data_factory)",
//                        source_url: ""
                    },
                    dataset_metadata : {},
                    agmip_translation_mappings : {
                        primary_ex_sheet : {
                            file : null,
                            sheet : null,
                        },
                        relations : [],
                        files : []
                    },
                    xrefs : [
//                        {
//                          xref_provider : "gardian",
//                          xref_url : "https://gardian.bigdata.cgiar.org/dataset.php?id=5cd88b72317da7f1ae0cf390#!/"
//                        }
                    ]
                };
                let agmipTranslationMappingTemplate = JSON.stringify({
                    //Grab the primary keys from here if EXNAME is not defined
                    file : {
                        file_metadata : {
                            file_name : "",
//                            file_name_local : "",
                            "content-type" : ""
                            // file_url : ""
                        },
                        sheets : []
                    }
                });
                
                $(".mapping_gengeral_info").each(function () {
                   sc2Obj.mapping_info[$(this).attr("name") ] = $(this).val();
                });

                for (let fileName in templates) {
                    let tmp2 = JSON.parse(agmipTranslationMappingTemplate);
                    saveMetaFileName(tmp2.file.file_metadata, fileName, fileUrls[fileName]);
                    tmp2.file.file_metadata["content-type"] = fileTypes[fileName];
//                    if (fileName.toLowerCase().endsWith(".csv")) {
//                        tmp2.file.file_metadata["content-type"] = "text/csv";
//                    } else if (fileName.toLowerCase().endsWith(".xlsx")) {
//                        tmp2.file.file_metadata["content-type"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
//                    } else if (fileName.toLowerCase().endsWith(".xls")) {
//                        tmp2.file.file_metadata["content-type"] = "application/vnd.ms-excel";
//                    } else {
//                        // TODO add default content-type key word here
//                    }
                    
                    sc2Obj.agmip_translation_mappings.files.push(tmp2);
                    for (let sheetName in templates[fileName]) {
                        let tmp = Object.assign({}, templates[fileName][sheetName]);
                        tmp.mappings = [];
                        delete tmp.references;
                        for (let i in templates[fileName][sheetName].mappings) {
                            let mapping = templates[fileName][sheetName].mappings[i];
                            if (!mapping.ignored_flg) {
                                let mappingCopy = JSON.parse(JSON.stringify(mapping));
                                if (!mappingCopy.column_index_org) {
                                    mappingCopy.column_index_vr = mappingCopy.column_index;
                                    delete mappingCopy.column_index;
                                    mappingCopy.formula_info = {};
                                    for (let key in mappingCopy) {
                                        if (key.startsWith("virtual")) {
                                            if (key === "virtual_val_fixed") {
                                                mappingCopy.value = mappingCopy[key];
                                            } else if (key === "virtual_val_keys") {
                                                if (mappingCopy[key].length === 0) {
                                                    continue;
                                                }
                                            }
                                            mappingCopy.formula_info[key] = mappingCopy[key];
                                            delete mappingCopy[key];
                                        }
                                    }
                                } else {
                                    mappingCopy.column_index = mappingCopy.column_index_org;
                                    delete mappingCopy.column_index_org;
                                }
                                tmp.mappings.push(mappingCopy);
                                if (mapping.reference_flg) {
                                    delete mappingCopy.reference_type;
                                    delete mappingCopy.reference_flg;
                                }
                                if (mapping.format_customized) {
                                    mappingCopy.format = mapping.format_customized;
                                    delete mappingCopy.format_customized;
                                }
                            }
                        }
                        if (templates[fileName][sheetName].references) {
                            for (let fromKeyIdxs in templates[fileName][sheetName].references) {
                                let refDefs = templates[fileName][sheetName].references[fromKeyIdxs];
                                for (let toRefDefStr in refDefs) {
                                    let toRefDef = refDefs[toRefDefStr];
                                    let refDef = createRefDefObj({file: fileName, sheet: sheetName},
                                        JSON.parse("[" + fromKeyIdxs + "]"),
                                        toRefDef,
                                        getKeyIdxArr(toRefDef.keys), true);
                                    sc2Obj.agmip_translation_mappings.relations.push(refDef);
                                }
                            }
                        }
                        tmp2.file.sheets.push(tmp);
                    }
                }
                return sc2Obj;
            }

            function alertBox(msg, callback) {
                if (callback) {
                    bootbox.alert({
                        message: msg,
                        backdrop: true,
                        callback: callback
                    });
                } else {
                    bootbox.alert({
                        message: msg,
                        backdrop: true
                    });
                }
            }
            
            function confirmBox(msg, callback) {
                bootbox.confirm({
                    message: msg,
                    callback: function (result) {
                        if (result) {
                            callback();
                        }
                    }
                });
            }
            
            String.prototype.capitalize = function() {
                return this.charAt(0).toUpperCase() + this.slice(1).toLowerCase();
            }
        </script>
    </head>

    <body>

        <#include "../nav.ftl">

        <div class="container"></div>
        <div class="container-fluid">
            <div class="">
                <div class="btn-group">
                    <button type="button" class="btn btn-primary dropdown-toggle" data-toggle="dropdown">
                        Experiment Data <span class="caret"></span>
                    </button>
                    <ul class="dropdown-menu" role="menu">
                        <li onclick="openExpDataFile()" id="openFileMenu"><a href="#"><span class="glyphicon glyphicon-open"></span> Load file</a></li>
                        <li onclick="openExpDataFolderFile()"><a href="#"><span class="glyphicon glyphicon-open"></span> Load folder</a></li>
                        <li onclick="saveExpDataFile()"><a href="#"><span class="glyphicon glyphicon-save"></span> Save</a></li>
                        <li onclick="saveAgMIPZip()"><a href="#"><span class="glyphicon glyphicon-export"></span> To AgMIP Input Package</a></li>
                        <li onclick="saveAcebFile()"><a href="#"><span class="glyphicon glyphicon-export"></span> To Aceb</a></li>
                    </ul>
                </div>
                <div class="btn-group">
                    <button type="button" class="btn btn-primary dropdown-toggle" data-toggle="dropdown">
                        Template <span class="caret"></span>
                    </button>
                    <ul class="dropdown-menu" role="menu">
                        <li onclick="openTemplateFile()"><a href="#"><span class="glyphicon glyphicon-open"></span> Load Existing Template</a></li>
                        <li onclick="saveTemplateFile()"><a href="#"><span class="glyphicon glyphicon-save"></span> Save Template</a></li>
                    </ul>
                </div>

                <div class="btn-group">
                    <button type="button" class="btn btn-primary dropdown-toggle" data-toggle="dropdown">
                        Resources <span class="caret"></span>
                    </button>
                    <ul class="dropdown-menu" role="menu">
                        <li onclick="window.open('https://docs.google.com/document/d/1ezs4uFWI66R-gywdKB56io1YrKVKKTvs-ynFZkebm9k/')"><a href="#"><span class="glyphicon glyphicon-book"></span> User Guide</a></li>
                        <li onclick="window.open('https://docs.google.com/spreadsheets/u/0/d/1MYx1ukUsCAM1pcixbVQSu49NU-LfXg-Dtt-ncLBzGAM/pub?output=html')"><a href="#"><span class="glyphicon glyphicon-book"></span> ICASA Definition</a></li>
                    </ul>
                </div>

<!--                <button type="button" class="btn btn-primary" onclick="openFile()"><span class="glyphicon glyphicon-open"></span> Load</button>
                <button type="button" class="btn btn-primary" onclick="saveFile()"><span class="glyphicon glyphicon-save"></span> Save</button>-->
            </div>
            <br/>
            <ul class="nav nav-tabs">
                <li id="sheetTab" class="active dropdown">
                    <a class="dropdown-toggle" data-toggle="dropdown" href="#">Spreadsheet
                        <span id="sheet_name_selected"></span>
                        <span class="caret"></span>
                    </a>
                    <ul class="dropdown-menu" id="sheet_tab_list">
                    </ul>
                </li>
                <li id="genTab"><a data-toggle="tab" href="#general_tab">General Info</a></li>
                <li id="refTab"><a data-toggle="tab" href="#reference_tab">Table Relations</a></li>
                <li id="SC2Tab"><a data-toggle="tab" href="#sc2_tab">SC2 Preview</a></li>
                <li><a data-toggle="tab" href="#csv_tab"><em> CSV [debug]</em></a></li>
                <li id="mappingTab"><a data-toggle="tab" href="#mapping_tab"><em>Mappings Cache [debug]</em></a></li>
            </ul>
            <div class="tab-content">
                <div id="spreadshet_tab" class="tab-pane fade in active">
                    <div class="">
    <!--                        <span class="label label-info"><strong>&nbsp;Header Row&nbsp;</strong></span>
                            <span class="label label-info"><u>&nbsp;&nbsp;&nbsp;&nbsp;Unit Row&nbsp;&nbsp;&nbsp;&nbsp;</u></span>
                            <span class="label label-info"><em>Description Row</em></span>
                            <span class="label label-default">Ignored Row</span>-->
                        <label>View Style: </label>
                        <input type="checkbox" id="tableViewSwitch" class="table_switch_cb" data-toggle="toggle" data-size="mini" data-on="Full View" data-off="Data Only">
                        <label>Column Marker : </label>
                        <span class="label label-success">ICASA Mapped</span>
                        <span class="label label-info">Customized</span>
                        <span class="label label-primary">Virtual</span>
                        <span class="label label-warning">Undefined</span>
                        <span class="label label-danger"><em>Warning</em></span>
                        <span class="label label-default">Ignored</span>
                    </div>
                    <div id="sheet_spreadsheet_content" class="col-sm-12" style="overflow: hidden"></div>
                </div>
                <div id="csv_tab" class="tab-pane fade">
                    <textarea class="form-control" rows="30" id="sheet_csv_content" style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;" readonly></textarea>
                </div>
                <div id="general_tab" class="tab-pane fade">
                    <div class="subcontainer">
                        <fieldset class="col-sm-12">
                            <legend data-toggle="tooltip" title="Used for file name">Data Information</legend>
                            <div class="form-group col-sm-12">
                                <label class="control-label">Mapping Author Email:</label>
                                <div class="input-group col-sm-12">
                                    <input type="email" name="mapping_author" class="form-control mapping_gengeral_info" value="">
                                </div>
                            </div>
                            <div class="form-group col-sm-12">
                                <label class="control-label">Oringal Data URL:</label>
                                <div class="input-group col-sm-12">
                                    <input type="url" name="source_url" class="form-control mapping_gengeral_info" value="">
                                </div>
                            </div>
                            <fieldset class="col-sm-12">
                                <legend data-toggle="tooltip" title="Used for file name">File URL</legend>
                                <div id="file_url_inputs"></div>
                            </fieldset>
                        </fieldset>
                    </div>
                </div>
                <div id="reference_tab" class="tab-pane fade">
                    <div id="ref_table" class="subcontainer panel-group"></div>
                </div>
                <div id="mapping_tab" class="tab-pane fade">
                    <div class="col-sm-6" style="overflow: auto;height: 600px">
                        <div id="mapping_json_content_tree"></div>
                    </div>
                    <div class="col-sm-6">
                        <textarea class="form-control" rows="30" id="mapping_json_content_text" style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;" readonly></textarea>
                    </div>
                </div>
                <div id="sc2_tab" class="tab-pane fade">
                    <div class="col-sm-6" style="overflow: auto;height: 600px">
                        <div id="sc2_json_content_tree"></div>
                    </div>
                    <div class="col-sm-6">
                        <textarea class="form-control" rows="30" id="sc2_json_content_text" style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;" readonly></textarea>
                    </div>
                </div>
            </div>
        </div>
        <div id="template_file_url_input" hidden>
            <div class="col-sm-12">
                <label class="control-label"></label>
                <div class="input-group col-sm-12">
                    <input type="url" name="file_url" class="form-control" value="">
                </div>
            </div>
        </div>

        <#include "data_factory_popup_loadFile.ftl">
        <#include "data_factory_popup_row.ftl">
        <#include "data_factory_popup_column.ftl">
        <#include "data_factory_popup_codeMapping.ftl">
        <#include "data_factory_table_reference.ftl">
        <#include "../footer.ftl">
        <script type="text/javascript" src="/js/bootbox/dragable.js" charset="utf-8"></script>
        <script type="text/javascript" src='/plugins/FileSaver/FileSaver.min.js'></script>
        <script type="text/javascript" src='/plugins/jszip/jszip.min.js'></script>
        <script type="text/javascript" src="/js/sheetjs/shim.js" charset="utf-8"></script>
        <script type="text/javascript" src="/js/sheetjs/xlsx.full.min.js"></script>
        <script type="text/javascript" src="/plugins/filestyle/bootstrap-filestyle.min.js"></script>
        <script type="text/javascript" src="/plugins/chosen/chosen.jquery.min.js" ></script>
        <script type="text/javascript" src="/plugins/chosen/prism.js" charset="utf-8"></script>
        <script type="text/javascript" src="/plugins/jsonViewer/jquery.json-viewer.js" charset="utf-8"></script>
        <script type="text/javascript" src="/js/chosen/init.js" charset="utf-8"></script>
        <script type="text/javascript" src="/js/dataReader/BufferedFileReader.js"></script>
        <script type="text/javascript" src="/js/util/dateUtil.js"></script>
        <script type="text/javascript" src="/js/bootbox/bootbox.all.min.js" charset="utf-8"></script>
        <script type="text/javascript" src="/js/toggle/bootstrap-toggle.min.js" charset="utf-8"></script>
        <script src="https://cdn.jsdelivr.net/npm/handsontable@6.2.2/dist/handsontable.full.min.js"></script>
        <!--<script src="https://cdn.jsdelivr.net/npm/exceljs@1.13.0/dist/exceljs.min.js"></script>-->
        
        <script>
            $(document).ready(function () {
                initIcasaLookupSB();
                initIcasaCategorySB();
                chosen_init_all();
                $('input').on("blur", function(event) {
                    event.target.checkValidity();
                }).bind('invalid', function(event) {
                    alertBox(event.target.value + " is an invalid " + event.target.type, function () {
                        setTimeout(function() { $(event.target).focus();}, 50);
                    });
                });
                $(".mapping_gengeral_info").on("change", function () {
                    isChanged = true;
                    isViewUpdated = false;
                    isDebugViewUpdated = false;
                });
                $('.nav-tabs #sheetTab').on('shown.bs.tab', function(){
                    $('.table_switch_cb').bootstrapToggle('enable');
                    if (templates[curFileName][curSheetName].data_start_row) {
                        if (templates[curFileName][curSheetName].unfully_matched_flg) {
                            alertBox("Please double check the mappings for each column and make any correction as needed.");
                            delete templates[curFileName][curSheetName].unfully_matched_flg;
                        }
                        $('#tableViewSwitch').bootstrapToggle('off');
                    } else {
                        showSheetDefPrompt(processData);
                        $('#tableViewSwitch').bootstrapToggle('on');
                    }
                });
                $('.nav-tabs #genTab').on('shown.bs.tab', function(){
//                    chosen_init_all($("#general_tab"));
                });
                $('.nav-tabs #refTab').on('shown.bs.tab', function(){
                    initRefTable();
                });
                $('.nav-tabs #mappingTab').on('shown.bs.tab', function(){
                    $("#mapping_json_content_text").html(JSON.stringify(templates, 2, 2));
                    if (!isDebugViewUpdated) {
                        $("#mapping_json_content_tree").jsonViewer(templates, {collapsed: true, rootCollapsable: false});
                        isDebugViewUpdated = true;
                    }
                });
                $('.nav-tabs #SC2Tab').on('shown.bs.tab', function(){
                    $("#sc2_json_content_text").html(toSC2Json());
                    if (!isViewUpdated) {
                        $("#sc2_json_content_tree").jsonViewer(toSC2Obj(), {collapsed: true, rootCollapsable: false});
                        isViewUpdated = true;
                    }
                });
                $("button").prop("disabled", false);
                $('#tableViewSwitch').change(function () {
                    initSpreadsheet(curFileName, curSheetName);
                });
//                $('#tableColSwitchSuccess').change(function () {
//                    let plugin = spreadsheet.getPlugin('hiddenColumns');
//                    let hiddenArr = [];
//                    let isShown = $('#tableColSwitchSuccess').prop('checked');
//                    let sheetDef = templates[curFileName][curSheetName];
//                    let mappings = sheetDef.mappings;
//                    for (let i = 0; i < mappings.length; i++) {
//                        if (mappings[i].icasa) {
//                            if (isShown) {
//                                plugin.showColumn(i);
//                            } else {
//                                plugin.hideColumn(i);
//                            }
//                            
//                        }
//                    };
//                });
                $('#sheetTab').on("click", function() {
                    $('#sheet_tab_list').find("a").each(function () {
                        let tmp = $(this).attr('id').split("__");
                        let cntUndefined = countUndefinedColumns(templates[tmp[0]][tmp[1]]);
                        if (cntUndefined > 0) {
                            $(this).find("span").html(cntUndefined).removeClass("invisible");
                        } else {
                            $(this).find("span").html(cntUndefined).addClass("invisible");
                        }
                    });
                });
                $('.table_switch_cb').bootstrapToggle('disable');
                $(window).resize(function(){
                    if (spreadsheet) {
                        spreadsheet.updateSettings({
                            height: $(window).height() - $("body").height() + $("#sheet_spreadsheet_content").height()
                        });
                    }
                });
                $("#openFileMenu").click();
                $(window).on('beforeunload',function(){
                    if (isChanged) {
                        return "There are changes have not been saved yet";
                    }
                });
//                window.addEventListener('beforeunload', (event) => {
//                    if (isChanged) {
//                        event.preventDefault();
//                        event.returnValue = "There are changes have not been saved yet";
//                    } else {
//                        delete event['returnValue'];
//                    }
//                });
            });
        </script>
    </body>
</html>

