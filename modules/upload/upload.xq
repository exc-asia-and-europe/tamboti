xquery version "3.1";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../utils/utils.xqm";
import module namespace functx = "http://www.functx.com";

declare namespace upload = "http://exist-db.org/eXide/upload";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mods="http://www.loc.gov/mods/v3";

declare variable $user := $config:dba-credentials[1];
declare variable $userpass := $config:dba-credentials[2];
declare variable $message := 'uploaded';
declare variable $image-collection-name := 'VRA_images';

declare function local:generate-image-record($uuid, $file-uuid, $title, $workrecord) {
    let $vra-content :=
        <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:ext="http://exist-db.org/vra/extension" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
            <image id="{$uuid}" source="Tamboti-upload" href="{$file-uuid}">
                <relationSet>
                    <relation type="imageOf" relids="{$workrecord}" source="Tamboti-upload">attachment</relation>
                </relationSet>
                <titleSet>
                    <title type="other">{concat('Image record ', xmldb:decode($title))}</title>
                </titleSet>
            </image>
        </vra>

    return $vra-content    
};

declare function upload:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return
            (xmldb:create-collection($collection, $components[1]),
            upload:mkcol-recursive($newColl, subsequence($components, 2)))
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function upload:mkcol($collection, $path) {
    upload:mkcol-recursive($collection, tokenize($path, "/"))[last()]
};

declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string) {
    local:apply-perms($collection-path, $username, $mode),
        for $child in xmldb:get-child-resources($collection-path)
        let $resource-path := fn:concat($collection-path, "/", $child)
        return
            local:apply-perms($resource-path, $username, $mode),
        for $child in xmldb:get-child-collections($collection-path)
        let $child-collection-path := fn:concat($collection-path, "/", $child)
        return
            local:recurse-items($child-collection-path, $username, $mode)
};

declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string) {
    sm:add-user-ace(xs:anyURI($path), $username, true(), $mode)
};

declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string) {
    local:apply-perms($collection-path, $username, $mode),
    for $child in xmldb:get-child-resources($collection-path)
    let $resource-path := fn:concat($collection-path, "/", $child)
    return
        local:apply-perms($resource-path, $username, $mode),
            for $child in xmldb:get-child-collections($collection-path)
            let $child-collection-path := fn:concat($collection-path, "/", $child)
            return
                local:recurse-items($child-collection-path, $username, $mode)
};

declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string) {
    sm:add-user-ace(xs:anyURI($path), $username,true(), $mode)
};

declare function local:get-vra-workrecord-template($workrecord-uuid as xs:string, $image-filename as xs:string) as element() {
    <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:ext="http://exist-db.org/vra/extension" xmlns:hra="http://cluster-schemas.uni-hd.de" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
        <work id="{$workrecord-uuid}" source="Tamboti-upload">
            <relationSet/>
            <titleSet>
                <title type="other">{concat('Work record ', $image-filename)}</title>
            </titleSet>
        </work>
    </vra>    
};

declare function upload:upload($filetype, $filesize, $filename, $data, $doc-type, $workrecord-uuid) {
    let $image-uuid := concat('i_', util:uuid())
    let $upload-collection-path :=
        if (exists(collection($config:mods-root)//vra:work[@id = $workrecord-uuid])) then 
            let $resource := collection($config:mods-root)//vra:work[@id = $workrecord-uuid]
            return
                util:collection-name($resource)
        else 
            if (exists(collection($config:mods-root)//mods:mods[@ID = $workrecord-uuid])) then
                util:collection-name(collection($config:mods-root)//mods:mods[@ID = $workrecord-uuid]/@ID)
            else 
                ()

    let $workrecord-file-path := concat($upload-collection-path, '/', $workrecord-uuid, '.xml')
    let $image-collection-path := concat($upload-collection-path, '/', $image-collection-name)
    let $image-filename := concat($image-uuid, '.', functx:substring-after-last($filename, '.'))
    let $image-file-path := xs:anyURI(concat($image-collection-path, '/', $image-filename))
    let $image-record := local:generate-image-record($image-uuid, $image-filename, $filename, $workrecord-uuid)

    let $image-record-filename := concat($image-uuid, '.xml')
    let $image-record-file-path := xs:anyURI($image-collection-path || '/' || $image-record-filename)
    let $collection-owner-username := xmldb:get-owner($upload-collection-path)
    let $upload :=  
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2] ,
            (
                
                security:copy-collection-ace-to-resource-apply-modechange($upload-collection-path, $workrecord-file-path)
                ,
                if (not(xmldb:collection-available($image-collection-path))) then
                    (
                        xmldb:create-collection($upload-collection-path, $image-collection-name),
                        sm:chown(xs:anyURI($image-collection-path), $collection-owner-username),
                        sm:chgrp(xs:anyURI($image-collection-path), $config:biblio-users-group),
                        security:duplicate-acl($upload-collection-path, $image-collection-path)
                    )
                else ()
                ,
                upload:add-tag-to-parent-doc($workrecord-file-path, upload:determine-type($workrecord-uuid), $image-uuid),
                    
                xmldb:store($image-collection-path, $image-record-filename, $image-record),
                sm:chown($image-record-file-path, $collection-owner-username),
                sm:chmod($image-record-file-path, $config:resource-mode),
                sm:chgrp($image-record-file-path, $config:biblio-users-group),
                security:copy-collection-ace-to-resource-apply-modechange($upload-collection-path, $image-record-file-path),
                    
                xmldb:store($image-collection-path, $image-filename, $data),
                sm:chown($image-file-path, $collection-owner-username),
                sm:chmod($image-file-path, $config:resource-mode),
                sm:chgrp($image-file-path, $config:biblio-users-group),
                security:copy-collection-ace-to-resource-apply-modechange($upload-collection-path, $image-file-path),                
                    
                concat($filename, ' ' ,$message)
            )
        )
    return $upload
};
 
declare function upload:add-tag-to-parent-doc($parentdoc_path as xs:string, $parent_type as xs:string, $myuuid as xs:string) {
    (
        let $parentdoc := doc($parentdoc_path)
        let $add :=
            if ($parent_type eq 'vra')
            then
                let $relationTag := $parentdoc/vra:vra/vra:work/vra:relationSet
                let $pref := 
                    if (exists($relationTag//vra:relation[@type="imageIs" and @pref="true"])) then
                        "false"
                    else
                        "true"
                let $vra_insert := <relation xmlns="http://www.vraweb.org/vracore4.htm" type="imageIs" relids="{$myuuid}" source="Tamboti-upload" pref="{$pref}">general view</relation>
                    return
                        let $vra-insert := $parentdoc
                        let $vra-update := update insert $vra_insert into $parentdoc/vra:vra/vra:work/vra:relationSet
                        return $vra-update
            else 
                if ($parent_type eq 'mods')
                then
                    let $mods-insert := 
                        <mods:relatedItem type="constituent">
                            <mods:typeOfResource>still image</mods:typeOfResource>
                            <mods:location>
                                <mods:url displayLabel="Illustration" access="preview">{$myuuid}</mods:url>
                            </mods:location>
                        </mods:relatedItem>
                    let $mods-insert-tag := $parentdoc
                    let $mods-update := update insert $mods-insert into $mods-insert-tag/mods:mods
                    return  $mods-update 
                else  ()
               
        return $add
    )
};

declare function upload:determine-type($workrecord) {
    let $vra_image := collection($config:mods-root)//vra:work[@id = $workrecord]/@id
    let $type :=
        if (exists($vra_image)) 
        then 'vra'
        else
            let $mods := collection($config:mods-root)//mods:mods[@ID = $workrecord]/@ID
            let $mods_type :=
                if (exists($mods)) 
                then 'mods'
                else ()
                    return $mods_type
                    
    return $type
};

let $image-types := ('png', 'jpg', 'gif', 'tiff', 'jpeg', 'tif')
let $uploadedFile := 'uploadedFile'
let $data := request:get-uploaded-file-data($uploadedFile)
let $filename := request:get-uploaded-file-name($uploadedFile)
let $filesize := request:get-uploaded-file-size($uploadedFile)
let $result := for $x in (1 to count($data))
    let $filetype := functx:substring-after-last($filename[$x], '.')
    let $doc-type := if (ends-with(lower-case($filetype), $image-types))
        then 'image'
        else ''
        return
            if ($doc-type eq 'image') then
                let $upload-resource-id :=
                    if (string-length(request:get-header('X-File-Parent')) > 0) then 
                        xmldb:decode(request:get-header('X-File-Parent'))
                    else 
                        ()

                let $upload := 
                    if (not(empty($upload-resource-id))) then
                        system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
                            upload:upload($filetype, $filesize[$x], $filename[$x], $data[$x], $doc-type, $upload-resource-id)
                        )
                    else
                        (:record for the collection:)
                        system:as-user($config:dba-credentials[1], $config:dba-credentials[2],(
                            let $collection-folder := xmldb:encode-uri(xmldb:decode(request:get-header('X-File-Folder')))
                            let $collection-owner-username := xmldb:get-owner($collection-folder)
                            let $work-xml-generate :=
                                    let $workrecord-uuid := concat('w_', util:uuid())
                                    let $vra-work-xml := local:get-vra-workrecord-template($workrecord-uuid, $filename[$x])
                                    let $create-workrecord :=
                                        (
                                            system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                                                (
                                                    xmldb:store($collection-folder, concat($workrecord-uuid, '.xml'), $vra-work-xml),
                                                    sm:chown(xs:anyURI(concat($collection-folder, '/', $workrecord-uuid, '.xml')), $collection-owner-username),
                                                    sm:chmod(xs:anyURI(concat($collection-folder, '/', $workrecord-uuid, '.xml')), $config:resource-mode),
                                                    sm:chgrp(xs:anyURI(concat($collection-folder, '/', $workrecord-uuid, '.xml')), $config:biblio-users-group),
                                                    upload:upload($filetype, $filesize[$x], $filename[$x], $data[$x], $doc-type, $workrecord-uuid)
                                                )
                                            )
                                        )
    
                                    return $message
                                return 
                                    concat($filename[$x], ' ', $message)
                        )
                    )
                    return $upload
        else 
            let $upload := 'unsupported file format'
                return $upload

return $result
