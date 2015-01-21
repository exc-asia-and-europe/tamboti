xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../modules/config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

<div xmlns="http://www.w3.org/1999/xhtml">
    <p> This is version {$config:app-version} of Tamboti, created 2014-01-24.</p>
    <p> Tamboti is an application for working with metadata based on the <a href="http://www.loc.gov/standards/mods/" target="_blank">MODS</a> standard.</p>
    <p> MODS is a standard used to catalogue books, articles and other traditional library
        material, and visual or online material such as images, videos, web sites or other sources.</p>
    <p> Tamboti is similar to the public interface (OPAC) of the library systems
        used by national and university libraries. Tamboti can process a large amount of records.</p>
    <p> In Tamboti, you can annotate records with metadata concerning language, script and
        transcription. This function is important for records used in multi-lingual contexts.</p>
    <p> In Tamboti, you can catalogue materials through a form-based interface. </p>
    <br/>
    <p> Tamboti is based on the <a href="http://exist-db.org/" target="_blank">eXist Native XML
            database</a>. As eXist itself, Tamboti is open source and free. Tamboti can be installed
         on a mobile device. The eXist database system can be
        installed with a standard application installer.</p>
    <br/>
    <p>Tamboti has a number of special features:</p>
    <ul class="list">
        <li> Users can log in using an Active Directory. </li>
        <li> Users have control over who can view and edit their records. </li>
        <li> Users can collaborate within groups to work on a collection of records. </li>
        <li> Users can upload PDFs and other binary records. The text and metadata of these records are
            extracted and searchable. </li>
        <li> Users and user groups are able to easily create a distinctive layout for their own
            collection, with its own internet address. </li>
    </ul>
    <p>Please follow the <a href="../../docs/">Tamboti Walkthrough</a> to get acquainted
        with functionalities of Tamboti.</p>
</div>
