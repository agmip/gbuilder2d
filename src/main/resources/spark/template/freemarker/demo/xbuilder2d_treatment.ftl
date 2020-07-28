<script>
    function addTrt(id, rawData) {
        let trtno;
        if (id) {
            trtno = id;
        } else {
            trtno = trtData.length + 1;
        }
        let trtRow = $("<tr></tr>");
        $("#trt_table_body").append(trtRow);
        
        let trtIdxCell = $('<td></td>');
        trtRow.append(trtIdxCell);
        let trtRemoveBtn = $('<span type="button" class="btn glyphicon glyphicon-remove" onclick="removeTrt(this);"></span>');
        trtIdxCell.append($('<a href="#"></a>').append(trtRemoveBtn)).append($("<label></label>").append(trtno));
        trtRemoveBtn.attr("id", "trt_remove_btn_" + trtno);
        
        let trtNameCell = $("<td></td>");
        trtRow.append(trtNameCell);
        let trtNameInput = $('<input type="text" name="trt_name" class="form-control" placeholder="Treatment name" data-toggle="tooltip" title="Treatment name" required>');
        trtNameCell.append($("<div class='input-group col-sm-11'></div>").append(trtNameInput));
        trtNameInput.attr("id", "trt_name_" + trtno);
        if (rawData) {
            trtNameInput.val(rawData.trt_name);
        }
        trtNameInput.on('change', function() {
            let trtid = Number(this.id.replace("trt_name_", "")) - 1;
            saveData(trtData[trtid], this.name, this.value);
        });
        
        let trtFieldCell = $("<td></td>");
        trtRow.append(trtFieldCell);
        let trtFieldSB = $('<select name="field" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Choose a field..." required></select>');
        trtFieldCell.append($('<div class="input-group col-sm-11"></div>').append(trtFieldSB));
        trtFieldSB.append('<option value=""></option>');
        trtFieldSB.append('<option value="">Create new...</option>');
        for (let fid in fields) {
            trtFieldSB.append($('<option value="' + fid + '"></option>').append(fields[fid].fl_name));
        }
        trtFieldSB.attr("id", "tr_field_" + trtno);
        if (rawData) {
            trtFieldSB.val(rawData.field);
        }
        
        let trtCulCell = $("<td></td>");
        trtRow.append(trtCulCell);
        let trtCulSB = $('<select name="cul" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Choose a cultivar..." required></select>');
        trtCulCell.append($('<div class="input-group col-sm-11"></div>').append(trtCulSB));
        trtCulSB.append('<option value=""></option>');
        trtCulSB.append('<option value="">Create new...</option>');
        for (let culId in cultivars) {
            trtCulSB.append($('<option value="' + culId + '"></option>').append(cultivars[culId].cul_name));
        }
        trtCulSB.attr("id", "tr_cul_" + trtno);
        if (rawData) {
            trtCulSB.val(rawData.cul_id);
        }
        
        let trtMgnCell = $("<td></td>");
        trtRow.append(trtMgnCell);
        let trtMgnSB = $('<select name="management" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Apply management setups..." multiple required></select>');
        trtMgnCell.append($('<div class="input-group col-sm-11"></div>').append(trtMgnSB));
        trtMgnSB.append('<option value=""></option>');
        trtMgnSB.append('<option value="">Create new...</option>');
        for (let mid in managements) {
            trtMgnSB.append($('<option value="' + mid + '"></option>').append(managements[mid].mgn_name));
        }
        trtMgnSB.attr("id", "tr_mgn_" + trtno);
        if (rawData && rawData.management) {
            rawData.management.forEach(item => {
                trtMgnSB.children('option[value=' + item + ']').attr('selected', true);
            });
        }
        
        let trtCfgCell = $("<td></td>");
        trtRow.append(trtCfgCell);
        let trtCfgSB = $('<select name="config" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Choose a Configuration..." required></select>');
        trtCfgCell.append($('<div class="input-group col-sm-11"></div>').append(trtCfgSB));
        trtCfgSB.append('<option value=""></option>');
        trtCfgSB.append('<option value="">Create new...</option>');
        trtCfgSB.attr("id", "tr_config_" + trtno);
        if (rawData) {
            trtCfgSB.val(rawData.config);
        }
        
        chosen_init("tr_field_" + trtno);
        chosen_init("tr_cul_" + trtno);
        chosen_init("tr_mgn_" + trtno);
        chosen_init("tr_config_" + trtno);
        if (id) {
            trtData.push(rawData);
        } else {
            trtData.push({trtno:trtno});
        }
        $('#treatment_badge').html(trtData.length);
    }
    
    function removeTrt(target) {
        let id = target.id;
        if (!id) {
            id = "trt_remove_btn_" + target;
        }
        $("#" + id).parent().parent().parent().remove();
        let rmvId = Number(id.replace("trt_remove_btn_", "")) - 1;
        trtData.splice(rmvId, 1);
        for (let trtid = rmvId; trtid < trtData.length; trtid++) {
            let newId = trtid + 1;
            $("#trt_remove_btn_" + trtData[trtid].trtno).parent().parent().children("label").html(newId);
            $("#trt_remove_btn_" + trtData[trtid].trtno).attr("id", "trt_remove_btn_" + newId);
            $("#trt_name_" + trtData[trtid].trtno).attr("id", "tr_field_" + newId);
            $("#tr_field_" + trtData[trtid].trtno).attr("id", "tr_field_" + newId);
            $("#tr_mgn_" + trtData[trtid].trtno).attr("id", "tr_field_" + newId);
            $("#tr_config_" + trtData[trtid].trtno).attr("id", "tr_field_" + newId);
            trtData[trtid].trtno = newId;
        }
        $('#treatment_badge').html(trtData.length);
    }
    
    function trtOptSelect(target) {
        if (target.selectedIndex === 1) {
            target.options[1].selected = false;
            if (target.name !== "cul") {
                $("#" + target.id.replace("tr_", "").replace(/_\d+/, "") + "_create").click();
            } else {
                showCultivarCreateDialog(target.id);
            }
        } else {
            let trtid = Number(target.id.replace(/tr_\w+_/, "")) - 1;
            if (target.name === "management") {
                let values = [];
                for (let i = 0; i < target.selectedOptions.length; i++) {
                    values.push(target.selectedOptions[i].value);
                }; 
                saveData(trtData[trtid], target.name, values);
            } else if (target.name === "cul") {
                saveData(trtData[trtid], "cul_id", target.value);
                saveData(trtData[trtid], "cul_name", target.selectedOptions[0].text);
            } else {
                saveData(trtData[trtid], target.name, target.value);
            }
            
        }
    }
    
    function showCultivarCreateDialog(sbid, msg) {
        let crid = $("#crid").val();
        if (!crid || crid === "") {
            bootbox.alert({backdrop: true, message: "Please select crop type under General section first."});
            return;
        }
        let dialogConfig = {
            title: "<h2>Please input your cultivar information:</h2>",
            size: 'large',
            message: $(".cultivar-input").html(),
            buttons: {
                cancel: {
                    label: "Cancel",
                    className: 'btn-default',
                    callback: function () {
                        let trtno = Number(sbid.replace("tr_cul_", ""));
                        $("#" + sbid).val(trtData[trtno].cul_id);
                        chosen_init(sbid);  
                    }
                },
                ok: {
                    label: "&nbsp;Save&nbsp;",
                    className: 'btn-primary',
                    callback: function(){
                        let culId = $(this).find("[name='cul_id']").val();
                        let culName = $(this).find("[name='cul_name']").val();
                        if (!culId || culId === "" || culId.length > 6) {
                            msg = "Please input cultivar ID with up to 6 digit code.";
                        } else if (cultivars[culId]) {
                            msg = culId + " has been used. Please provide a different cultivar ID.";
                        } else {
                            msg = "";
                        }
                        if (!culName || culName === "") {
                            msg = msg + "<br>Please input cultivar name for reference.";
                        }
                        if (msg === "") {
                            let customizedData= {
                                cul_id : culId,
                                cul_name : culName,
                                crid : crid
                            }
                            for (let i in trtData) {
                                let sb = $('#tr_cul_' + trtData[i].trtno);
                                sb.append($('<option value="' + culId + '"></option>').append(culName));
                                $("#" + sbid).val(culId).trigger("change");
                                chosen_init("tr_cul_" + trtData[i].trtno);
                            }
                            cultivars[culId] = customizedData;
                        } else {
                            showCultivarCreateDialog(sbid, msg);
                        }
                    }
                }
            }
        };
        if (msg) {
            dialogConfig.message = '<p><span><mark class="bg-warning">' + msg + '</mark></span></p><br>' + dialogConfig.message;
        }
        bootbox.dialog(dialogConfig);
    }
</script>
<div class="subcontainer">
    <fieldset>
        <legend>
            Treatment Information&nbsp;&nbsp;&nbsp;
            <a href="#"><span id="trt_add_btn" type="button" class="btn glyphicon glyphicon-plus" onclick="addTrt();"></span></a>
        </legend>
        <table class="table table-hover table-striped table-condensed">
            <thead>
                <tr class="info">
                    <th class="col-sm-1 text-center">Index</th>
                    <th class="col-sm-2">Name</th>
                    <th class="col-sm-2">Field</th>
                    <th class="col-sm-2">Cultivar</th>
                    <th class="col-sm-3">Management</th>
                    <th class="col-sm-2">Configuration</th>
                </tr>
            </thead>
            <tbody id='trt_table_body'>
<!--                <tr>
                    <td><a href="#"><span id="trt_remove_btn_1" type="button" class="btn glyphicon glyphicon-remove" onclick="removeTrt(this);"></span></a><label>1</label></td>
                    <td>
                        <div class="input-group col-sm-11">
                            <input type="text" id="trt_name_1" name="trt_name" class="form-control" placeholder="Treatment name" data-toggle="tooltip" title="Treatment name" required>
                        </div>
                    </td>
                    <td>
                        <div class="input-group col-sm-11">
                            <select id="tr_field_1" name="field" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Choose a field..." required>
                                <option value=""></option>
                                <option value="">Create new...</option>
                            </select>
                        </div>
                    </td>
                    <td>
                        <div class="input-group col-sm-11">
                            <select id="tr_mgn_1" name="management" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Apply management setups..." multiple required>
                                <option value=""></option>
                                <option value="">Create new...</option>
                                <option value="PT">Default</option>
                                <option value="TM">N-150</option>
                                <option value="TM">N-200</option>
                                <option value="TM">N-250</option>
                                <option value="TM">I-subsurface</option>
                                <option value="TM">I-surface</option>
                                <option value="TM">I-fixed</option>
                            </select>
                        </div>
                    </td>
                    <td>
                        <div class="input-group col-sm-11">
                            <select id="tr_config_1" name="config" class="form-control chosen-select-deselect" onchange="trtOptSelect(this);" data-placeholder="Choose a Configuration..." required>
                                <option value=""></option>
                                <option value="">Create new...</option>
                            </select>
                        </div>
                    </td>
                </tr>-->
            </tbody>
        </table>
    </fieldset>
</div>
<div class="cultivar-input" hidden>
    <p></p>
    <div class="col-sm-12">
        <!-- 1st row -->
        <div class="form-group col-sm-12">
            <label class="control-label">Cultivar ID</label>
            <div class="input-group col-sm-12">
                <input type="text" name="cul_id" class="form-control cultivar-input-item" value="" >
            </div>
        </div>
        <!-- 2nd row -->
        <div class="form-group col-sm-12">
            <label class="control-label">Cultivar Name</label>
            <div class="input-group col-sm-12">
                <input type="text" name="cul_name" class="form-control cultivar-input-item" value="New Cultivar" >
            </div>
        </div>
    </div>
</div>
