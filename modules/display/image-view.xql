xquery version "3.0";

import module namespace image-service="http://hra.uni-heidelberg.de/ns/tamboti/image-service" at "image-service.xqm";
import module namespace functx="http://www.functx.com";
import module namespace content="http://exist-db.org/xquery/contentextraction" at "java:org.exist.contentextraction.xquery.ContentExtractionModule";
import module namespace im4xquery="http://expath.org/ns/im4xquery" at "java:org.expath.exist.im4xquery.Im4XQueryModule"; 
import module namespace config="http://exist-db.org/mods/config" at "../../../modules/config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";


let $imageUUID := request:get-parameter("uuid", "")
let $width := request:get-parameter("width", "")
let $mime-to-convert := ("image/tiff","image/jpg")

let $image-VRA := image-service:get-image-vra($imageUUID)
return 
    if (empty($image-VRA)) then
        $imageUUID || " not found"
    else
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
            (
             (: parent collection should be obsolete if we got a common place to store all images:)
            let $parentCollection := functx:substring-before-last(base-uri($image-VRA), '/')
            let $image-filename := data($image-VRA/@href)
            let $image-binary-uri := $parentCollection || "/" || $image-filename
    (:        let $image-binary-data := xs:base64Binary(util:binary-doc($image-binary-uri)):)
            let $image-metadata := contentextraction:get-metadata(util:binary-doc($image-binary-uri))
            let $image-binary-mime := xmldb:get-mime-type(xs:anyURI($image-binary-uri))
    (:        let $image-dimensions := map {  "height" := image:get-height($image-binary-data),:)
    (:                                        "width":=  image:get-width($image-binary-data) }:)
    
            let $image-dimensions := map {  "height" := data($image-metadata//xhtml:meta[@name="tiff:ImageLength"]/@content),
                                            "width" := data($image-metadata//xhtml:meta[@name="tiff:ImageWidth"]/@content) }
            
            let $image-binary-data := 
                if($image-binary-mime = $mime-to-convert) then
                    im4xquery:convert2jpg(util:binary-doc($image-binary-uri))
                else
                    xs:base64Binary(util:binary-doc($image-binary-uri))
    
            let $mime-type := 
                if($image-binary-mime = $mime-to-convert) then
                    "image/jpeg"
                else
                    $image-binary-mime
    
            return 
            (:let $setContent-disposition := response:set-header("content-disposition", concat("attachment; filename=", $image-filename)):)
                if(not($width = "")) then
                    let $bin := xs:base64Binary(im4xquery:scale($image-binary-data, (xs:integer($image-dimensions("height")), xs:integer($width)), $mime-type))
                    return 
                        response:stream-binary($bin, $mime-type, $image-filename)
                else
                    response:stream-binary($image-binary-data, $mime-type, $image-filename)
            )
        )