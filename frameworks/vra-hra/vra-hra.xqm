xquery version "3.0";

module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../../modules/utils/utils.xqm";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare function vra-hra-framework:get-vra-work-record-list($work-record as element()) as xs:string+ {
    (
            base-uri($work-record),
            vra-hra-framework:get-vra-image-records-list($work-record)
    )
};

declare function vra-hra-framework:get-vra-image-records-list($work-record as element()) as xs:string+ {
    let $image-record-ids := $work-record//vra:relationSet/vra:relation[@type eq "imageIs"]/@relids/string()
    let $image-record-ids := tokenize($image-record-ids, ' ')
    return
        for $image-record-id in $image-record-ids
        let $image-record := collection($config:mods-root-minus-temp)/vra:vra[vra:image/@id eq $image-record-id]
        let $image-record-url := base-uri($image-record)
        let $image-url := resolve-uri($image-record/*/@href, $image-record-url)        
        return
            (
                base-uri($image-record),
                $image-url
            )
};

declare function vra-hra-framework:move-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) as element(status) {
    let $resource-name :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
            (
                try {
                    let $resource-name := util:document-name(collection($source-collection)//vra:work[@id = $resource-id][1])
                    let $log := util:log("INFO", "resName:" || $resource-name)
                    (: create VRA_images collection, if needed :)
                    let $create-VRA-image-collection := tamboti-utils:create-vra-image-collection($target-collection)
                    let $relations := collection($source-collection)//vra:work[@id = $resource-id][1]/vra:relationSet//vra:relation[@type="imageIs"]
                    let $vra-images-target-collection := $target-collection || "/VRA_images"

                    (: move each image record :)
                    let $move-images := 
                        for $relation in $relations
                            let $image-uuid := data($relation/@relids)
                            let $image-vra := collection($source-collection)//vra:image[@id = $image-uuid]
                            let $image-resource-name := util:document-name($image-vra)
                            let $binary-name := data($image-vra/@href)
                            let $vra-images-source-collection := util:collection-name($image-vra)
                            return
                                (
                                    (: if binary available, move it as well :)
                                    if(util:binary-doc-available($vra-images-source-collection || "/" || $binary-name)) then
                                        security:move-resource-to-tamboti-collection($vra-images-source-collection, $binary-name, $vra-images-target-collection)
                                    else
                                        util:log("INFO", "not available: " || $vra-images-source-collection || "/" || $binary-name)
                                    ,
                                    (: move image record :)
                                    security:move-resource-to-tamboti-collection($vra-images-source-collection, $image-resource-name, $vra-images-target-collection)
                                )
                    let $move-work-record := security:move-resource-to-tamboti-collection($source-collection, $resource-name, $target-collection)
                    return
                        $resource-name
                } catch * {
                    util:log("INFO", "Error: move resource failed: " ||  $err:code || ": " || $err:description),
                    false()
                }
            )
        )

    return
        if($resource-name) then
            <status moved="{$resource-name}" from="{$source-collection}" to="{$target-collection}">{$target-collection}</status>
        else
            <status id="error">Error trying to move</status>
};
