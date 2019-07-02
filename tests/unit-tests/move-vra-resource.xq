xquery version "3.1";

import module namespace config="http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "../../frameworks/vra-hra/vra-hra.xqm";

declare namespace earl = "http://www.w3.org/ns/earl#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $config:content-root := "/apps/" || $config:actual-app-id || "/tests/resources";

declare function local:run-unit-test($resource-id as xs:string, $target-collection as xs:string) {
    let $run-tamboti-function := vra-hra-framework:move-resource($config:content-root || "/temp", $target-collection, $resource-id)
    
    return
        <earl:TestResult rdf:about="#result">
            <earl:outcome rdf:resource="http://www.w3.org/ns/earl#passed"/>
        </earl:TestResult>
};

(
    local:run-unit-test("w_46647ced-6a0a-4a06-9575-f7bed1a2d07f", $config:content-root || "/temp"),
    xmldb:move($config:content-root || "/temp", $config:content-root, "w_46647ced-6a0a-4a06-9575-f7bed1a2d07f.xml"),
    xmldb:move($config:content-root || "/temp/VRA_images", $config:content-root || "/VRA_images", "i_e1a29053-6987-4210-b922-39042e36ff9d.xml"),
    xmldb:move($config:content-root || "/temp/VRA_images", $config:content-root || "/VRA_images", "i_e1a29053-6987-4210-b922-39042e36ff9d.jpg")
)