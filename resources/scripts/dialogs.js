$(function() {
    
    //called each time the collection/folder sharing dialog is opened, and when a sharing operation occurs
    function updateSharingDialog() {
        // reload dataTable
        $("#collectionSharingDetails").dataTable().fnReloadAjax("sharing.xql?collection=" + getCurrentCollection());

        // go to the last page
        //$('#collectionSharingDetails').dataTable().fnPageChange("last");
    }
    
    function shareCollection(options) {
        if (tamboti.checkDuplicateSharingEntry(options.name, options.target)) {
            return;
        }
    
        var fancyTree = $('#collection-tree-tree').fancytree("getTree");
        var collection = fancyTree.getActiveNode().key;
    
        $.ajax({
            type: 'POST',
            url: "operations.xql",
            data: { 
                action: "share",
                collection: collection,
                name: options.name,
                target: options.target,
                type: options.type
                },
            success: function(data, status, xhr) {
                updateSharingDialog();
            },
            error: function(response, message) {
                showMessage('Sharing failed: ' + response.responseText);
            }
        });
    }            

    $('#login-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Login": function () {
                login($(this));
            }
        },
        title: "Login", width: 450
    });
    var trigger = '#login-link';
    if (trigger != '') {
        $(trigger).click(function() {
            $('#login-dialog').dialog('open');
            return false;
        });
    }
    
    $('#new-collection-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Create": function () {
                createCollection($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        },
        title: "Create Folder",
        width: 450
    });
    $("#new-collection-dialog").on("keydown", function (event) {
        if (event.keyCode == 13) {
            $(this).parent()
                   .find("button:eq(1)").trigger("click");
            return false;
        }
    });            
    
    var trigger = '#collection-create-folder';
    if (trigger != '') {
        $(trigger).click(function() {
            $('#new-collection-dialog').dialog('open');
            return false;
        });                
    }
    
    $('#upload-file-dialog').dialog({
        modal: true,
        autoOpen: false,
        open: function(event, ui){
            updateAttachmentDialog();
        },
        buttons: {},
        title: "File attachments",
        width: 900
    });
    var trigger = '#upload-file-to-resource';
    if (trigger != '') {
        $(trigger).click(function() {
            $('#upload-file-dialog').dialog('open');
            return false;
        });                 
    }
   
    $('#rename-collection-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Rename": function () {
                renameCollection($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        },
        title: "Rename Folder",
        width: 450
    });
    var trigger = '#collection-rename-folder';
    if (trigger != '') {
        $(trigger).click(function() {
            $('#rename-collection-dialog').dialog('open');
            return false;
        });                
    }
    
    $('#move-collection-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Move": function () {
                moveCollection($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        },
        title: "Move Folder",
        width: 700
    });
    var trigger = '#collection-move-folder';
    if (trigger != '') {
        $(trigger).click(function() {
            $('#move-collection-dialog').dialog('open');
            return false;
        });                 
    }
   
    $('#remove-collection-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Remove": function () {
                removeCollection($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        }, 
        title: "Remove Folder", 
        width: 450
    });
    var trigger = '#collection-remove-folder';
    if (trigger != '') {
        $(trigger).click(function() {
            $('#remove-collection-dialog').dialog('open');
            return false;
        });                  
    }
    
    $('#sharing-collection-dialog').dialog({
        modal: true,
        autoOpen: false,
        open: function(event, ui){
            updateSharingDialog();
        },
        buttons: {
            "Close": function() {
                $(this).dialog("close");
            }
        }
        ,
        title: "Folder Sharing",
        width: 700
    });
    
    // add the  progress indicator with custon events (showLoading and showDone)
    var copyACLStatusSelector = $('form#copy-acl-to .messageContainer');
    addStatusDisplay(copyACLStatusSelector);
    $('form#copy-acl-to').bind("submit", function(event, data) {
        if(confirm("Warning: existing sharing-table on target collection will get overwritten! Proceed?")){
            var node = $("#collection-tree-tree").fancytree("getActiveNode");
            copyACLStatusSelector.trigger('showLoading');
            copyCollectionACL(node.key, $('#copy-acl-target-collection-list option:selected').val());
            copyACLStatusSelector.trigger('showDone');
        }
        event.preventDefault();
    });
    
    $("#collection-sharing").click(function() {
        var node = $("#collection-tree-tree").fancytree("getActiveNode");
        if (node !== null) {
            var selectedCollection = node.key;
            //clear the list
            $("#copy-acl-target-collection-list").find("option").remove();
            $.ajax({
                url: "operations.xql",
                data: {
                    action: 'get-move-folder-list', 
                    collection: selectedCollection
                },
                type: 'POST',
                success: function(data, message) {
                    $('option', data).each(function() {
                        $('#copy-acl-target-collection-list').append('<option value="' + $.trim($(this).attr('value')) + '">' + $.trim($(this).text()) + '</option>');
                    });
                },
                error: function(response, message) {
                    console.debug("Loading the sharing folder list failed");
                }
            });
            $('#sharing-collection-dialog').dialog('open');
        }
        else{
            console.debug("no node selected");
        }
    });
    
    $("#sharing-collection-dialog-tabs").tabs({
        beforeActivate: function(ev, ui) {
            if (ui.newTab.index() == 1) {
                var shareRolesSelectElement = $(this).find("select.shareRoles");
                $("option", shareRolesSelectElement).removeAttr('selected');
                $("option:first", shareRolesSelectElement).attr('selected','selected');
                shareRolesSelectElement.empty();
                $.each(tamboti.shareRoles.options, function(idx, data){
                    shareRolesSelectElement.append('<option value="' + data.value + '">' + data.title + '</option>');
                });
                
                // $(this).find("input[name='inherit']").attr("checked", false);
                // $(this).find("input[name='write']").attr("checked", false);
                // $(this).find("input[name='execute']").attr("checked", false);                        
            }
            if (ui.newTab.index() == 2) {
                var shareRolesSelectElement = $(this).find("select.shareRoles");
                $("option", shareRolesSelectElement).removeAttr('selected');
                $("option:first", shareRolesSelectElement).attr('selected','selected');
                shareRolesSelectElement.empty();
                $.each(tamboti.shareRoles.options, function(idx, data){
                    shareRolesSelectElement.append('<option value="' + data.value + '">' + data.title + '</option>');
                });

                // $(this).find("input[name='inherit']").attr("checked", false);
                // $(this).find("input[name='write']").attr("checked", false);
                // $(this).find("input[name='execute']").attr("checked", false);                        
            }    
        }                
    });            
    
    // add new user to share event
    $('#add-new-user-to-share-button').click(function() {
        var input_value = $("#user-auto-list").val();
        if (input_value == tamboti.currentUsername) {
            showMessage("You cannot share to yourself!")
            return;
        }
        var username_no_parenthesis = input_value.match( /\(.*\)/ );
        var username = "";
        
        if (username_no_parenthesis !== null) {
            username = username_no_parenthesis[0].substring(1, username_no_parenthesis[0].length-1);
        } else {
            username = input_value;
        }

        var options = 
            {
                name: username,
                target: "USER",
                type: $("select.shareRoles option:selected", $("#add-user-tab")).val()
            }
        shareCollection(options);
        
        //clear the textbox for user name
        $('#user-auto-list').val("");
    });
    
    // $('#add-user-to-share-button').click(function() {
    //     var dialog = $("#add-user-ace");
    //     console.debug(dialog);
    //     addUserToShare();
    // });            
    
    // add new project to share event
    $('#add-new-group-to-share-button').click(function() {
        var groupname = $("#group-auto-list").val();
        var options = 
            {
                name: groupname,
                target: "GROUP",
                type: $("select.shareRoles option:selected", $("#add-group-tab")).val()
            }
        shareCollection(options);
        
        //clear the textbox for project name
        $('#group-auto-list').val("");
    });
    
    // $('#add-project-to-share-button').click(function() {
    //     addProjectToShare();
    // });            

    $('#user-auto-list').autocomplete({
        source: function(request, response) {
            var data = {
                term: request.term
            };
            $.ajax({
                url: "autocomplete-username.xql",
                dataType: "json",
                data: data,
                success: function(data) {
                    response(data);
                }
            });
        },
        minLength: 2,
        delay: 700
    }); 

    $('#group-auto-list').autocomplete({
        source: function(request, response) {
            var data = {
                term: request.term
            };
            $.ajax({
                url: "autocomplete-groupname.xql",
                dataType: "json",
                data: data,
                success: function(data) {
                    response(data);
                }
            });
        },
        minLength: 2,
        delay: 700
    });

    $('#remove-resource-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Remove": function () {
                removeResource($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        }, 
        title: "Remove Record", 
        width: 450
    });
    $('#move-resource-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Move": function () {
                moveResource($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        }, 
        title: "Move Record",
        width: 500
    });
    $('#new-resource-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Create": function () {
                tamboti.newResource();
                $(this).dialog("close");
            },
            "Cancel": function() { 
                $(this).dialog("close");
            }
        }, 
        title: "Create Stand-Alone MODS Record", 
        width: 550
    });
    $("#collection-create-resource").click(function() {
        $('#new-resource-dialog').dialog('open');
        return false;
    });                

    $('#add-related-dialog').dialog({
        modal: true,
        autoOpen: false,
        buttons: {
            "Create": function () {
                newRelatedResource($(this));
            },
            "Cancel": function() {
                $(this).dialog("close");
            }
        },
        title: "Create Related MODS Record",
        width: 550
    });
  
  
});  